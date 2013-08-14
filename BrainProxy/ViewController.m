//
//  ViewController.m
//  BrainProxy
//
//  Created by Jeffrey Crouse on 8/14/13.
//  Copyright (c) 2013 Jeffrey Crouse. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController {
    SRWebSocket *_webSocket;
}

@synthesize labelTGAccessoryStatus;
@synthesize labelWebsocketStatus;
@synthesize brainView;
@synthesize submitButton, resetButton;
@synthesize uiSwitch;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _webSocket = nil;
    [self wsConnect];
    [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self
                                   selector: @selector(update:)
                                   userInfo: nil repeats: YES];
    
    [self disableControls];
}

- (void)enableControls
{
    submitButton.alpha = 1;
    submitButton.enabled = YES;
    
    resetButton.alpha = 1;
    resetButton.enabled = YES;
    
    uiSwitch.alpha = 1;
    resetButton.enabled = YES;
}

- (void)disableControls
{
    submitButton.alpha = 0.4;
    submitButton.enabled = NO;
    
    resetButton.alpha = 0.4;
    resetButton.enabled = NO;
    
    uiSwitch.alpha = 0.4;
    resetButton.enabled = NO;
    
    [uiSwitch setOn:NO];
}

- (void)wsConnect
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    [labelWebsocketStatus setText:[NSString stringWithFormat:@"Connecting to %@", [userDefaults stringForKey:@"host"]]];
    
    NSLog( @"host = %@", [userDefaults stringForKey:@"host"] );
    
    NSURL* url = [NSURL URLWithString:[userDefaults stringForKey:@"host"]];
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:url]];
    _webSocket.delegate = self;
    [_webSocket open];
}

- (void) update:(NSTimer*)t
{
    //NSLog(@"update");
    if([[TGAccessoryManager sharedTGAccessoryManager] accessory] == nil){
         [labelTGAccessoryStatus setText:@"No device connected"];
    } else {
        [labelTGAccessoryStatus setText:@"Connected!"];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Button actions
 /*
- (IBAction)startJourney:(id)sender
{
    NSLog(@"startJourney");
    bSending = true;
    
   
    NSNumber* color = [NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey:@"color"]];
    NSDictionary* data = @{@"color": color, @"route": @"start"};

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    if(_webSocket != nil) {
        [_webSocket send: jsonString];
        bSending = true;
    }
     
}

- (IBAction)stopJourney:(id)sender
{
    NSLog(@"stopJourney");
    
    
    NSNumber* color = [NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey:@"color"]];
    NSDictionary* data = @{@"color": color, @"route": @"stop"};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    if(_webSocket != nil) {
        [_webSocket send: jsonString];
        bSending = false;
    }
}
*/

- (IBAction)submitJourney:(id)sender
{
    NSLog(@"submitJourney");
    
    NSNumber* color = [NSNumber numberWithInt:[[NSUserDefaults standardUserDefaults] integerForKey:@"color"]];
    NSDictionary* data = @{@"color": color, @"route": @"submit"};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    if(_webSocket != nil) {
        [_webSocket send: jsonString];
    }
}

- (IBAction)resetJourney:(id)sender
{
    NSLog(@"resetJourney");
}

#pragma mark - SocketRocket



- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [labelWebsocketStatus setText:[NSString stringWithFormat:@"Connected to %@", [userDefaults stringForKey:@"host"]]];
    [self enableControls];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    [labelWebsocketStatus setText:[error localizedDescription]];
     _webSocket = nil;
    [self disableControls];
    [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self
                                   selector: @selector(wsConnect) userInfo: nil repeats: NO];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    NSLog(@"Received \"%@\"", message);
    /*
     [_messages addObject:[[TCMessage alloc] initWithMessage:message fromMe:NO]];
     [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_messages.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
     [self.tableView scrollRectToVisible:self.tableView.tableFooterView.frame animated:YES];
     */
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    [labelWebsocketStatus setText:@"Connection Closed!"];
     _webSocket = nil;
    [self disableControls];
    
    [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self
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
    //NSLog(@"dataReceived");
    [brainView onData:data];
    
    if([uiSwitch isOn]) {
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSNumber* color = [NSNumber numberWithInt:[userDefaults integerForKey:@"color"]];
        NSDictionary* message = @{@"color": color, @"route": @"data", @"data": data};
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
        if (!jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSLog(@"%@", jsonString);
            if(_webSocket != nil) {
                [_webSocket send: jsonString];
            }
        }
    }
}


@end
