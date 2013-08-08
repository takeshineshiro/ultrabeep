//
//  UBAmplitudeBuffer.m
//  UltraBeep
//
//  Created by Diego von Beck on 7/31/13.
//  Copyright (c) 2013 Diego von Beck. All rights reserved.
//

#import "UBAmplitudeBuffer.h"




@implementation UBAmplitudeBuffer

- (id)initWithDelegate:(id<UBAmplitudeBufferDelegate>)delegate frequency:(uint)freq andSampleRate:(uint)sampleRate {
    self = [super init];
    
    del = delegate;
    spectrum = sampleRate/2;
    targetFreq = freq;
    lastSize = 0;
    buffer = [[NSMutableArray alloc] init];
    date = [NSDate date];
    
    return self;
}

- (void)saveData:(SInt32 *)amplitude withSize:(uint)size {
    if (lastSize == 0) lastSize = size;
    if (lastSize != size) [NSException raise:@"ampBuffer size and lastSize differed, size changed?" format:@"lastSize: %i size: %i", lastSize, size];
    
    NSMutableArray* currData = [[NSMutableArray alloc] init];
    for (uint i = 0; i < size; i++)
        [currData addObject:[NSNumber numberWithInt:amplitude[i]]];
    
    [buffer addObject:currData];
    
    if ([self readyToSend]) {
        [self giveResponse];
    }
    
}

- (BOOL)readyToSend {
    return (-[date timeIntervalSinceNow] > 0.125);
}

- (void) giveResponse {
    int value = 0;
    for (uint i = 0; i < [buffer count]; i++) {
        value += [buffer[i][lastSize*targetFreq/spectrum] intValue] / [buffer count];
    }
    NSLog(@"%i",[buffer count]);
    [buffer removeAllObjects];
    [del receiveAmplitudeResult:(value > -1100000000) fromValue:value];
    date = [NSDate date];
}
@end