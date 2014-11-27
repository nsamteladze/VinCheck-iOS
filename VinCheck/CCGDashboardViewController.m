
#import "CCGDashboardViewController.h"
#import "CCGBarcodeCaptureViewController.h"

@interface CCGDashboardViewController () <CCGBarcodeCaptureDelegate>

- (IBAction)scanButtonClicked:(id)sender;

@property (strong, nonatomic) IBOutlet UILabel *vinLabel;

@end

@implementation CCGDashboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)scanButtonClicked:(id)sender
{
    CCGBarcodeCaptureViewController* viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"BarcodeCaptureViewController"];
    viewController.delegate = self;
    
    [self.navigationController presentViewController:viewController animated:YES completion:nil];
}

- (void)didCaptureBarcodeWithData:(NSDictionary *)barcodeData
{
    self.vinLabel.text = barcodeData[@"raw"];
}

- (void)didCancelBarcodeCapture
{
    
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
