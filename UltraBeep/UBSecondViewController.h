//
//  UBSecondViewController.h
//  UltraBeep
//
//  Created by Diego von Beck on 7/2/13.
//  Copyright (c) 2013 Diego von Beck. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "FFTWrapper.h"
#import <AudioUnit/AudioUnit.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface UBSecondViewController : UIViewController
{
    __weak IBOutlet UILabel *freqLabel;
    __weak IBOutlet UISlider *freqSlider;
    __weak IBOutlet UILabel *numLabel;
    __weak IBOutlet UIButton *startButton;
    uint freq;
    BOOL receiving;
    AVAudioSession* session;
    AVAudioRecorder* recorder;
    UInt32 maxFPS;
    NSTimer* timer;
    SInt32*	fftData;
	NSUInteger fftLength;
    int32_t* l_fftData;

}

@property (nonatomic, assign)	AudioUnit rioUnit;
@property (nonatomic) FFTWrapper* fftBufferManager;

- (IBAction)receiveToggle:(id)sender;
- (IBAction)freqChange:(id)sender;
- (void)processAudioData;
@end
