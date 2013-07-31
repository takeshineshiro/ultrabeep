//
//  FFTWrapper.h
//  UltraBeep
//
//  Created by Diego von Beck on 7/6/13.
//  Copyright (c) 2013 Diego von Beck. All rights reserved.
//
//  Objective-C wrapper for Apple's C++ class FFTBufferManager.

#import <AudioToolbox/AudioToolbox.h>
#import <libkern/OSAtomic.h>
#import <Accelerate/Accelerate.h>
#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>

struct Wrapper;

@interface FFTWrapper : NSObject
{
    struct Wrapper* wrapper;
    int32_t* l_fftData;
}

-(id) initWithNumberOfFrames: (UInt32) inNumberFrames;

-(int32_t) HasNewAudioData;
-(int32_t) NeedsNewAudioData;

-(UInt32) GetNumberFrames;

-(void) GrabAudioData: (AudioBufferList*) inBL;
-(Boolean) ComputeFFT: (int32_t *) outFFTData;

//Returns pointer to dynamically allocated c++ array for storing FFTResult
-(int32_t*) l_fftData;

+(void) setFormatToUnit: (AudioUnit*) audioUnit;
+(void) intArrayNewWithPointer: (int32_t**)pointer andSize: (int32_t)size;
//Declared but undefined?
//-(void) ClearBuffer: (void*) buffer With: (UInt32) numBytes;

@end
