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
#import "BrainView.h"
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface ViewController : UIViewController <TGAccessoryDelegate, SRWebSocketDelegate> {
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


- (IBAction)startJourney:(id)sender;
- (IBAction)stopJourney:(id)sender;
- (IBAction)submitJourney:(id)sender;

@property (nonatomic, retain) IBOutlet UILabel *labelTGAccessoryStatus;
@property (nonatomic, retain) IBOutlet UILabel *labelWebsocketStatus;
@property (nonatomic, retain) IBOutlet BrainView *brainView;
@end
