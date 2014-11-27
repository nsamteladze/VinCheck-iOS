#import "CCGBarcodeCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import <CoreImage/CoreImage.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <CocoaLumberjack/DDLog.h>

#if DEBUG
static const int ddLogLevel = LOG_LEVEL_ALL;
#else
static const int ddLogLevel = LOG_LEVEL_ERROR;
#endif

@interface CCGBarcodeCaptureViewController () <AVCaptureMetadataOutputObjectsDelegate>

- (IBAction)cancelCaptureButtonClicked:(id)sender;
- (IBAction)takePhotoButtonClicked:(id)sender;

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) UIPanGestureRecognizer *recognizer;
@property (strong, nonatomic) NSDateFormatter *birthDateFormatter;
@property (strong, nonatomic) AVCaptureMetadataOutput *metaDataOutput;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *avCaptureVideoPreviewLayer;

@end

@implementation CCGBarcodeCaptureViewController

- (void)awakeFromNib
{
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    self.birthDateFormatter = [[NSDateFormatter alloc] init];
    [self.birthDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    //self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.session = [[AVCaptureSession alloc] init];
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionBack) backCamera = device;
            else frontCamera = device;
        }
    }
    
    if (backCamera) {
        if ([backCamera lockForConfiguration:nil]) {
            if ([backCamera isAutoFocusRangeRestrictionSupported]) {
                [backCamera setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionNear];
            }
            
            if ([backCamera isLowLightBoostSupported]) {
                [backCamera setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
            }
            
            [backCamera unlockForConfiguration];
        }
        
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera
                                                                            error:&error];
        
        if (input) {
            [self.session addInput:input];
        } else {
            DDLogError(@"Error: %@", error);
        }
        
        DDLogVerbose(@"Configuring capture output");
        
        // Add meta data output to session
        if (!self.metaDataOutput) self.metaDataOutput = [[AVCaptureMetadataOutput alloc] init];
        
        if (![self.session.outputs containsObject:self.metaDataOutput]) {
            
            [self.metaDataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
            [self.session addOutput:self.metaDataOutput];
            [self.metaDataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeCode39Code]];
        }
        
        // Add still image output to session
        self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
        [self.stillImageOutput setOutputSettings:outputSettings];
        [self.session addOutput:self.stillImageOutput];
        
        if (!self.session.running) [self.session startRunning];
        
        DDLogVerbose(@"Configuring capture video preview layer");
        
        CALayer* viewLayer = self.captureScanView.layer;
        viewLayer.masksToBounds = YES;
        
        self.avCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        [self.avCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [self.avCaptureVideoPreviewLayer setFrame:self.captureScanView.bounds];
        [viewLayer addSublayer:self.avCaptureVideoPreviewLayer];
        
        /* REMARK
         * Uncomment the code below to add target frame to 
         * the barcode capturing camera view.
         */
//        UIImageView* overlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BarcodeTarget"]];
//        [overlayImageView setFrame:CGRectMake(0, 284, 1024, 225)];
//        [self.view addSubview:overlayImageView];
        
        if (self.avCaptureVideoPreviewLayer.connection.supportsVideoOrientation) {
            self.avCaptureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }
    }
    
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}


/* REMARK
 * Should be called async not to block UI thread
 */
- (void)stopSession:(AVCaptureSession*) session
{
    // Sync call that can take a while
    if ([self.session isRunning]) [self.session stopRunning];
    
    for (AVCaptureInput* input in self.session.inputs) {
        [self.session removeInput:input];
    }
    
    for (AVCaptureOutput* output in self.session.outputs) {
        [self.session removeOutput:output];
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    // Get Code 39 barcode if it was among captured barcodes
    NSString* rawBarcodeData = nil;
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeCode39Code]) {
            rawBarcodeData = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            break;
        }
    }
    
    DDLogVerbose(@"Raw data => %@", rawBarcodeData);
    
    // Trigger error if not a PDF417 barcode
    if (!rawBarcodeData) {
        [self.delegate didFailCaptureBarcodeWithError:@"Scanned barcode is not Code 39"];
        return;
    }
    
    /* REMARK
     * AVCaptureSession stopRunning is a sync call => execute async not to block UI thread
     */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self stopSession:self.session];
    });
    
    // Parse PDF417 barcode
//    dispatch_async(dispatch_get_main_queue(), ^{
//
//        NSArray *stringComponents = [rawBarcodeData componentsSeparatedByString:@"\n"];
//        
//        NSArray *tokenIdentifiers = @[@"DAA", @"DAG", @"DAI", @"DAJ", @"DAK", @"DAQ", @"DBB", @"DBA", @"DBD"];
//        NSArray *tokenBucketNames = @[@"fullname", @"street", @"city", @"state", @"zipcode", @"dlnum", @"birthdate",@"dlExpire", @"licenseExpirationDate"];
//        NSMutableDictionary *scanData = [NSMutableDictionary new];
//        
//        for (NSString *component in stringComponents) {
//            for (NSString *tokenIdentifier in tokenIdentifiers) {
//                NSRange range = [component rangeOfString:tokenIdentifier];
//                if (range.location != NSNotFound) {
//                    NSInteger tokenIndex = [tokenIdentifiers indexOfObject:tokenIdentifier];
//                    NSString *bucketName = [tokenBucketNames objectAtIndex:tokenIndex];
//                    NSRange dataRange = NSMakeRange(range.location + 3, [component length] - (range.location + 3));
//                    scanData[bucketName] = [component substringWithRange:dataRange];
//                }
//            }
//        }
//        
//        NSString *fullname = scanData[@"fullname"];
//        if (fullname) {
//            NSArray *nameComponents = [fullname componentsSeparatedByString:@","];
//            if ([nameComponents count] == 3) {
//                scanData[@"lastname"] = [nameComponents objectAtIndex:0];
//                scanData[@"firstname"] = [nameComponents objectAtIndex:1];
//                scanData[@"middlename"] = [nameComponents objectAtIndex:2];
//            } else if ([nameComponents count] == 2) {
//                scanData[@"lastname"] = [nameComponents objectAtIndex:0];
//                scanData[@"firstname"] = [nameComponents objectAtIndex:1];
//            }
//        }
//        
//        DDLogVerbose(@"Driver License Info => %@", scanData);
    
//        AVCaptureConnection *videoConnection = nil;
//        for (AVCaptureConnection *connection in self.stillImageOutput.connections){
//            for (AVCaptureInputPort *port in [connection inputPorts]){
//                
//                DDLogDebug(@"%@", [port debugDescription]);
//                
//                if ([[port mediaType] isEqual:AVMediaTypeVideo]){
//                    
//                    videoConnection = connection;
//                    break;
//                }
//            }
//            if (videoConnection) {
//                break; 
//            }
//        }
    
    NSMutableDictionary* barcodeData = [NSMutableDictionary new];
    barcodeData[@"raw"] = rawBarcodeData;
    
    [self.delegate didCaptureBarcodeWithData:barcodeData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
//    });
}

#pragma mark - Actions

- (void)cancelCaptureButtonClicked:(id)sender
{
    [self.delegate didCancelBarcodeCapture];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)takePhotoButtonClicked:(id)sender
{
    if ([self.stillImageOutput.connections count] != 1) {
        DDLogError(@"Still image output has more than one connection");
        return;
    }
    AVCaptureConnection* connection = self.stillImageOutput.connections[0];
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error){
        
        CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
        
        if (!exifAttachments) {
            DDLogError(@"Failed to get attachment from image sample buffer");
            return;
        }
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        
        [[[UIAlertView alloc] initWithTitle:@"VIN Check"
                                    message:@"Saved to Photos"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil, nil]
         show];
    }];

}

//- (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
//{
//    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
//    CGFloat viewRatio = frameSize.width / frameSize.height;
//    
//    CGSize size = CGSizeZero;
//    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
//        if (viewRatio > apertureRatio) {
//            size.width = frameSize.width;
//            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
//        } else {
//            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
//            size.height = frameSize.height;
//        }
//    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
//        if (viewRatio > apertureRatio) {
//            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
//            size.height = frameSize.height;
//        } else {
//            size.width = frameSize.width;
//            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
//        }
//    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
//        size.width = frameSize.width;
//        size.height = frameSize.height;
//    }
//    
//    CGRect videoBox;
//    videoBox.size = size;
//    if (size.width < frameSize.width)
//        videoBox.origin.x = (frameSize.width - size.width) / 2;
//    else
//        videoBox.origin.x = (size.width - frameSize.width) / 2;
//    
//    if ( size.height < frameSize.height )
//        videoBox.origin.y = (frameSize.height - size.height) / 2;
//    else
//        videoBox.origin.y = (size.height - frameSize.height) / 2;
//    
//    return videoBox;
//}

@end
