//
//  AppDelegate.m
//  BrainProxy
//
//  Created by Jeffrey Crouse on 8/21/13.
//  Copyright (c) 2013 Jeffrey Crouse. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    self.viewController = [[ViewController alloc] initWithStyle: UITableViewStyleGrouped];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = self.viewController;
    
    
    [[TGAccessoryManager sharedTGAccessoryManager] setupManagerWithInterval:0.05 forAccessoryType:0];
    [[TGAccessoryManager sharedTGAccessoryManager] setDelegate:self.viewController];
    [[TGAccessoryManager sharedTGAccessoryManager] setRawEnabled:false];
    NSLog(@"dispatchInterval=%f", [[TGAccessoryManager sharedTGAccessoryManager] dispatchInterval]);
    
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = @{@"endpoint": @"http://brainz.io/submit/journey",
                                  @"sample_rate": [NSNumber numberWithFloat:1]};
    [defaults registerDefaults:appDefaults];
    
     
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if([[TGAccessoryManager sharedTGAccessoryManager] connected])
        [[TGAccessoryManager sharedTGAccessoryManager] stopStream];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    if([[TGAccessoryManager sharedTGAccessoryManager] accessory] != nil) {
        [[TGAccessoryManager sharedTGAccessoryManager] startStream];
        NSLog(@"TGAccessory version: %d", [[TGAccessoryManager sharedTGAccessoryManager] getVersion]);
    } else
        NSLog(@"No accessory found!");
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"standardUserDefaults: %@", [NSUserDefaults standardUserDefaults]);
    
    NSLog(@"applicationDidBecomeActive");
    
    /*
    NSLog(@"client_id = %d", [[NSUserDefaults standardUserDefaults] integerForKey:@"client_id"]);
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    UIColor* color;
    switch([[NSUserDefaults standardUserDefaults] integerForKey:@"client_id"]) {
        case 0: color = UIColorFromRGB(0xFF6363); break;
        case 1: color = UIColorFromRGB(0xFFB62E); break;
        case 2: color = UIColorFromRGB(0xDEDE40); break;
        case 3: color = UIColorFromRGB(0x4FE63C); break;
        case 4: color = UIColorFromRGB(0x00B7C4); break;
        case 5: color = UIColorFromRGB(0x8366D4); break;
        case 6: color = UIColorFromRGB(0xE33BCF); break;
         case 7: color = UIColorFromRGB(0xE33BCF); break;
         case 8: color = UIColorFromRGB(0xE33BCF); break;
         case 9: color = UIColorFromRGB(0xE33BCF); break;
    }
    
    self.viewController.view.backgroundColor = color;
    self.viewController.tableView.separatorColor = color;
    self.viewController.tableView.backgroundView = nil;
    */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [[TGAccessoryManager sharedTGAccessoryManager] teardownManager];
}

@end
