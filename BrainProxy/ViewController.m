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
@synthesize successSound, errorSound, blinkSound, shakeSound, reverb;
@synthesize recorder;


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
    
    
    
    //
    //  headerView
    //
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
    
    
    //
    //  Other controls
    //
    soundSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [soundSwitch setOn:NO animated:NO];
    [soundSwitch addTarget:self action:@selector(toggleSound:) forControlEvents:UIControlEventValueChanged];
    
    
    //
    // motionManager
    //
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

    //
    // Create an instance of the audio controller, set it up and start it running
    //
    self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription] inputEnabled:NO];
    self.audioController.preferredBufferDuration = 0.005;
    
    
    self.successSound = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"Success"
                                                                                          withExtension:@"wav"]
                                             audioController:self.audioController
                                                       error:NULL];
    self.successSound.volume = 0.5;
    self.successSound.channelIsPlaying = NO;
    [self.audioController addChannels:[NSArray arrayWithObject:self.successSound]];
    
    self.blinkSound = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"Blink"
                                                                                        withExtension:@"wav"]
                                                  audioController:self.audioController
                                                            error:NULL];
    self.blinkSound.volume = 0.5;
    self.blinkSound.channelIsPlaying = NO;
    [self.audioController addChannels:[NSArray arrayWithObject:self.blinkSound]];
    
    self.shakeSound = [AEAudioFilePlayer audioFilePlayerWithURL:[[NSBundle mainBundle] URLForResource:@"Static"
                                                                                        withExtension:@"aif"]
                                                audioController:self.audioController
                                                          error:NULL];
    self.shakeSound.channelIsPlaying = NO;
    [self.audioController addChannels:[NSArray arrayWithObject:self.shakeSound]];
    
    

    for(int i=0; i<N_ATTENTION_LOOPS; i++) {
        NSString* base = [NSString stringWithFormat:@"Att%02d", i+1];
        NSURL* url = [[NSBundle mainBundle] URLForResource:base withExtension:@"wav"];
        attentionFiles[i] = [AEAudioFilePlayer audioFilePlayerWithURL:url
                                                            audioController:self.audioController
                                                                      error:NULL];
        attentionFiles[i].loop = YES;
        attentionFiles[i].channelIsPlaying = NO;
    }
    
    
    for(int i=0; i<N_MEDITATION_LOOPS; i++) {
        NSString* base = [NSString stringWithFormat:@"Med%02d", i+1];
        NSURL* url = [[NSBundle mainBundle] URLForResource:base withExtension:@"wav"];
        meditationFiles[i] = [AEAudioFilePlayer audioFilePlayerWithURL:url
                                                      audioController:self.audioController
                                                                error:NULL];
        meditationFiles[i].loop = YES;
        meditationFiles[i].channelIsPlaying = NO;
    }
    
    brainSoundGroup = [audioController createChannelGroup];
    
    [audioController addChannels:[NSArray arrayWithObjects:attentionFiles count:N_ATTENTION_LOOPS] toChannelGroup:brainSoundGroup];
    [audioController addChannels:[NSArray arrayWithObjects:meditationFiles count:N_MEDITATION_LOOPS] toChannelGroup:brainSoundGroup];
    [audioController setMuted:YES forChannelGroup:brainSoundGroup];
    
    
    for(int i=0; i<3; i++) {
        NSString* base = [NSString stringWithFormat:@"ppk-tick-%02d", i+5];
        NSURL* url = [[NSBundle mainBundle] URLForResource:base withExtension:@"wav"];
        ticks[i] = [AEAudioFilePlayer audioFilePlayerWithURL:url
                                             audioController:self.audioController
                                                       error:NULL];
        ticks[i].volume = 0.1;
        ticks[i].channelIsPlaying = NO;

    }
    [self.audioController addChannels:[NSArray arrayWithObjects:ticks count:3]];
    [self.audioController start:NULL];
    
    
    
    
    //[self.audioController addChannels:[NSArray arrayWithObjects:attentionFiles count:N_ATTENTION_LOOPS]];
    //[self.audioController addChannels:[NSArray arrayWithObjects:meditationFiles count:N_MEDITATION_LOOPS]];
    
    
 
    AudioComponentDescription component  = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple,
                                                                           kAudioUnitType_Effect,
                                                                           kAudioUnitSubType_Reverb2);
    NSError *error = NULL;
    self.reverb = [[AEAudioUnitFilter alloc]
                   initWithComponentDescription:component
                   audioController:audioController
                   error:&error];
    
    
    [audioController addFilter:reverb toChannelGroup:brainSoundGroup];

    
    
    
    
    //
    // Init vars
    //
    poorSignalValue = 500;
    webSocketStatus = SOCKET_STATUS_CLOSED;
    readings = [NSMutableArray arrayWithObjects: nil];
    
    //
    // Initial kickoff
    //
    [self wsConnect];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target: self selector: @selector(update:) userInfo: nil repeats: YES];
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
- (void) update:(NSTimer*)t
{
    if(recordButton.selected) {
        interval += [t timeInterval];
    }
    
    attentionEased += (attention-attentionEased) / 10.0;
    meditationEased += (meditation-meditationEased) / 10.0;
    attentionTeir = ofMap(attentionEased, 0, 100, 0, N_ATTENTION_LOOPS, true);
    meditationTeir = ofMap(meditationEased, 0, 100, 0, N_MEDITATION_LOOPS, true);
    
    for(int i=0; i<N_ATTENTION_LOOPS; i++) {
        float dist = fabs(attentionTeir - i);
        float volume = ofMap(dist, 0, 1.0, 0.25, 0, true);
        attentionFiles[i].volume = volume;
        attentionFiles[i].channelIsPlaying = (volume>0);
    }
    
    for(int i=0; i<N_MEDITATION_LOOPS; i++) {
        float dist = fabs(meditationTeir - i);
        float volume = ofMap(dist, 0, 1.0, 0.25, 0, true);
        meditationFiles[i].volume = volume;
        meditationFiles[i].channelIsPlaying = (volume>0);
    }
    
    submitButton.alpha = resetButton.alpha = [readings count] > 40 ? 1 : 0.4;
    submitButton.enabled = resetButton.enabled = [readings count] > 40;
    
    float avg = (fabs(userAcceleration.x) + fabs(userAcceleration.y) + fabs(userAcceleration.z)) / 3.0;
    float mix = ofMap(avg, 0, 3, 0, 100, true);
    AudioUnitSetParameter(reverb.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, mix, 0);

    float decay = ofMap(fabs(180/M_PI)*attitude.pitch, 0, 90, 0.001, 20, true);
    AudioUnitSetParameter(reverb.audioUnit, kReverb2Param_DecayTimeAt0Hz, kAudioUnitScope_Global, 0, decay, 0);
    
    [self reloadSection:SECTION_STATUS];
}

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

- (void)processReading:(NSDictionary *)data
{
    if(recordButton.selected)
    {
        NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
        NSDictionary* message = @{@"data": data, @"timestamp":timestamp};
        [readings addObject:message];
    }
}

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
        ticks[0].volume = 0.25;
        ticks[1].channelIsPlaying = YES;
    }
}


- (void)submitJourney:(id)sender
{
    NSLog(@"submitJourney");
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Hello!" message:@"Please enter your email address:" delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 100;
    
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
    [readings removeAllObjects];
    interval = 0;
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


#pragma mark -AlertView delagate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(alertView.tag==100)
    {
        NSLog(@"Entered: %@", [[alertView textFieldAtIndex:0] text]);
        NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
        NSNumber* client_id = [NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey:@"client_id"]];
        NSString* email = [[alertView textFieldAtIndex:0] text];
        NSDictionary* data = @{@"client_id": client_id, @"route": @"submit", @"timestamp": timestamp, @"email": email, @"readings": readings};
        
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        if(webSocket != nil)
            [webSocket send: jsonString];
    }
}

#pragma mark - Motion 

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        self.shakeSound.channelIsPlaying = YES;
        // User was shaking the device.
        NSLog(@"Shake motionBegan");
        NSDictionary* reading = @{@"shake":
                                      @{@"x": [NSNumber numberWithDouble: userAcceleration.x],
                                        @"y": [NSNumber numberWithDouble: userAcceleration.y],
                                        @"z": [NSNumber numberWithDouble: userAcceleration.z]}};
        
        [self processReading:reading];
        NSLog(@"Shake motionBegan");
    }
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        // User was shaking the device.
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
        //NSLog(@"blinkStrength = %d", blinkStrength);
        //self.blinkSound.currentTime = 0;
        //self.blinkSound.channelIsPlaying = YES;
    }

    if([data valueForKey:@"eSenseAttention"]){
        attention = [[data valueForKey:@"eSenseAttention"] intValue];
    }
    
    if([data valueForKey:@"eSenseMeditation"])
        meditation = [[data valueForKey:@"eSenseMeditation"] intValue];
    
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
    
    [self processReading: data];
    [self reloadSection: SECTION_THINKGEAR];
}


#pragma mark - SocketRocket

 

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




#pragma mark - Table view data source




- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch(section) {
        case SECTION_CONTROLS: return @"Controls";
        case SECTION_STATUS: return @"Status";
        case SECTION_THINKGEAR: return @"Brain Activity";
        case SECTION_MOTION: return @"Motion";
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
        case SECTION_CONTROLS: return 1;
        case SECTION_STATUS: return 8;
        case SECTION_THINKGEAR: return 11;
        case SECTION_MOTION: return 9;
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
            
        case SECTION_CONTROLS:
            cell.accessoryView = soundSwitch;
            cell.textLabel.text = @"Sound";
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
                    [[cell textLabel] setText:@"Websocket"];
                    switch(webSocketStatus) {
                        case SOCKET_STATUS_CLOSED:
                            [[cell detailTextLabel] setText:@"Closed"];
                            break;
                        case SOCKET_STATUS_CONNECTING:
                            [[cell detailTextLabel] setText:@"Connecting"];
                            break;
                        case SOCKET_STATUS_OPEN:
                            [[cell detailTextLabel] setText:@"Open"];
                            break;
                    }
                    break;
                
                case 2:
                    [[cell textLabel] setText:@"Record Time"];
                    
                    NSInteger ti = (NSInteger)interval;
                    NSInteger seconds = ti % 60;
                    NSInteger minutes = (ti / 60) % 60;
                    NSInteger hours = (ti / 3600);
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds]];
                    break;
                case 3:
                    [[cell textLabel] setText:@"Readings"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", [readings count]]];
                    break;
                case 4:
                    [[cell textLabel] setText:@"Meditation Eased"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", meditationEased]];
                    break;
                case 5:
                    [[cell textLabel] setText:@"Attention Eased"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", attentionEased]];
                    break;
                case 6:
                    [[cell textLabel] setText:@"Meditation Teir"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", meditationTeir]];
                    break;
                case 7:
                    [[cell textLabel] setText:@"Attention Teir"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", attentionTeir]];
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
                    [[cell textLabel] setText:@"X Rotation"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", rotationRate.x]];
                    break;
                case 4:
                    [[cell textLabel] setText:@"Y Rotation"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", rotationRate.y]];
                    break;
                case 5:
                    [[cell textLabel] setText:@"Z Rotation"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", rotationRate.z]];
                    break;
                case 6:
                    [[cell textLabel] setText:@"X Acceleration"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", userAcceleration.x]];
                    break;
                case 7:
                    [[cell textLabel] setText:@"Y Acceleration"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", userAcceleration.y]];
                    break;
                case 8:
                    [[cell textLabel] setText:@"Z Acceleration"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.2f", userAcceleration.z]];
                    break;
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
