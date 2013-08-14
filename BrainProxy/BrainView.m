//
//  BrainView.m
//  BrainProxy
//
//  Created by Jeffrey Crouse on 8/14/13.
//  Copyright (c) 2013 Jeffrey Crouse. All rights reserved.
//

#import "BrainView.h"

@implementation BrainView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = YES;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)onData:(NSDictionary*) data
{
    NSLog(@"BrainView onData");
    

    if([data valueForKey:@"blinkStrength"])
        blinkStrength = [[data valueForKey:@"blinkStrength"] intValue];
    
    if([data valueForKey:@"raw"]) {
        rawValue = [[data valueForKey:@"raw"] shortValue];
    }
    
    if([data valueForKey:@"heartRate"])
        heartRate = [[data valueForKey:@"heartRate"] intValue];
    
    if([data valueForKey:@"poorSignal"]) {
        poorSignalValue = [[data valueForKey:@"poorSignal"] intValue];
        //NSLog(@"buffered raw count: %d", buffRawCount);
        buffRawCount = 0;
    }
    
    if([data valueForKey:@"respiration"]) {
        respiration = [[data valueForKey:@"respiration"] floatValue];
    }
    
    if([data valueForKey:@"heartRateAverage"]) {
        heartRateAverage = [[data valueForKey:@"heartRateAverage"] intValue];
    }
    if([data valueForKey:@"heartRateAcceleration"]) {
        heartRateAcceleration = [[data valueForKey:@"heartRateAcceleration"] intValue];
    }
    
    if([data valueForKey:@"rawCount"]) {
        rawCount = [[data valueForKey:@"rawCount"] intValue];
    }
    
    
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

    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //NSLog(@"attention = %d", eSenseValues.attention);
    //NSLog(@"meditation = %d", eSenseValues.meditation);
    
    float width = (eSenseValues.attention/100.0) * self.bounds.size.width;
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, width, 20));
    
    width = (eSenseValues.meditation/100.0) * self.bounds.size.width;
    
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0].CGColor);
    CGContextFillRect(context, CGRectMake(0, 20, width, 20));

    
}


@end
