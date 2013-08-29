//
//  ViewController.m
//  BrainProxy
//
//  Created by Jeffrey Crouse on 8/21/13.
//  Copyright (c) 2013 Jeffrey Crouse. All rights reserved.
//

#import "ViewController.h"



@interface ViewController ()

@end

@implementation ViewController

@synthesize recordButton, submitButton, resetButton;
@synthesize soundSwitch;
@synthesize motionManager;
@synthesize audioController;
@synthesize successSound, errorSound, adjustHeadsetSound, reverb; //, blinkSound, shakeSound, ;



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"currentDevice name = %@", [[UIDevice currentDevice] name]);
#pragma mark Init vars

    poorSignalValue = 500;
    readings = [NSMutableArray arrayWithObjects: nil];
    events = [NSMutableArray arrayWithObjects: nil];
    lastRecordedReading = [[NSDate date] dateByAddingTimeInterval:-20];
    lastDataReceived = [[NSDate date] dateByAddingTimeInterval:-20];
    SSID = @"None";
   
    
#pragma mark headerView   

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 100)];
    headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    float x = 20;
    float y = 10;
    float width = ((headerView.bounds.size.width-50) / 2);
    float height = headerView.bounds.size.height - 20;
    
    self.recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [recordButton setTitle:@"Stop" forState:UIControlStateSelected];
    [recordButton addTarget:self action:@selector(record:) forControlEvents:UIControlEventTouchUpInside];
    recordButton.frame = CGRectMake(x, y, width, height);
    recordButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    recordButton.selected = NO;
    
    x = CGRectGetMaxX(recordButton.frame)+10;
    height = (headerView.bounds.size.height - 20) * 0.6;
    
    self.submitButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [submitButton setTitle:@"Submit" forState:UIControlStateNormal];
    [submitButton addTarget:self action:@selector(submitJourney:) forControlEvents:UIControlEventTouchUpInside];
    submitButton.frame = CGRectMake(x, y, width, height);
    submitButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    
    y += (headerView.bounds.size.height - 20) * 0.7;
    height = (headerView.bounds.size.height - 20) * 0.3;
    
    self.resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(resetJourney:) forControlEvents:UIControlEventTouchUpInside];
    resetButton.frame = CGRectMake(x, y, width, height);
    resetButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    
    
    [headerView addSubview:recordButton];
    [headerView addSubview:submitButton];
    [headerView addSubview:resetButton];
    self.tableView.tableHeaderView = headerView;

    
#pragma mark soundSwitch

    soundSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [soundSwitch setOn:NO animated:NO];
    [soundSwitch addTarget:self action:@selector(toggleSound:) forControlEvents:UIControlEventValueChanged];
    
    
#pragma mark motionManager

    [self becomeFirstResponder];
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 0.1;
    
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                            withHandler:^(CMDeviceMotion *motion, NSError *error){
                                                attitude = [motion attitude];
                                                rotationRate = [motion rotationRate];
                                                userAcceleration = [motion userAcceleration];
                                                [self reloadSection: SECTION_MOTION];
                                            }];
    
    
#pragma mark audioController

    self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription] inputEnabled:NO];
    self.audioController.preferredBufferDuration = 0.005;
    
    
    NSURL* successSoundURL = [[NSBundle mainBundle] URLForResource:@"Success" withExtension:@"wav"];
    successSound = [AEAudioFilePlayer audioFilePlayerWithURL:successSoundURL
                                                  audioController:self.audioController
                                                       error:NULL];
    successSound.volume = 0.5;
    successSound.channelIsPlaying = NO;
    

    NSURL* errorSoundURL = [[NSBundle mainBundle] URLForResource:@"Error" withExtension:@"wav"];
    errorSound = [AEAudioFilePlayer audioFilePlayerWithURL:errorSoundURL
                                                  audioController:self.audioController
                                                            error:NULL];
    errorSound.volume = 0.5;
    errorSound.channelIsPlaying = NO;
    
    
    NSURL* adjustHeadsetSoundURL = [[NSBundle mainBundle] URLForResource:@"AdjustHeadset" withExtension:@"wav"];
    adjustHeadsetSound = [AEAudioFilePlayer audioFilePlayerWithURL:adjustHeadsetSoundURL
                                           audioController:self.audioController
                                                     error:NULL];
    adjustHeadsetSound.volume = 0.5;
    adjustHeadsetSound.channelIsPlaying = NO;
    adjustHeadsetSound.loop = YES;
    
    
    
    [audioController addChannels:[NSArray arrayWithObjects:successSound, errorSound, adjustHeadsetSound, nil]];
    
    
    
    brainSoundGroup = [audioController createChannelGroup];
    [audioController setMuted:YES forChannelGroup:brainSoundGroup];
    
    
    
        
    NSArray* attentionSounds = @[@"Silence",
                                @"BrainWave03-Attn",
                                @"BrainWave06-Attn",
                                @"Silence",
                                @"BRainWave16-Attn",
                                @"BrainWave07-Attn",
                                @"BrainWave10-Attn",
                                @"Silence",
                                @"BrainWave09-Attn",
                                @"BrainWave17-Attn",
                                @"Silence"];
    
    NSArray* meditationSounds = @[@"Silence",
                                @"BrainWave15-Med",
                                @"BrainWave11-Med",
                                @"Silence",
                                @"BrainWave04-Both",
                                @"BrainWave12-Med",
                                @"BrainWave14-Both",
                                @"BrainWave13-Med",
                                @"Silence"];
    
    attentionLoops = [[NSMutableArray alloc] init];
    //for (id fname in attentionSounds) {
    for(int i=0; i<[attentionSounds count]; i++)
    {
        NSURL* url = [[NSBundle mainBundle] URLForResource:[attentionSounds objectAtIndex:i] withExtension:@"wav"];
        NSLog(@"Loading %@", url);
        NSError* err;
        AEAudioFilePlayer *filePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:url
                                                      audioController:self.audioController
                                                                error:&err];
        if(err)
            NSLog(@"%@", [err localizedDescription]);
        filePlayer.loop = YES;
        filePlayer.channelIsPlaying = NO;
        [attentionLoops addObject:filePlayer];
    }
    
    meditationLoops = [[NSMutableArray alloc] init];
    //for (id fname in meditationSounds)
    for(int i=0; i<[meditationSounds count]; i++)
    {
        NSURL* url = [[NSBundle mainBundle] URLForResource:[meditationSounds objectAtIndex:i] withExtension:@"wav"];
        NSLog(@"Loading %@", url);
        NSError* err;
        AEAudioFilePlayer *filePlayer = [AEAudioFilePlayer audioFilePlayerWithURL:url
                                                                  audioController:self.audioController
                                                                            error:&err];
        if(err) 
            NSLog(@"%@", [err localizedDescription]);
 
        filePlayer.loop = YES;
        filePlayer.channelIsPlaying = NO;
        [meditationLoops addObject:filePlayer];
    }
    
    [audioController addChannels:attentionLoops toChannelGroup:brainSoundGroup];
    [audioController addChannels:meditationLoops toChannelGroup:brainSoundGroup];
    
    
    //
    // TICKS
    //
    for(int i=0; i<3; i++) {
        NSString* base = [NSString stringWithFormat:@"Tick%02d", i+1];
        NSURL* url = [[NSBundle mainBundle] URLForResource:base withExtension:@"wav"];
        ticks[i] = [AEAudioFilePlayer audioFilePlayerWithURL:url
                                             audioController:self.audioController
                                                       error:NULL];
        ticks[i].volume = 0.1;
        ticks[i].channelIsPlaying = NO;
    }
    [self.audioController addChannels:[NSArray arrayWithObjects:ticks count:3]];
    
    
    //
    //  REVERB!
    //
    AudioComponentDescription component  = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple,
                                                                           kAudioUnitType_Effect,
                                                                           kAudioUnitSubType_Reverb2);
    NSError *error = NULL;
    self.reverb = [[AEAudioUnitFilter alloc]
                   initWithComponentDescription:component
                   audioController:audioController
                   error:&error];
    
    
    [audioController addFilter:reverb toChannelGroup:brainSoundGroup];


#pragma mark KICK IT OFF!
    
    [self.audioController start:NULL];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(update:) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(slowUpdate:) userInfo:nil repeats:YES];
}

/*
-(void)doSample:(NSTimer*)t
{
    
    if(recordButton.selected)
    {
        NSDictionary* event = @{@"shake":
                                    @{@"x": [NSNumber numberWithDouble: userAcceleration.x],
                                      @"y": [NSNumber numberWithDouble: userAcceleration.y],
                                      @"z": [NSNumber numberWithDouble: userAcceleration.z]}};
        
        NSDictionary* message = @{@"data": event, @"date":[self isoDate]};
        [events addObject:message];
    }
    
    float sampleRate = [[NSUserDefaults standardUserDefaults] floatForKey:@"sample_rate"];
    NSLog(@"doSample: %f", sampleRate);
    [NSTimer scheduledTimerWithTimeInterval:sampleRate target:self selector:@selector(doSample:) userInfo:nil repeats:NO];
}
*/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}


#pragma mark -Utility Methods

float ofMap(float value, float inputMin, float inputMax, float outputMin, float outputMax, bool clamp) {
    
	if (fabs(inputMin - inputMax) < FLT_EPSILON){
		NSLog(@"ofMap(): avoiding possible divide by zero, check inputMin and inputMax: %f %f", inputMin , inputMax);
		return outputMin;
	} else {
		float outVal = ((value - inputMin) / (inputMax - inputMin) * (outputMax - outputMin) + outputMin);
        
		if( clamp ){
			if(outputMax < outputMin){
				if( outVal < outputMax )outVal = outputMax;
				else if( outVal > outputMin )outVal = outputMin;
			}else{
				if( outVal > outputMax )outVal = outputMax;
				else if( outVal < outputMin )outVal = outputMin;
			}
		}
		return outVal;
	}
    
}


-(void)slowUpdate:(NSTimer*)t
{
    CFArrayRef myArray = CNCopySupportedInterfaces();
    CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
    NSDictionary *myDictionary = (__bridge_transfer NSDictionary*)myDict;
    if([myDictionary objectForKey:@"SSID"]!=nil)
        SSID = [myDictionary objectForKey:@"SSID"];
    
    [self reloadSection:SECTION_STATUS];
}

#define LOOP_FALLOFF 2

- (void) update:(NSTimer*)t
{
    if(recordButton.selected) {
        interval += [t timeInterval];
    }
    [self reloadSection:SECTION_RECORDING];
    
    attentionEased += (attention-attentionEased) / 20.0;
    meditationEased += (meditation-meditationEased) / 20.0;
    attentionTeir = ofMap(attentionEased, 0, 100, 0, [attentionLoops count], true);
    meditationTeir = ofMap(meditationEased, 0, 100, 0, [meditationLoops count], true);
    
    AEAudioFilePlayer* filePlayer;
    for(int i=0; i<[attentionLoops count]; i++) {
        float dist = fabs(attentionTeir - i);
        float volume = ofMap(dist, 0, LOOP_FALLOFF, 0.25, 0, true);
        filePlayer = [attentionLoops objectAtIndex:i];
        filePlayer.volume = volume;
        filePlayer.channelIsPlaying = (volume>0);
    }
    
    for(int i=0; i<[meditationLoops count]; i++) {
        float dist = fabs(meditationTeir - i);
        float volume = ofMap(dist, 0, LOOP_FALLOFF, 0.25, 0, true);
        filePlayer = [meditationLoops objectAtIndex:i];
        filePlayer.volume = volume;
        filePlayer.channelIsPlaying = (volume>0);
    }
    
    BOOL accessoryConnected = [[TGAccessoryManager sharedTGAccessoryManager] accessory] != nil && [[TGAccessoryManager sharedTGAccessoryManager] connected];
    BOOL receivingData = poorSignalValue < 50 || [[NSDate date] timeIntervalSinceDate:lastDataReceived] < ACCESSORY_TIMEOUT;
    
    accessoryActive = accessoryConnected && receivingData;

    
    if(recordButton.selected) {
        //NSLog(@"accessoryActive = %@", accessoryActive? @"Yes" : @"No");
        adjustHeadsetSound.channelIsPlaying = !accessoryActive;
    } else {
        recordButton.alpha = (accessoryActive) ? 1 : 0.4;
        recordButton.enabled = accessoryActive;
        adjustHeadsetSound.channelIsPlaying = NO;
    }
    
    submitButton.alpha = resetButton.alpha = [readings count] > MIN_READINGS ? 1 : 0.4;
    submitButton.enabled = resetButton.enabled = [readings count] > MIN_READINGS;
    
    float avg = (fabs(userAcceleration.x) + fabs(userAcceleration.y) + fabs(userAcceleration.z)) / 3.0;
    float mix = ofMap(avg, 0, 3, 0, 100, true);
    AudioUnitSetParameter(reverb.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, mix, 0);

    float decay = ofMap(fabs(180/M_PI)*attitude.pitch, 0, 90, 0.001, 20, true);
    AudioUnitSetParameter(reverb.audioUnit, kReverb2Param_DecayTimeAt0Hz, kAudioUnitScope_Global, 0, decay, 0);
    
    
    [self reloadSection:SECTION_DEBUG];
}


/*
#pragma mark - Recording

- (void)beginRecording {
    // Init recorder
    self.recorder = [[AERecorder alloc] initWithAudioController:audioController];
    NSString *documentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                                 objectAtIndex:0];
    NSString *filePath = [documentsFolder stringByAppendingPathComponent:@"Recording.aiff"];
    // Start the recording process
    NSError *error = NULL;
    if ( ![self.recorder beginRecordingToFileAtPath:filePath
                                       fileType:kAudioFileAIFFType
                                          error:&error] ) {
        // Report error
        return;
    }
    // Receive both audio input and audio output. Note that if you're using
    // AEPlaythroughChannel, mentioned above, you may not need to receive the input again.
    [self.audioController addInputReceiver:self.recorder];
    [self.audioController addOutputReceiver:self.recorder];
}

- (void)endRecording
    {
    [self.audioController removeInputReceiver:self.recorder];
    [self.audioController removeOutputReceiver:self.recorder];
    [self.recorder finishRecording];
    self.recorder = nil;
}
*/
#pragma mark - Action Buttons

- (void)record:(id)sender
{
    if(recordButton.selected) {
        recordButton.selected = NO;
        
        ticks[0].currentTime = 0;
        ticks[0].volume = 0.25;
        ticks[0].channelIsPlaying = YES;
    } else {
        recordButton.selected = YES;
        
        ticks[1].currentTime = 0;
        ticks[1].volume = 0.25;
        ticks[1].channelIsPlaying = YES;
    }
}


- (void)submitJourney:(id)sender
{
    NSLog(@"submitJourney");
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"email"
                                                     message:@"Please enter your email address (optional):"
                                                    delegate:self
                                           cancelButtonTitle:@"Continue"
                                           otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = ALERT_TAG_SUBMIT;
    
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeEmailAddress;
    alertTextField.placeholder = @"you@email.com";
    [alert show];
    
    recordButton.selected = NO;
}

- (void)resetJourney:(id)sender
{
    NSLog(@"resetJourney");
    recordButton.selected = NO;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Reset?"
                                                    message:@"Are you sure you want to reset?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil ];
    alert.tag = ALERT_TAG_RESET;
    [alert show];

}

- (void)toggleSound:(UISwitch*)sender
{
    [audioController setMuted:!sender.isOn forChannelGroup:brainSoundGroup];
    if ( sender.isOn ) {
        NSLog(@"Sound ON");
    } else {
        NSLog(@"Sound OFF");
    }
}


#pragma mark - AlertView delagate



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(alertView.tag==ALERT_TAG_RESET && buttonIndex==1)
    {
        [readings removeAllObjects];
        [events removeAllObjects];
        interval = 0;
    }
    
    if(alertView.tag==ALERT_TAG_ERROR)
    {
        
    }
    
    if(alertView.tag==ALERT_TAG_SUBMIT) // SubmitJourney
    {
        NSLog(@"Entered: %@", [[alertView textFieldAtIndex:0] text]);
        //NSNumber* client_id = [NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey:@"client_id"]];
        NSString* email = [[alertView textFieldAtIndex:0] text];
        NSDictionary* data = @{@"client_id": [[UIDevice currentDevice] name],
                               @"route": @"submit",
                               @"date": [self isoDate], //[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970]],
                               @"email": email,
                               @"readings": readings,
                               @"events": events};
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"Journey: %@", jsonString);
  
        NSURL* url = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"endpoint"]];
        __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request addRequestHeader:@"User-Agent" value:@"ASIHTTPRequest"];
        [request addRequestHeader:@"Content-Type" value:@"application/json"];
        [request appendPostData:jsonData];
        [request setCompletionBlock:^{

            NSError *jsonError = nil;
            NSData* data = [[request responseString] dataUsingEncoding:NSUTF8StringEncoding];
            id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            if ([jsonObject isKindOfClass:[NSArray class]]) {
                //NSArray *jsonArray = (NSArray *)jsonObject;
                // do something with the array?
            }
            else {
                NSDictionary *dict = (NSDictionary *)jsonObject;
                NSString* status = [dict valueForKey:@"status"];
                NSLog(@"status = %@", status);
                if([status isEqualToString:@"OK"]) {

                    self.successSound.currentTime = 0;
                    self.successSound.channelIsPlaying = YES;
                    [readings removeAllObjects];
                    interval = 0;
                    
                } else {
                    
                    self.errorSound.currentTime = 0;
                    self.errorSound.channelIsPlaying = YES;
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                    message:[dict valueForKey:@"status"]
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles: nil];
                    alert.tag = ALERT_TAG_ERROR;
                    [alert show];
                }
 
            }
        }];
        [request setFailedBlock:^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[[request error] localizedDescription]  delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
            alert.tag = ALERT_TAG_ERROR;
            [alert show];
        }];
        [request startSynchronous];
        //if(webSocket != nil) [webSocket send: jsonString];
    }
}



#pragma mark - Motion 

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        NSLog(@"Shake motionBegan");
        
        if(recordButton.selected)
        {
            NSDictionary* data = @{@"x": [NSNumber numberWithDouble: userAcceleration.x],
                                   @"y": [NSNumber numberWithDouble: userAcceleration.y],
                                   @"z": [NSNumber numberWithDouble: userAcceleration.z]};
            
            NSDictionary* event = @{@"eventType": @"shake", @"date":[self isoDate], @"data": data};
            [events addObject:event];
        }
    }
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        NSLog(@"Shake motionEnded");
    }
}



#pragma mark - ThinkGear

//  This method gets called by the TGAccessoryManager when a ThinkGear-enabled
//  accessory is connected.
- (void)accessoryDidConnect:(EAAccessory *)accessory {
    // toss up a UIAlertView when an accessory connects
    UIAlertView * a = [[UIAlertView alloc] initWithTitle:@"Accessory Connected"
                                                 message:[NSString stringWithFormat:@"A ThinkGear accessory called %@ was connected to this device.", [accessory name]]
                                                delegate:nil
                                       cancelButtonTitle:@"Okay"
                                       otherButtonTitles:nil];
    [a show];
    
    // start the data stream to the accessory
    [[TGAccessoryManager sharedTGAccessoryManager] startStream];
}

- (NSString*)isoDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];

    NSString *iso8601String = [dateFormatter stringFromDate:[NSDate date]];
    return iso8601String;
}

//  This method gets called by the TGAccessoryManager when a ThinkGear-enabled
//  accessory is disconnected.
- (void)accessoryDidDisconnect {
    // toss up a UIAlertView when an accessory disconnects
    UIAlertView * a = [[UIAlertView alloc] initWithTitle:@"Accessory Disconnected"
                                                 message:@"The ThinkGear accessory was disconnected from this device."
                                                delegate:nil
                                       cancelButtonTitle:@"Okay"
                                       otherButtonTitles:nil];
    [a show];
}

//  This method gets called by the TGAccessoryManager when data is received from the
//  ThinkGear-enabled device.
- (void)dataReceived:(NSDictionary *)data {

    if([data valueForKey:@"poorSignal"])
        poorSignalValue = [[data valueForKey:@"poorSignal"] intValue];
    
    if([data valueForKey:@"blinkStrength"]) {
        blinkStrength = [[data valueForKey:@"blinkStrength"] intValue];
        if(recordButton.selected)
        {
            NSDictionary* message = @{@"eventType": @"blink", @"date":[self isoDate], @"data": @{@"strength": [NSNumber numberWithInt:blinkStrength]}};
            [events addObject:message];
        }
        //self.blinkSound.currentTime = 0;
        //self.blinkSound.channelIsPlaying = YES;
    }
    
    BOOL bNewReading = NO;
    if([data valueForKey:@"eSenseAttention"]){
        attention = [[data valueForKey:@"eSenseAttention"] intValue];
        if(attention>0) bNewReading = YES;
    }
    
    if([data valueForKey:@"eSenseMeditation"]) {
        meditation = [[data valueForKey:@"eSenseMeditation"] intValue];
        if(meditation>0) bNewReading = YES;
    }
    
    if([data valueForKey:@"eegDelta"])
        delta =   [[data valueForKey:@"eegDelta"] intValue];

    if([data valueForKey:@"eegTheta"])
        theta =   [[data valueForKey:@"eegTheta"] intValue];
    
    if([data valueForKey:@"eegLowAlpha"])
        lowAlpha =   [[data valueForKey:@"eegLowAlpha"] intValue];
    
    if([data valueForKey:@"eegHighAlpha"])
        highAlpha =   [[data valueForKey:@"eegHighAlpha"] intValue];
    
    if([data valueForKey:@"eegLowBeta"])
        lowBeta =   [[data valueForKey:@"eegLowBeta"] intValue];
    
    if([data valueForKey:@"eegHighBeta"])
        highBeta =   [[data valueForKey:@"eegHighBeta"] intValue];
    
    if([data valueForKey:@"eegLowGamma"])
        lowGamma =   [[data valueForKey:@"eegLowGamma"] intValue];
    
    if([data valueForKey:@"eegHighGamma"])
        highGamma =   [[data valueForKey:@"eegHighGamma"] intValue];
    

    if(bNewReading)
    {
        lastDataReceived = [NSDate date];
        BOOL timeForNewRecording =
            [[NSDate date] timeIntervalSinceDate:lastRecordedReading] >
            [[NSUserDefaults standardUserDefaults] floatForKey:@"sample_rate"];
        if(recordButton.selected && timeForNewRecording) {
            ticks[2].volume = 0.1;
            ticks[2].currentTime = 0;
            ticks[2].channelIsPlaying = YES;
            NSDictionary* reading = @{@"date":[self isoDate], @"data": @{@"attention": [NSNumber numberWithInt:attention],
                                                                         @"meditation": [NSNumber numberWithInt:meditation]}};
            [readings addObject:reading];
            if([readings count]>MAX_READINGS) {
                //TO DO:  do something!  stop recording?  [readings removeObjectAtIndex:0]?
            }
            //NSError *error;
            //NSLog(@"%@", [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:reading options:NSJSONWritingPrettyPrinted error:&error] encoding:NSUTF8StringEncoding]);
            
            lastRecordedReading = [NSDate date];
            [self reloadSection:SECTION_RECORDING];
        }
    }
        
    
    [self reloadSection: SECTION_THINKGEAR];
}


#pragma mark - SocketRocket

 
/*
 
- (void)wsConnect
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];

    webSocketStatus = SOCKET_STATUS_CONNECTING;

    NSLog( @"host = %@", [userDefaults stringForKey:@"host"] );

    NSURL* url = [NSURL URLWithString:[userDefaults stringForKey:@"host"]];
    webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:url]];
    webSocket.delegate = self;
    [webSocket open];
}
 
- (void)webSocketDidOpen:(SRWebSocket *)_webSocket;
{
    NSLog(@"Websocket Connected");
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"%@", [NSString stringWithFormat:@"Connected to %@", [userDefaults stringForKey:@"host"]]);
    webSocketStatus = SOCKET_STATUS_OPEN;
}

- (void)webSocket:(SRWebSocket *)_webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    webSocket = nil;
    
    webSocketStatus = SOCKET_STATUS_CONNECTING;
    [NSTimer scheduledTimerWithTimeInterval: 3.0 target: self
                                   selector: @selector(wsConnect) userInfo: nil repeats: NO];
}

- (void)webSocket:(SRWebSocket *)_webSocket didReceiveMessage:(id)message;
{
    NSLog(@"Received \"%@\"", message);
    
    NSError *jsonError = nil;
    NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
    
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSArray *jsonArray = (NSArray *)jsonObject;
        NSLog(@"jsonArray - %@",jsonArray);
    }
    else {
        NSDictionary *dict = (NSDictionary *)jsonObject;
        NSString* route = [dict valueForKey:@"route"];
        if([route isEqualToString:@"saveStatus"]) {
            if([[dict valueForKey:@"status"] isEqualToString:@"OK"]) {
                NSLog(@"Success saving!");
                self.successSound.currentTime = 0;
                self.successSound.channelIsPlaying = YES;
                [readings removeAllObjects];
                interval = 0;
                
            } else {
                NSLog(@"Error saving!");
                self.errorSound.currentTime = 0;
                self.errorSound.channelIsPlaying = YES;
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[dict valueForKey:@"status"]  delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                alert.tag = 101;
                [alert show];
                
            }
        } else {
            NSLog(@"UNKNOWN ROUTE!");
        }
    }
}

- (void)webSocket:(SRWebSocket *)_webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    webSocket = nil;
    webSocketStatus = SOCKET_STATUS_CONNECTING;
    [NSTimer scheduledTimerWithTimeInterval: 3.0 target: self
                                   selector: @selector(wsConnect) userInfo: nil repeats: NO];
}
*/



#pragma mark - Table view data source




- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 6;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case SECTION_RECORDING: return @"Recording";
        case SECTION_CONTROLS: return @"Controls";
        case SECTION_STATUS: return @"Status";
        case SECTION_THINKGEAR: return @"Brain Activity";
        case SECTION_MOTION: return @"Motion";
        case SECTION_DEBUG: return @"Debug";
        default:
            return [NSString stringWithFormat:@"Section %d", section];
    }
}

- (void) reloadSection:(NSUInteger)section
{
    [self.tableView beginUpdates];

    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:section];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];

    //[self.tableView reloadData];
    [self.tableView endUpdates];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch(section) {
        case SECTION_RECORDING: return 2;
        case SECTION_CONTROLS: return 1;
        case SECTION_STATUS: return 3;
        case SECTION_THINKGEAR: return 11;
        case SECTION_MOTION: return 5;
        case SECTION_DEBUG: return 5;
        default: return 4;
    }    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell_%d_%d", indexPath.section, indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Configure the cell...
    switch(indexPath.section) {
            
        
        case SECTION_RECORDING:
            switch(indexPath.row) {
                case 0:
                    [[cell textLabel] setText:@"Record Time"];
                    
                    NSInteger ti = (NSInteger)interval;
                    NSInteger seconds = ti % 60;
                    NSInteger minutes = (ti / 60) % 60;
                    NSInteger hours = (ti / 3600);
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds]];
                    break;
                    
                case 1:
                    [[cell textLabel] setText:@"Readings"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", [readings count]]];
                    break;
            }
            break;
        
        case SECTION_CONTROLS:
            cell.textLabel.text = @"Sound";
            cell.accessoryView = soundSwitch;
            break;
            
            
        case SECTION_STATUS:
            // TO DO:  shouldn't reload image every time section is updated!!
            switch(indexPath.row) {
                case 0:
                    [[cell textLabel] setText:@"Signal Strength"];
       
                    if(poorSignalValue == 0) {
                        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Signal_Connected"]];
                    }
                    else if(poorSignalValue > 0 && poorSignalValue < 50) {
                        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Signal_Connecting3"]];
                    }
                    else if(poorSignalValue > 50 && poorSignalValue < 200) {
                        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Signal_Connecting2"]];
                    }
                    else if(poorSignalValue == 200) {
                        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Signal_Connecting1"]];
                    }
                    else {
                        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Signal_Disconnected"]];
                    }
                    break;

                case 1:
                    [[cell textLabel] setText:@"Device Name"];
                    [[cell detailTextLabel] setText:[[UIDevice currentDevice] name]];
                    break;
                case 2:
                    [[cell textLabel] setText:@"WiFi Network"];
                    [[cell detailTextLabel] setText:SSID];
                    break;
            }
            break;
            
        case SECTION_DEBUG:
           
            switch(indexPath.row) {
                case 0:
                    [[cell textLabel] setText:@"Meditation Eased"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", meditationEased]];
                    break;
                case 1:
                    [[cell textLabel] setText:@"Attention Eased"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", attentionEased]];
                    break;
                case 2:
                    [[cell textLabel] setText:@"Meditation Teir"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", meditationTeir]];
                    break;
                case 3:
                    [[cell textLabel] setText:@"Attention Teir"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", attentionTeir]];
                    break;
                case 4:
                    [[cell textLabel] setText:@"Time Since Last Data"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", [[NSDate date] timeIntervalSinceDate:lastDataReceived]]];
                    break;
            }
            break;
            
            
        case SECTION_THINKGEAR:
            switch (indexPath.row) {
                case 0:
                    [[cell textLabel] setText:@"Attention"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", attention]];
                    break;
                case 1:
                    [[cell textLabel] setText:@"Meditation"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", meditation]];
                    break;
                case 2:
                    [[cell textLabel] setText:@"Blink Strength"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", blinkStrength]];
                    break;
                case 3:
                    [[cell textLabel] setText:@"Delta"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", delta]];
                    break;
                case 4:
                    [[cell textLabel] setText:@"Theta"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", theta]];
                    break;
                case 5:
                    [[cell textLabel] setText:@"Low Alpha"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", lowAlpha]];
                    break;
                case 6:
                    [[cell textLabel] setText:@"High Alpha"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", highAlpha]];
                    break;
                case 7:
                    [[cell textLabel] setText:@"Low Beta"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", lowBeta]];
                    break;
                case 8:
                    [[cell textLabel] setText:@"High Beta"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", highBeta]];
                    break;
                case 9:
                    [[cell textLabel] setText:@"Low Gamma"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", lowGamma]];
                    break;
                case 10:
                    [[cell textLabel] setText:@"High Gamma"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", highGamma]];
                    break;
            }
            break;
            
        case SECTION_MOTION:
            switch (indexPath.row) {
                case 0:
                    [[cell textLabel] setText:@"Yaw"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", (180/M_PI)*attitude.yaw]];
                    break;
                case 1:
                    [[cell textLabel] setText:@"Pitch"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", (180/M_PI)*attitude.pitch]];
                    break;
                case 2:
                    [[cell textLabel] setText:@"Roll"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", (180/M_PI)*attitude.roll]];
                    break;
                case 3:
                    [[cell textLabel] setText:@"Rotation Speed"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f, %.2f, %.2f",
                                                     rotationRate.x,
                                                     rotationRate.y,
                                                     rotationRate.z]];
                    break;
                case 4:
                    [[cell textLabel] setText:@"User Acceleration"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f, %.2f, %.2f",
                                                     userAcceleration.x,
                                                     userAcceleration.y,
                                                     userAcceleration.z]];
                default:
                    break;
            }
            break;
        default:
            [[cell textLabel] setText:CellIdentifier];
            break;
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
