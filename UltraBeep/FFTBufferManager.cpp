/*
 
     File: FFTBufferManager.cpp
 Abstract: This class manages buffering and computation for FFT analysis on input audio data. The methods provided are used to grab the audio, buffer it, and perform the FFT when sufficient data is available
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 
 */

#include "FFTBufferManager.h"
#include <algorithm>
#include "CAStreamBasicDescription.h"

#define min(x,y) (x < y) ? x : y

//------CODE FROM CA LIBRARY

inline UInt32 CountLeadingZeroes(UInt32 arg)
{
    // GNUC / LLVM has a builtin
#if defined(__GNUC__)
    // on llvm and clang the result is defined for 0
#if (TARGET_CPU_X86 || TARGET_CPU_X86_64) && !defined(__llvm__)
	if (arg == 0) return 32;
#endif	// TARGET_CPU_X86 || TARGET_CPU_X86_64
	return __builtin_clz(arg);
#elif TARGET_OS_WIN32
	UInt32 tmp;
	__asm{
		bsr eax, arg
		mov ecx, 63
		cmovz eax, ecx
		xor eax, 31
		mov tmp, eax	// this moves the result in tmp to return.
    }
	return tmp;
#else
#error "Unsupported architecture"
#endif	// defined(__GNUC__)
}

inline UInt32 Log2Ceil(UInt32 x)
{
	return 32 - CountLeadingZeroes(x - 1);
}

//------END OF CODE FROM CA LIBRARY


FFTBufferManager::FFTBufferManager(UInt32 inNumberFrames) :
mNeedsAudioData(0),
mHasAudioData(0),
mFFTNormFactor(1.0/(2*inNumberFrames)),
mAdjust0DB(1.5849e-13),
m24BitFracScale(16777216.0f),
mFFTLength(inNumberFrames/2),
mLog2N(Log2Ceil(inNumberFrames)),
mNumberFrames(inNumberFrames),
mAudioBufferSize(inNumberFrames * sizeof(Float32)),
mAudioBufferCurrentIndex(0)

{
    mAudioBuffer = (Float32*) calloc(mNumberFrames,sizeof(Float32));
    mDspSplitComplex.realp = (Float32*) calloc(mFFTLength,sizeof(Float32));
    mDspSplitComplex.imagp = (Float32*) calloc(mFFTLength, sizeof(Float32));
    mSpectrumAnalysis = vDSP_create_fftsetup(mLog2N, kFFTRadix2);
	OSAtomicIncrement32Barrier(&mNeedsAudioData);
}

FFTBufferManager::~FFTBufferManager()
{
    vDSP_destroy_fftsetup(mSpectrumAnalysis);
    free(mAudioBuffer);
    free (mDspSplitComplex.realp);
    free (mDspSplitComplex.imagp);
}

void FFTBufferManager::GrabAudioData(AudioBufferList *inBL)
{
	if (mAudioBufferSize < inBL->mBuffers[0].mDataByteSize)	return;
	
	UInt32 bytesToCopy = min(inBL->mBuffers[0].mDataByteSize, mAudioBufferSize - mAudioBufferCurrentIndex);
	memcpy(mAudioBuffer+mAudioBufferCurrentIndex, inBL->mBuffers[0].mData, bytesToCopy);
	
	mAudioBufferCurrentIndex += bytesToCopy / sizeof(Float32);
	if (mAudioBufferCurrentIndex >= mAudioBufferSize / sizeof(Float32))
	{
		OSAtomicIncrement32Barrier(&mHasAudioData);
		OSAtomicDecrement32Barrier(&mNeedsAudioData);
	}
}

Boolean	FFTBufferManager::ComputeFFT(int32_t *outFFTData)
{
	if (HasNewAudioData())
	{
        //Generate a split complex vector from the real data
        vDSP_ctoz((COMPLEX *)mAudioBuffer, 2, &mDspSplitComplex, 1, mFFTLength);
        
        //Take the fft and scale appropriately
        vDSP_fft_zrip(mSpectrumAnalysis, &mDspSplitComplex, 1, mLog2N, kFFTDirection_Forward);
        vDSP_vsmul(mDspSplitComplex.realp, 1, &mFFTNormFactor, mDspSplitComplex.realp, 1, mFFTLength);
        vDSP_vsmul(mDspSplitComplex.imagp, 1, &mFFTNormFactor, mDspSplitComplex.imagp, 1, mFFTLength);
        
        //Zero out the nyquist value
        mDspSplitComplex.imagp[0] = 0.0;
        
        //Convert the fft data to dB
        Float32 tmpData[mFFTLength];
        vDSP_zvmags(&mDspSplitComplex, 1, tmpData, 1, mFFTLength);
        
        //In order to avoid taking log10 of zero, an adjusting factor is added in to make the minimum value equal -128dB
        vDSP_vsadd(tmpData, 1, &mAdjust0DB, tmpData, 1, mFFTLength);
        Float32 one = 1;
        vDSP_vdbcon(tmpData, 1, &one, tmpData, 1, mFFTLength, 0);
        
        //Convert floating point data to integer (Q7.24)
        vDSP_vsmul(tmpData, 1, &m24BitFracScale, tmpData, 1, mFFTLength);
        for(UInt32 i=0; i<mFFTLength; ++i)
            outFFTData[i] = (SInt32) tmpData[i];
        
        OSAtomicDecrement32Barrier(&mHasAudioData);
		OSAtomicIncrement32Barrier(&mNeedsAudioData);
		mAudioBufferCurrentIndex = 0;
		return true;
	}
	else if (mNeedsAudioData == 0)
		OSAtomicIncrement32Barrier(&mNeedsAudioData);
	
	return false;
}

//Code added by Diego von Beck, all rights reserved:

void FFTBufferManager::setFormatToUnit(AudioUnit *audioUnit) {
    CAStreamBasicDescription desc;
    desc = CAStreamBasicDescription(44100, kAudioFormatLinearPCM, 4, 1, 4, 2, 32, kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved);
    AudioUnitSetProperty(*audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &desc, sizeof(desc));
    AudioUnitSetProperty(*audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &desc, sizeof(desc));
}

void FFTBufferManager::intArrayNew(int32_t **pointer, int32_t size) {
    if (*pointer != NULL) delete [] *pointer;
    *pointer = new int32_t[size];
}