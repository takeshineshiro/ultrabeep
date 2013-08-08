//
//  UBAmplitudeBuffer.h
//  UltraBeep
//
//  Created by Diego von Beck on 7/31/13.
//  Copyright (c) 2013 Diego von Beck. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UBAmplitudeBufferDelegate <NSObject>

@required

- (void)receiveAmplitudeResult: (BOOL)result fromValue: (SInt32)value;

@end

@interface UBAmplitudeBuffer : NSObject
{
    NSMutableArray* buffer;
    uint lastSize;
    id del;
    uint spectrum;
    uint targetFreq;
    NSDate* date;
}

//Receives delegate, frequency to look for and sample rate;
- (id)initWithDelegate: (id <UBAmplitudeBufferDelegate>)delegate frequency: (uint)freq andSampleRate: (uint)sampleRate;
- (void)saveData: (SInt32*)amplitude withSize: (uint)size;



@end
