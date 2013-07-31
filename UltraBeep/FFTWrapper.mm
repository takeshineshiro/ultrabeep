//
//  FFTWrapper.mm
//  UltraBeep
//
//  Created by Diego von Beck on 7/6/13.
//  Copyright (c) 2013 Diego von Beck. All rights reserved.
//

#import "FFTWrapper.h"
#import "FFTBufferManager.h"

struct Wrapper {
    FFTBufferManager* cppobject;
};

@implementation FFTWrapper
class CAStreamBasicDescription;

- (id)init
{
    NSAssert(false, @"You cannot init FFTWrrapper class directly. Use initWithNumberOfFrames:");
    self = nil;
    return nil;
}

-(id)initWithNumberOfFrames:(UInt32)inNumberFrames {
    self = [super init];
    wrapper = new Wrapper;
    wrapper->cppobject = new FFTBufferManager(inNumberFrames);
    l_fftData = new int32_t[inNumberFrames/2];
    return self;
};

-(int32_t)HasNewAudioData {
    return wrapper->cppobject->HasNewAudioData();
}

-(int32_t)NeedsNewAudioData {
    return wrapper->cppobject->NeedsNewAudioData();
}

-(UInt32)GetNumberFrames {
    return wrapper->cppobject->GetNumberFrames();
}

-(void)GrabAudioData:(AudioBufferList *)inBL {
    wrapper->cppobject->GrabAudioData(inBL);
}

-(Boolean)ComputeFFT:(int32_t *)outFFTData {
    return wrapper->cppobject->ComputeFFT(outFFTData);
}

-(int32_t*) l_fftData {
    return l_fftData;
}

-(void)dealloc {
    delete wrapper->cppobject;
    delete wrapper;
    delete l_fftData;
}

+(void)setFormatToUnit:(AudioUnit *)audioUnit {
    FFTBufferManager::setFormatToUnit(audioUnit);
}

+(void)intArrayNewWithPointer:(int32_t **)pointer andSize:(int32_t)size {
    FFTBufferManager::intArrayNew(pointer, size);
}

//Declared but undefined?
/*
-(void)ClearBuffer:(void *)buffer With:(UInt32)numBytes {
    wrapper->cppobject->ClearBuffer(buffer, numBytes);
}
*/

@end
