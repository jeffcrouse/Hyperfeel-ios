//
//  ViewController.h
//  BrainProxy
//
//  Created by Jeffrey Crouse on 8/21/13.
//  Copyright (c) 2013 Jeffrey Crouse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
//#import "SRWebSocket.h"
#import "TGAccessoryDelegate.h"
#import "TGAccessoryManager.h"
#import "TheAmazingAudioEngine.h"
#import "ASIHTTPRequest.h"

#define SECTION_CONTROLS 0
#define SECTION_STATUS 1
#define SECTION_DEBUG 2
#define SECTION_THINKGEAR 3
#define SECTION_MOTION 4


#define ALERT_TAG_ERROR 101
#define ALERT_TAG_SUBMIT 100
#define ALERT_TAG_RESET 102

#define N_ATTENTION_LOOPS 10
#define N_MEDITATION_LOOPS 6

#define MIN_READINGS 30
#define MAX_READINGS 64*64


@interface ViewController : UITableViewController <TGAccessoryDelegate> { //SRWebSocketDelegate
    
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
    //int webSocketStatus;
    //SRWebSocket *webSocket;
    NSMutableArray* readings;
    NSMutableArray* events;
    NSTimeInterval interval;
    CMAttitude* attitude;
    CMRotationRate rotationRate;
    CMAcceleration userAcceleration;
    AEChannelGroupRef brainSoundGroup;
    AEAudioFilePlayer* attentionFiles[N_ATTENTION_LOOPS];
    AEAudioFilePlayer* meditationFiles[N_MEDITATION_LOOPS];
    AEAudioFilePlayer* ticks[3];
    NSDate* lastReading;
}

// SocketRocket
//- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
//- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
//- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
//- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

@property (retain, nonatomic) AEAudioController *audioController;
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
