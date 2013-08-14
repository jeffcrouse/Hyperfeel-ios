//
//  AppDelegate.m
//  BrainProxy
//
//  Created by Jeffrey Crouse on 8/14/13.
//  Copyright (c) 2013 Jeffrey Crouse. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    
    // Set the application defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:@"ws://brainz.io:8080"
     //                                                       forKey:@"host"];
    NSDictionary *appDefaults = @{@"host" : @"ws://brainz.io:8081", @"color" : [NSNumber numberWithInt:5236284]};
    [defaults registerDefaults:appDefaults];
    [defaults synchronize];
    
    
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    
    TGAccessoryType accessoryType = (TGAccessoryType)[defaults integerForKey:@"accessory_type_preference"];
    //
    // to use a connection to the ThinkGear Connector for
    // Simulated Data, uncomment the next line
    //accessoryType = TGAccessoryTypeSimulated;
    //
    // NOTE: this wont do anything to get the simulated data stream
    // started. See the ThinkGear Connector Guide.
    //
    BOOL rawEnabled = false; // [defaults boolForKey:@"raw_enabled"];
    
    if(rawEnabled) {
        NSLog(@"rawEnabled: true");
        // setup the TGAccessoryManager to dispatch dataReceived notifications every 0.05s (20 times per second)
        [[TGAccessoryManager sharedTGAccessoryManager] setupManagerWithInterval:0.05 forAccessoryType:accessoryType];
    } else {
        NSLog(@"rawEnabled: false");
        [[TGAccessoryManager sharedTGAccessoryManager] setupManagerWithInterval:0.1 forAccessoryType:accessoryType];
    }
    // set the root UIViewController as the delegate object.
    [[TGAccessoryManager sharedTGAccessoryManager] setDelegate:self.viewController];
    [[TGAccessoryManager sharedTGAccessoryManager] setRawEnabled:rawEnabled];
    
    if([[TGAccessoryManager sharedTGAccessoryManager] accessory] != nil)
        [[TGAccessoryManager sharedTGAccessoryManager] startStream];
    else
        NSLog(@"No accessory found!");
    
    NSLog(@"TGAccessory version: %d", [[TGAccessoryManager sharedTGAccessoryManager] getVersion]);
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground");
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground");
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    NSLog(@"applicationDidBecomeActive");
    NSLog(@"%d", [userDefaults integerForKey:@"color"]);
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    self.viewController.view.backgroundColor = UIColorFromRGB([userDefaults integerForKey:@"color"]);
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"applicationWillTerminate");
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[TGAccessoryManager sharedTGAccessoryManager] teardownManager];
}

@end
