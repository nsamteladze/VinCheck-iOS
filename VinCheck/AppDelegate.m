
#import "AppDelegate.h"
#import <CocoaLumberjack/DDLog.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import "Constants.h"

extern NSString* const kC1BApplicationDidFinishLaunchingEventName;
extern NSString* const kC1BApplicationWillResignActiveEventName;
extern NSString* const kC1BApplicationDidEnterBackgroundEventName;
extern NSString* const kC1BApplicationWillEnterForegroundEventName;
extern NSString* const kC1BApplicationDidBecomeActiveEventName;
extern NSString* const kC1BApplicationWillTerminateEventName;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // Configure logging framework
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kC1BApplicationDidFinishLaunchingEventName object:nil];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kC1BApplicationWillResignActiveEventName object:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    [[NSNotificationCenter defaultCenter] postNotificationName:kC1BApplicationDidEnterBackgroundEventName object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    [[NSNotificationCenter defaultCenter] postNotificationName:kC1BApplicationWillEnterForegroundEventName object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kC1BApplicationDidBecomeActiveEventName object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kC1BApplicationWillTerminateEventName object:nil];
}

@end
