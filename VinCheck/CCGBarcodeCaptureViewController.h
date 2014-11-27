
#import <UIKit/UIKit.h>

@class CCGBarcodeCaptureViewController;

@protocol CCGBarcodeCaptureDelegate <NSObject>

@optional

- (void)didCaptureBarcodeWithData:(NSDictionary *) barcodeData;
- (void)didFailCaptureBarcodeWithError:(NSString *) error;
- (void)didCancelBarcodeCapture;

@end

@interface CCGBarcodeCaptureViewController : UIViewController <UIGestureRecognizerDelegate, UIPopoverControllerDelegate>

@property (weak, nonatomic) id <CCGBarcodeCaptureDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *captureScanView;

@end
