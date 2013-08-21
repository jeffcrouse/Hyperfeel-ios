//
//  ViewController.h
//  BrainProxy
//
//  Created by Jeffrey Crouse on 8/21/13.
//  Copyright (c) 2013 Jeffrey Crouse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "SRWebSocket.h"
#import "TGAccessoryDelegate.h"
#import "TGAccessoryManager.h"
#import "TheAmazingAudioEngine.h"
#import "AERecorder.h"

#define SOCKET_STATUS_CLOSED 1
#define SOCKET_STATUS_CONNECTING 2
#define SOCKET_STATUS_OPEN 3

#define SECTION_CONTROLS 0
#define SECTION_STATUS 1
#define SECTION_THINKGEAR 2
#define SECTION_MOTION 3

#define N_ATTENTION_LOOPS 10
#define N_MEDITATION_LOOPS 6

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface ViewController : UITableViewController <SRWebSocketDelegate,TGAccessoryDelegate> {
    
    // ThinkGear stuff
    int blinkStrength;
    int poorSignalValue;
    int attention;
    int meditation;
    int delta;
    int theta;
    int lowAlpha;
    int highAlpha;
    int lowBeta;
    int highBeta;
    int lowGamma;
    int highGamma;
    
    float attentionEased;
    float meditationEased;
    float attentionTeir;
    float meditationTeir;
    
    // Other stuff
    NSMutableArray* readings;
    NSTimeInterval interval;
    int webSocketStatus;
    SRWebSocket *webSocket;
    CMAttitude* attitude;
    CMRotationRate rotationRate;
    CMAcceleration userAcceleration;
    //NSArray* medLoops;
    //NSArray* attLoops;
    AEChannelGroupRef brainSoundGroup;
    AEAudioFilePlayer* attentionFiles[N_ATTENTION_LOOPS];
    AEAudioFilePlayer* meditationFiles[N_MEDITATION_LOOPS];
    
}

// SocketRocket
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

@property (retain, nonatomic) AEAudioController *audioController;
@property (retain, nonatomic) AERecorder *recorder;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (nonatomic, retain) UIButton *recordButton;
@property (nonatomic, retain) UIButton *submitButton;
@property (nonatomic, retain) UIButton *resetButton;
@property (nonatomic, retain) UISwitch *soundSwitch;

@property (nonatomic, retain) AEAudioFilePlayer *successSound;
@property (nonatomic, retain) AEAudioFilePlayer *errorSound;
@property (nonatomic, retain) AEAudioFilePlayer *blinkSound;
@property (nonatomic, retain) AEAudioFilePlayer *shakeSound;
@property (nonatomic, retain) AEAudioUnitFilter *reverb;
@end
