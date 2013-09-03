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

@synthesize recordButton;
@synthesize doneButton;
@synthesize resetButton;
@synthesize buttonSound;
@synthesize tickSound;
@synthesize soundSwitch;
@synthesize motionManager;
@synthesize audioController;
@synthesize successSound;
@synthesize errorSound;
@synthesize adjustHeadsetSound;
//@synthesize reverb;



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
    connectivityStatus = @"Unknown";

    
#pragma mark headerView   

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 70)];
    headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    float x = 10;
    float y = 10;
    float width = ((headerView.bounds.size.width-30) / 2);
    float height = headerView.bounds.size.height - 10;
    
    self.recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    //[recordButton setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
    //[recordButton setTintColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0]];
    [recordButton setTitleColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [recordButton setTitle:@"Pause" forState:UIControlStateSelected];
    [recordButton addTarget:self action:@selector(toggleRecord:) forControlEvents:UIControlEventTouchUpInside];
    recordButton.frame = CGRectMake(x, y, width, height);
    recordButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    recordButton.selected = NO;
    [headerView addSubview:recordButton];
    
  
    x = CGRectGetMaxX(recordButton.frame)+10;
    //height = (headerView.bounds.size.height - 20) * 0.6;
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [doneButton setTitleColor:[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
    doneButton.frame = CGRectMake(x, y, width, height);
    doneButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    [headerView addSubview:doneButton];
    
      /*
    y += (headerView.bounds.size.height - 20) * 0.7;
    height = (headerView.bounds.size.height - 20) * 0.3;
    
        */
    
    self.tableView.tableHeaderView = headerView;

    
#pragma mark footerView
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 80)];
    footerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    self.resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [resetButton setTitle:@"Reset" forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(resetJourney:) forControlEvents:UIControlEventTouchUpInside];
    resetButton.frame = CGRectMake(10, 10, footerView.bounds.size.width-20, 40);
    resetButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    [footerView addSubview:resetButton];

    self.tableView.tableFooterView = footerView;
    
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
                                                //[self reloadSection: SECTION_MOTION];
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
    
    NSURL* buttonSoundURL = [[NSBundle mainBundle] URLForResource:@"Button" withExtension:@"wav"];
    buttonSound = [AEAudioFilePlayer audioFilePlayerWithURL:buttonSoundURL
                                           audioController:self.audioController
                                                     error:NULL];
    //buttonSound.volume = 0.5;
    buttonSound.channelIsPlaying = NO;
    
    
    NSURL* tickSoundURL = [[NSBundle mainBundle] URLForResource:@"Tick" withExtension:@"wav"];
    tickSound = [AEAudioFilePlayer audioFilePlayerWithURL:tickSoundURL
                                            audioController:self.audioController
                                                      error:NULL];
    //tickSound.volume = 0.5;
    tickSound.channelIsPlaying = NO;
    
    
    NSURL* adjustHeadsetSoundURL = [[NSBundle mainBundle] URLForResource:@"AdjustHeadset" withExtension:@"wav"];
    adjustHeadsetSound = [AEAudioFilePlayer audioFilePlayerWithURL:adjustHeadsetSoundURL
                                           audioController:self.audioController
                                                     error:NULL];
    adjustHeadsetSound.volume = 0.5;
    adjustHeadsetSound.channelIsPlaying = NO;
    adjustHeadsetSound.loop = YES;
    
    
    
    [audioController addChannels:[NSArray arrayWithObjects:successSound, errorSound, buttonSound, tickSound, adjustHeadsetSound, nil]];
    
    
    
    brainSoundGroup = [audioController createChannelGroup];
    [audioController setMuted:YES forChannelGroup:brainSoundGroup];
        
    NSArray* attentionSounds = @[@"Silence",
                                @"BrainWave03-Attn",
                                @"BrainWave06-Attn",
                                @"Silence",
                                @"BrainWave16-Attn",
                                //@"BrainWave07-Attn",
                                @"Silence",
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
    //  REVERB!
    //
    /*
    AudioComponentDescription component  = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple,
                                                                           kAudioUnitType_Effect,
                                                                           kAudioUnitSubType_Reverb2);
    NSError *error = NULL;
    self.reverb = [[AEAudioUnitFilter alloc]
                   initWithComponentDescription:component
                   audioController:audioController
                   error:&error];
    
    
    [audioController addFilter:reverb toChannelGroup:brainSoundGroup];
    */

#pragma mark KICK IT OFF!
    
    [self.audioController start:NULL];
    [NSTimer scheduledTimerWithTimeInterval:8 target:self selector:@selector(connectivityCheck:) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(update:) userInfo:nil repeats:YES];
#if !(TARGET_IPHONE_SIMULATOR)
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(slowUpdate:) userInfo:nil repeats:YES];
#endif
}


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

#pragma mark - NSTimer 

-(void)connectivityCheck:(NSTimer*)t
{
    connectivityStatus = @"Checking...";
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/ping", [[NSUserDefaults standardUserDefaults] stringForKey:@"server"]]];
    // __block   ... removed??
    __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

    [request setCompletionBlock:^{
        connectivityStatus = [request responseString];
    }];
    [request setFailedBlock:^{
        connectivityStatus = [[request error] localizedDescription];
    }];
    [request startAsynchronous];
    
    [self reloadSection:SECTION_STATUS];
}


-(void)slowUpdate:(NSTimer*)t
{
#if !(TARGET_IPHONE_SIMULATOR)
    CFArrayRef myArray = CNCopySupportedInterfaces();
    CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
    NSDictionary *myDictionary = (__bridge_transfer NSDictionary*)myDict;
    if([myDictionary objectForKey:@"SSID"]!=nil)
        SSID = [myDictionary objectForKey:@"SSID"];
    else
        SSID = @"None";
    [self reloadSection:SECTION_STATUS];
#endif
}



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
    
    float max_volume = 1;
    
    AEAudioFilePlayer* filePlayer;
    for(int i=0; i<[attentionLoops count]; i++) {
        float dist = fabs(attentionTeir - i);
        filePlayer = [attentionLoops objectAtIndex:i];
        filePlayer.volume = ofMap(dist, 0, LOOP_FALLOFF, max_volume, 0, true);
        filePlayer.channelIsPlaying = (filePlayer.volume>0);
    }
    
    for(int i=0; i<[meditationLoops count]; i++) {
        float dist = fabs(meditationTeir - i);
        filePlayer = [meditationLoops objectAtIndex:i];
        filePlayer.volume = ofMap(dist, 0, LOOP_FALLOFF, max_volume, 0, true);
        filePlayer.channelIsPlaying = (filePlayer.volume>0);
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
    
    doneButton.alpha = [readings count] > MIN_READINGS ? 1 : 0.4;
    doneButton.enabled = [readings count] > MIN_READINGS;
    
    /*
    float avg = (fabs(userAcceleration.x) + fabs(userAcceleration.y) + fabs(userAcceleration.z)) / 3.0;
    float mix = ofMap(avg, 0, 3, 0, 100, true);
    AudioUnitSetParameter(reverb.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, mix, 0);

    float decay = ofMap(fabs(180/M_PI)*attitude.pitch, 0, 90, 0.001, 20, true);
    AudioUnitSetParameter(reverb.audioUnit, kReverb2Param_DecayTimeAt0Hz, kAudioUnitScope_Global, 0, decay, 0);
    */
    
    //[self reloadSection:SECTION_DEBUG];
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

- (void)toggleRecord:(id)sender
{
    recordButton.selected = !recordButton.selected;
    buttonSound.currentTime = 0;
    buttonSound.channelIsPlaying = YES;
    if(recordButton.selected) {
        [soundSwitch setOn:YES animated:YES];
        [audioController setMuted:NO forChannelGroup:brainSoundGroup];
    } else {
        [soundSwitch setOn:NO animated:YES];
        [audioController setMuted:YES forChannelGroup:brainSoundGroup];
    }
}


- (void)done:(id)sender
{
    NSLog(@"done");
    buttonSound.currentTime = 0;
    buttonSound.channelIsPlaying = YES;
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"email"
                                                     message:@"Please enter your email address (optional):"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Submit", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = ALERT_TAG_DONE;
    
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeEmailAddress;
    alertTextField.autocorrectionType = UITextAutocapitalizationTypeNone;
    alertTextField.placeholder = @"you@email.com";
    [alert show];
    
    recordButton.selected = NO;
}

- (void)submitJourney:(NSString*)email
{
    //NSNumber* client_id = [NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey:@"client_id"]];
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
    
    
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/submit/journey", [[NSUserDefaults standardUserDefaults] stringForKey:@"server"]]];
    // __block   ... removed??
    __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
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
    [request startAsynchronous];
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
    
    if(alertView.tag==ALERT_TAG_DONE)
    {
        if(buttonIndex==0)
        {
            
        }
        else if(buttonIndex==1)
        {
             NSLog(@"Entered: %@", [[alertView textFieldAtIndex:0] text]);
            
            [soundSwitch setOn:NO animated:YES];
            [audioController setMuted:YES forChannelGroup:brainSoundGroup];
            [self submitJourney:[[alertView textFieldAtIndex:0] text]];
        }
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
            if([events count] > MAX_READINGS) {
                [events removeObjectAtIndex:0];
            }

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
    poorSignalValue = 500;
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
            if([events count] > MAX_READINGS) {
                [events removeObjectAtIndex:0];
            }
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
            tickSound.volume = 0.1;
            tickSound.currentTime = 0;
            tickSound.channelIsPlaying = YES;
            NSDictionary* reading = @{@"date":[self isoDate], @"data": @{@"attention": [NSNumber numberWithInt:attention],
                                                                         @"meditation": [NSNumber numberWithInt:meditation]}};
            [readings addObject:reading];
            if([readings count]>MAX_READINGS) {
                [readings removeObjectAtIndex:0];
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
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case SECTION_RECORDING: return @"Recording";
        case SECTION_CONTROLS: return @"Controls";
        case SECTION_STATUS: return @"Status";
        case SECTION_THINKGEAR: return @"Brain Activity";
        //case SECTION_DEBUG: return @"Debug";
        //case SECTION_MOTION: return @"Motion";
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
        case SECTION_STATUS: return 4;
        case SECTION_THINKGEAR: return 11;
        //case SECTION_DEBUG: return 5;
        //case SECTION_MOTION: return 5;
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
                case 3:
                    [[cell textLabel] setText:@"Connectivity"];
                    [[cell detailTextLabel] setText:connectivityStatus];
                    break;
                /*
                case 4:
                    [[cell textLabel] setText:@"Server"];
                    [[cell detailTextLabel] setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"server"]];
                    
                    break;
                */
            }
            break;
        /*
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
         */
            
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
        /*
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
        */
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
