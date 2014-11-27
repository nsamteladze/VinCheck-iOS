
#import "CCGLocalContext.h"
#import <DDLog.h>

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_ALL;
#else
static const int ddLogLevel = LOG_LEVEL_ERROR;
#endif

@interface CCGLocalContext()


@end

@implementation CCGLocalContext

+ (instancetype) sharedInstance
{
    static CCGLocalContext* _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[CCGLocalContext alloc] init];
        
        [_sharedInstance registerUserDefaults:@{ }];
    });
    return _sharedInstance;
}

- (void) registerUserDefaults:(NSDictionary *)defaults
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

@end
