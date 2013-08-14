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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    _webSocket = nil;
    //[self wsConnect];
    [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self
                                   selector: @selector(update:)
                                   userInfo: nil repeats: YES];
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

- (IBAction)startJourney:(id)sender
{
    NSLog(@"startJourney");
}

- (IBAction)stopJourney:(id)sender
{
    NSLog(@"stopJourney");
}

- (IBAction)submitJourney:(id)sender
{
    NSLog(@"submitJourney");
}

#pragma mark - SocketRocket



- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
    [labelWebsocketStatus setText:@"Websocket Status: Connected"];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    [labelWebsocketStatus setText:[error localizedDescription]];
     _webSocket = nil;
    
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
    
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data
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


@end
