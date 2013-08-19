//
//  ViewController.h
//  BrainProxy
//
//  Created by Jeffrey Crouse on 8/14/13.
//  Copyright (c) 2013 Jeffrey Crouse. All rights reserved.
//

#import "TGAccessoryManager.h"
#import "TGAccessoryDelegate.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "SRWebSocket.h"
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreMotion/CoreMotion.h>


#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

// the eSense values
typedef struct {
    int attention;
    int meditation;
} ESenseValues;

// the EEG power bands
typedef struct {
    int delta;
    int theta;
    int lowAlpha;
    int highAlpha;
    int lowBeta;
    int highBeta;
    int lowGamma;
    int highGamma;
} EEGValues;

@interface ViewController : UIViewController <TGAccessoryDelegate, SRWebSocketDelegate, UITableViewDataSource> {
    short rawValue;
    int rawCount;
    int buffRawCount;
    int blinkStrength;
    int poorSignalValue;
    int heartRate;
    float respiration;
    int heartRateAverage;
    int heartRateAcceleration;
    
    ESenseValues eSenseValues;
    EEGValues eegValues;
    
    SRWebSocket *_webSocket;
    NSMutableArray* readings;
    BOOL bRecording;
    NSTimeInterval interval;
    SystemSoundID successSound;
    SystemSoundID errorSound;
}

- (void) update:(NSTimer*)t;
- (void) wsConnect;

// TGAccessoryDelegate protocol methods
- (void)accessoryDidConnect:(EAAccessory *)accessory;
- (void)accessoryDidDisconnect;
- (void)dataReceived:(NSDictionary *)data;

// SocketRocket
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

- (IBAction)submitJourney:(id)sender;
- (IBAction)resetJourney:(id)sender;
- (IBAction)toggleRecord:(id)sender;
- (IBAction)identify:(id)sender;

@property (strong, nonatomic) CMMotionManager *motionManager;
@property (nonatomic, retain) IBOutlet UILabel *labelReadings;
@property (nonatomic, retain) IBOutlet UILabel *labelTime;
@property (nonatomic, retain) IBOutlet UILabel *labelWebsocketStatus;
@property (nonatomic, retain) IBOutlet UIButton *submitButton;
@property (nonatomic, retain) IBOutlet UIButton *resetButton;
@property (nonatomic, retain) IBOutlet UIButton *recordButton;
@property (nonatomic, retain) IBOutlet UISwitch *uiSwitch;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@end
