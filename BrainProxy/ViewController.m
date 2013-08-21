//
//  ViewController.m
//  BrainProxy
//
//  Created by Jeffrey Crouse on 8/14/13.
//  Copyright (c) 2013 Jeffrey Crouse. All rights reserved.
//

#import "ViewController.h"


@interface ViewController () {
    
}

@end

@implementation ViewController 
@synthesize labelReadings, labelTime, labelWebsocketStatus;
@synthesize recordButton, submitButton, resetButton;
@synthesize uiSwitch, tableView;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Set up sounds
    AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"success" ofType:@"wav"]]), &successSound);
    AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"error" ofType:@"wav"]]), &errorSound);
    poorSignalValue = 500;
    
    bRecording = NO;
    readings = [NSMutableArray arrayWithObjects: nil];
    
    submitButton.alpha = 0.4;
    submitButton.enabled = NO;
    resetButton.alpha = 0.4;
    resetButton.enabled = NO;
    
    
    _webSocket = nil;
    [self disableControls];
    [self wsConnect];

    
    // Set up motion stuff...
    float motionInterval = 0.1;
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = motionInterval;
    self.motionManager.gyroUpdateInterval = motionInterval;
    self.motionManager.deviceMotionUpdateInterval = motionInterval;
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 acc = accelerometerData.acceleration;
                                             }];
    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                            withHandler:^(CMGyroData *gyroData, NSError *error) {
                                                rot = gyroData.rotationRate;
                                            }];
    
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                            withHandler:^(CMDeviceMotion *motion, NSError *error){
                                                attitude = [motion attitude];
                                                rotationRate = [motion rotationRate];
                                                userAcceleration = [motion userAcceleration];
                                            }];
   
    [self becomeFirstResponder];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target: self selector: @selector(update:) userInfo: nil repeats: YES];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target: self selector: @selector(sampleMotionData:) userInfo: nil repeats: YES];
    
    self.audioController = [[AEAudioController alloc]
                            initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription]
                            inputEnabled:NO]; // don't forget to autorelease if you don't use ARC!
    NSError *error = NULL;
    BOOL result = [_audioController start:&error];
    if ( !result ) {
        NSLog(@"Error starting audioContoller: %@", [error localizedDescription]);
    }
    
    NSURL *file = [[NSBundle mainBundle] URLForResource:@"AmbientLoop" withExtension:@"wav"];
    self.ambientLoop = [AEAudioFilePlayer audioFilePlayerWithURL:file
                                          audioController:_audioController
                                                    error:NULL];
    self.ambientLoop.loop = YES;
    
    [_audioController addChannels:[NSArray arrayWithObjects:self.ambientLoop, nil]];
}



- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (void) update:(NSTimer*)t {
    if(bRecording) {
        interval += [t timeInterval];
    }
    
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    NSString* time = [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds];
    
    [labelReadings setText:[NSString stringWithFormat:@"%d", [readings count]]];
    [labelTime setText:time];
    
    
    if([readings count] > 40) {
        submitButton.alpha = 1;
        submitButton.enabled = YES;
        
        resetButton.alpha = 1;
        resetButton.enabled = YES;
    } else {
        submitButton.alpha = 0.4;
        submitButton.enabled = NO;
        
        resetButton.alpha = 0.4;
        resetButton.enabled = NO;
    }
}



- (void)enableControls
{    
    recordButton.alpha = 1;
    recordButton.enabled = YES;
    
    uiSwitch.alpha = 1;
}

- (void)disableControls
{    
    recordButton.alpha = 0.4;
    recordButton.enabled = NO;
    
    uiSwitch.alpha = 0.4;
    resetButton.enabled = NO;
    
    [uiSwitch setOn:NO];
}


- (void)wsConnect
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    [labelWebsocketStatus setText:@"Connecting..."];
    
    NSLog( @"host = %@", [userDefaults stringForKey:@"host"] );
    
    NSURL* url = [NSURL URLWithString:[userDefaults stringForKey:@"host"]];
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:url]];
    _webSocket.delegate = self;
    [_webSocket open];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)processReading:(NSDictionary *)data
{
    if([uiSwitch isOn]) // streaming
    {
        NSNumber* client_id = [NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey:@"client_id"]];
        NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
        
        NSDictionary* message = @{@"client_id": client_id, @"route": @"reading", @"reading": data, @"timestamp":timestamp};
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        if (!jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            //NSLog(@"%@", jsonString);
            NSLog(@"sending reading...");
            if(_webSocket != nil) {
                [_webSocket send: jsonString];
            }
        }
    }
    
    if(bRecording)
    {
        NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
        NSDictionary* message = @{@"data": data, @"timestamp":timestamp};
        [readings addObject:message];
    }
}



#pragma mark - Motion handlers

- (void) sampleMotionData:(NSTimer*)t
{
    if([uiSwitch isOn])
    {
        NSDictionary* data = @{@"attitude": @{@"yaw": [NSNumber numberWithDouble: attitude.yaw],
                                              @"pitch": [NSNumber numberWithDouble: attitude.pitch],
                                              @"roll": [NSNumber numberWithDouble: attitude.roll] },
                               @"acceleration": @{@"x": [NSNumber numberWithDouble: userAcceleration.x],
                                                   @"y": [NSNumber numberWithDouble: userAcceleration.y],
                                                   @"z": [NSNumber numberWithDouble: userAcceleration.z]}
                               };
        
        NSNumber* client_id = [NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey:@"client_id"]];
        NSString *timestamp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
        NSDictionary* message = @{@"client_id": client_id, @"route": @"reading", @"reading": data, @"timestamp":timestamp};
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        if (!jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            if(_webSocket != nil)
                [_webSocket send: jsonString];
        }
    }
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
        // User was shaking the device.
        NSLog(@"Shake motionBegan");
        NSDictionary* reading = @{@"shake":
                                        @{@"x": [NSNumber numberWithDouble: userAcceleration.x],
                                          @"y": [NSNumber numberWithDouble: userAcceleration.y],
                                          @"z": [NSNumber numberWithDouble: userAcceleration.z]}};
        [self processReading:reading];
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





#pragma mark - Button actions


- (IBAction)submitJourney:(id)sender
{
    NSLog(@"submitJourney");

    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Hello!" message:@"Please enter your email address:" delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 100;
    
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeEmailAddress; 
    alertTextField.placeholder = @"you@email.com";
    [alert show];
    
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
    bRecording = NO;
    //[uiSwitch setOn:NO animated:YES];
}

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
        
        if(_webSocket != nil)
            [_webSocket send: jsonString];
    }
}

- (IBAction)resetJourney:(id)sender
{
    NSLog(@"resetJourney");    
    [recordButton setTitle:@"Record" forState:UIControlStateNormal];
    bRecording = NO;
    [readings removeAllObjects];
    interval = 0;
}

-(IBAction)toggleRecord:(id)sender
{
    if(bRecording) {
        [recordButton setTitle:@"Record" forState:UIControlStateNormal];
        bRecording = NO;
    } else {
       [recordButton setTitle:@"Stop" forState:UIControlStateNormal];
        bRecording = YES;
    }
}

- (IBAction)identify:(id)sender
{
    NSNumber* client_id = [NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey:@"client_id"]];
    NSDictionary* data = @{@"client_id": client_id, @"route": @"identify"};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    if(_webSocket != nil)
        [_webSocket send: jsonString];
}


#pragma mark - SocketRocket

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSLog(@"%@", [NSString stringWithFormat:@"Connected to %@", [userDefaults stringForKey:@"host"]]);
    [labelWebsocketStatus setText:@"Open"];
    [self enableControls];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    [labelWebsocketStatus setText:@"Error"];
     _webSocket = nil;
    [self disableControls];
    [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self
                                   selector: @selector(wsConnect) userInfo: nil repeats: NO];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
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
                AudioServicesPlaySystemSound (successSound);
                
                [readings removeAllObjects];
                interval = 0;
                
            } else {
                NSLog(@"Error saving!");
                AudioServicesPlaySystemSound (errorSound);
                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[dict valueForKey:@"status"]  delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                alert.tag = 101;
                [alert show];

            }
        } else {
            NSLog(@"UNKNOWN ROUTE!");
        }
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    [labelWebsocketStatus setText:@"Closed"];
     _webSocket = nil;
    [self disableControls];
    
    [NSTimer scheduledTimerWithTimeInterval: 3.0 target: self
                                   selector: @selector(wsConnect) userInfo: nil repeats: NO];
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

    if([data valueForKey:@"blinkStrength"])
        blinkStrength = [[data valueForKey:@"blinkStrength"] intValue];
    
    if([data valueForKey:@"raw"])
        rawValue = [[data valueForKey:@"raw"] shortValue];
    
    if([data valueForKey:@"heartRate"])
        heartRate = [[data valueForKey:@"heartRate"] intValue];
    
    if([data valueForKey:@"poorSignal"]) {
        poorSignalValue = [[data valueForKey:@"poorSignal"] intValue];
        //NSLog(@"buffered raw count: %d", buffRawCount);
        buffRawCount = 0;
    }
    
    if([data valueForKey:@"respiration"])
        respiration = [[data valueForKey:@"respiration"] floatValue];
    
    if([data valueForKey:@"heartRateAverage"])
        heartRateAverage = [[data valueForKey:@"heartRateAverage"] intValue];
    
    if([data valueForKey:@"heartRateAcceleration"])
        heartRateAcceleration = [[data valueForKey:@"heartRateAcceleration"] intValue];
    
    if([data valueForKey:@"rawCount"])
        rawCount = [[data valueForKey:@"rawCount"] intValue];
    
    
    // check to see whether the eSense values are there. if so, we assume that
    // all of the other data (aside from raw) is there. this is not necessarily
    // a safe assumption.
    if([data valueForKey:@"eSenseAttention"]){
        
        eSenseValues.attention =    [[data valueForKey:@"eSenseAttention"] intValue];
        eSenseValues.meditation =   [[data valueForKey:@"eSenseMeditation"] intValue];
        
        eegValues.delta =       [[data valueForKey:@"eegDelta"] intValue];
        eegValues.theta =       [[data valueForKey:@"eegTheta"] intValue];
        eegValues.lowAlpha =    [[data valueForKey:@"eegLowAlpha"] intValue];
        eegValues.highAlpha =   [[data valueForKey:@"eegHighAlpha"] intValue];
        eegValues.lowBeta =     [[data valueForKey:@"eegLowBeta"] intValue];
        eegValues.highBeta =    [[data valueForKey:@"eegHighBeta"] intValue];
        eegValues.lowGamma =    [[data valueForKey:@"eegLowGamma"] intValue];
        eegValues.highGamma =   [[data valueForKey:@"eegHighGamma"] intValue];
    }
    
    //[[self tableView] performSelector:@selector(reloadData) withObject:nil afterDelay:1.0];
    [tableView reloadData];
    
    [self processReading: data];
}


#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section){
        case 0:
            return @"Status";
        case 1:
            return @"eSense";
        case 2:
            return @"EEG bands";
        default:
            return nil;
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section){
        case 0: return 1;
        case 1: return 3;
        case 2: return 8;
        default: return 0;
    }
}

- (UIImage *)updateSignalStatus {
    
    if(poorSignalValue == 0) {
        return [UIImage imageNamed:@"Signal_Connected"];
    }
    else if(poorSignalValue > 0 && poorSignalValue < 50) {
        return [UIImage imageNamed:@"Signal_Connecting3"];
    }
    else if(poorSignalValue > 50 && poorSignalValue < 200) {
        return [UIImage imageNamed:@"Signal_Connecting2"];
    }
    else if(poorSignalValue == 200) {
        return [UIImage imageNamed:@"Signal_Connecting1"];
    }
    else {
        return [UIImage imageNamed:@"Signal_Disconnected"];
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * CellIdentifier = @"Cell";
    
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        // cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    NSInteger section = [indexPath indexAtPosition:0];
    NSInteger field = [indexPath indexAtPosition:1];
    
    
    // Clear out leftover crud from dequeueReusableCellWithIdentifier
    cell.imageView.image = nil;
    cell.accessoryView = nil;
    [[cell detailTextLabel] setText: nil];
    
    
	// Configure the cell.
    switch(section){
        case 0:
            switch(field){
                case 0:
                    [[cell textLabel] setText:@"Signal Strength"];
                    //[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", poorSignalValue]];
                    //[[cell imageView] setImage:[self updateSignalStatus]];
                    //cell.accessoryView = [self updateSignalStatus];
                    cell.accessoryView = [[UIImageView alloc] initWithImage:[self updateSignalStatus]];
                    break;
                default:
                    break;
            }
            
            break;
        case 1:
            switch(field){
                case 0:
                    [[cell textLabel] setText:@"Attention"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", eSenseValues.attention]];
                    break;
                case 1:
                    [[cell textLabel] setText:@"Meditation"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", eSenseValues.meditation]];
                    break;
                case 2:
                    [[cell textLabel] setText:@"Blink strength"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", blinkStrength]];
                    break;
                /*
                case 3:
                    [[cell textLabel] setText:@"Heart rate"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", heartRate]];
                    break;
                case 4:
                    [[cell textLabel] setText:@"Respiration"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%f", respiration]];
                    break;
                case 5:
                    [[cell textLabel] setText:@"Heart Rate Average"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", heartRateAverage]];
                    break;
                case 6:
                    [[cell textLabel] setText:@"Heart Rate Acceleration"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", heartRateAcceleration]];
                    break;
                */
                default:
                    break;
            }
            
            break;
        case 2:
            switch(field){
                case 0:
                    [[cell textLabel] setText:@"Delta"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", eegValues.delta]];
                    break;
                case 1:
                    [[cell textLabel] setText:@"Theta"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", eegValues.theta]];
                    break;
                case 2:
                    [[cell textLabel] setText:@"Low alpha"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", eegValues.lowAlpha]];
                    break;
                case 3:
                    [[cell textLabel] setText:@"High alpha"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", eegValues.highAlpha]];
                    break;
                case 4:
                    [[cell textLabel] setText:@"Low beta"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", eegValues.lowBeta]];
                    break;
                case 5:
                    [[cell textLabel] setText:@"High beta"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", eegValues.highBeta]];
                    break;
                case 6:
                    [[cell textLabel] setText:@"Low gamma"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", eegValues.lowGamma]];
                    break;
                case 7:
                    [[cell textLabel] setText:@"High gamma"];
                    [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%d", eegValues.highGamma]];
                    break;
                default:
                    break;
            }
            
            break;
        default:
            break;
    }
    return cell;
}
@end
