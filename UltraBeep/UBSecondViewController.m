//
//  UBSecondViewController.m
//  UltraBeep
//
//  Created by Diego von Beck on 7/2/13.
//  Copyright (c) 2013 Diego von Beck. All rights reserved.
//

#import "UBSecondViewController.h"

/*
 AudioUnitRender
 Initiates a rendering cycle for an audio unit.
 
 OSStatus AudioUnitRender (
 AudioUnit                   inUnit,
 AudioUnitRenderActionFlags  *ioActionFlags,
 const AudioTimeStamp        *inTimeStamp,
 UInt32                      inOutputBusNumber,
 UInt32                      inNumberFrames,
 AudioBufferList             *ioData
 );
 Parameters
 inUnit
 The audio unit that you are asking to render.
 ioActionFlags
 Flags to configure the rendering operation.
 inTimeStamp
 The audio time stamp for the render operation. Each time stamp must contain a valid sample time that is incremented monotonically from the previous call to this function. That is, the next time stamp is equal to inTimeStamp + inNumberFrames.
 If sample time does not increase like this from one render call to the next, the audio unit interprets that as a discontinuity with the timeline it is rendering for.
 When rendering to multiple output buses, ensure that this value is the same for each bus. Using the same value allows an audio unit to determine that the rendering for each output bus is part of a single render operation.
 inOutputBusNumber
 The output bus to render for.
 inNumberFrames
 The number of audio sample frames to render.
 ioData
 On input, the audio buffer list that the audio unit is to render into. On output, the audio data that was rendered by the audio unit.
 The AudioBufferList that you provide on input must match the topology for the current audio format for the given bus. The buffer list can be either of these two variants:
 If the mData pointers are non-null, the audio unit renders its output into those buffers
 If the mData pointers are null, the audio unit can provide pointers to its own buffers. In this case, the audio unit must keep those buffers valid for the duration of the calling thread’s I/O cycle.
 */

static OSStatus	PerformThru(
							void						*inRefCon,
							AudioUnitRenderActionFlags 	*ioActionFlags,
							const AudioTimeStamp 		*inTimeStamp,
							UInt32 						inBusNumber,
							UInt32 						inNumberFrames,
							AudioBufferList 			*ioData)
{
    //****Bridge?
	UBSecondViewController *THIS = (__bridge UBSecondViewController *)inRefCon;
	OSStatus err = AudioUnitRender(THIS.rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
	if (err) { NSLog(@"PerformThru: error %d\n", (int)err); return err; }
	
	// Remove DC component
	/*
    for(UInt32 i = 0; i < ioData->mNumberBuffers; ++i)
		THIS.dcFilter[i].InplaceFilter((Float32*)(ioData->mBuffers[i].mData), inNumberFrames);
	*/
    if ([[THIS fftBufferManager] NeedsNewAudioData])
        [[THIS fftBufferManager] GrabAudioData: ioData];
    //NSLog(@"Callback is running!");
	return err;
}

@interface UBSecondViewController ()

@end

@implementation UBSecondViewController

@synthesize rioUnit;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self freqChange:nil];
    receiving = false;
    
	//Initialize audio session
    session = [AVAudioSession sharedInstance];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)receiveToggle:(id)sender {
    //Add a delay to avoid super-fast toggling
    if (!receiving) {
        [freqSlider setEnabled:NO];
        [startButton setTitle: @"Stop Receiving" forState:UIControlStateNormal];
        
        //*********** Make these exceptions send error info!
        
        //Setting preferred sample rate
        [session setPreferredSampleRate:44100 error:nil];
        
        // Setting session category
        if (![session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil]) //Use CategoryPlaybackAndRecord to enable built in mic only? is that possible?
            [NSException raise:@"session setCategory failed" format:@"Setting the Audio Session Category failed"];
        
        //Activating session
        if (![session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil])
            [NSException raise:@"session activation failed" format:@"Setting the Audio Session Active to YES failed"];
        
        //Checking session sample rate
        if ([session sampleRate] < 44000)
            [NSException raise:@"Low sample rate" format:@"Low sample rate: %f",[session sampleRate]];
        
        //Checking for the existance of an input device
        if (![session isInputAvailable])
            [NSException raise:@"No input" format:@"No input device detected"];
        
        //********Setting preferred buffer size, Should I? What value?
        //Info: The audio I/O buffer duration, in seconds, is 0.005 through 0.093 s, corresponding to a range of 256 through 4,096 sample frames at 44.1 kHz.
        //FPS: Specifies the maximum number of sample frames an audio unit is prepared to supply on one invocation of its AudioUnitRender function.
        //Do I need >4096 FPS to get a slice big enough for nice FFT processing?
        /*
        if (![session setPreferredIOBufferDuration:.005 error:nil])
            [NSException raise:@"Set buffer size failed" format:@"setPreferredIOBufferDuration finished with error"];
        */
        
        
        //Defining and instanciating remote I/O audio unit
        AudioComponentDescription ioUnitDescription;
        ioUnitDescription.componentType = kAudioUnitType_Output;
        ioUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO;
        ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
        ioUnitDescription.componentFlags = 0;
        ioUnitDescription.componentFlagsMask = 0;
        AudioComponent foundUnitRef = AudioComponentFindNext(NULL, &ioUnitDescription);
        AudioComponentInstanceNew(foundUnitRef, &rioUnit);
        
        //******Build audio processing graph?????
        
        //******Configure audio unit
        UInt32 enableInput        = 1;    // to enable input
        AudioUnitElement inputBus = 1;
        
        AudioUnitSetProperty (
            rioUnit,
            kAudioOutputUnitProperty_EnableIO,
            kAudioUnitScope_Input,
            inputBus,
            &enableInput,
            sizeof (enableInput)
        );
        
        
        //******Write and attach "render callback function"
        /*
         kAudioOutputUnitProperty_SetInputCallback
         A read/write AURenderCallbackStruct data structure valid on the audio unit global scope. When an output unit has been enabled for input operation, this callback can be used to provide a single callback to the host application from the input I/O proc, in order to notify the host that input is available and may be obtained by calling the AudioUnitRender function.
         
        */
        
        
        AURenderCallbackStruct inputProc;  //******Store this as instance variable for memory leak avoidance???
        inputProc.inputProc = PerformThru;
        inputProc.inputProcRefCon = (__bridge void *)(self);
        
        AudioUnitSetProperty(rioUnit, /*kAudioOutputUnitProperty_SetInputCallback*/ kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &inputProc, sizeof(inputProc));
        
        //******Connect nodes
        //******Initialize audio unit
        
        //Saving max frames per slice.
        UInt32 size = sizeof(maxFPS);
        //****Get property giving wrong FPS!!!!
        AudioUnitGetProperty(rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size);
        maxFPS = 1024;
        NSLog(@"maxFPS: %i, sampleRate: %f, IOBufferDuration: %f", (unsigned int)maxFPS, [session sampleRate], [session IOBufferDuration]);
        
        //Initializing FFTBufferManager wrapper
        if (self.fftBufferManager == nil) self.fftBufferManager = [[FFTWrapper alloc] initWithNumberOfFrames:maxFPS];
        
        //*******Do I need this? Is it of any use?
        //[FFTWrapper setFormatToUnit:&rioUnit];
        
        //Setting up buffer space
        [FFTWrapper intArrayNewWithPointer:&l_fftData andSize:maxFPS/2];
        
        //Starting audio unit
        AudioOutputUnitStart(rioUnit);
        
        //Set triggering of FFT analysis and output refresh
        //*****IS INTERVAL TOO HIGH?
        timer = [NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(processAudioData) userInfo:nil repeats:YES];
        
        
        
    } else {
        
        //Stopping timer
        if (timer) {
            [timer invalidate];
            timer = NULL;
        }
        
        AudioOutputUnitStop(rioUnit);
        AudioComponentInstanceDispose(rioUnit);
        
        if (![session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil])
            [NSException raise:@"session deactivation failed" format:@"Setting the Audio Session Active to NO failed"];
        
        [freqSlider setEnabled:YES];
        [startButton setTitle: @"Start Receiving" forState:UIControlStateNormal];
        
    }
    
    receiving = !receiving;
}

- (void)processAudioData {
    if ([[self fftBufferManager] HasNewAudioData])
	{
		if ([[self fftBufferManager] ComputeFFT:l_fftData])
		{
            NSUInteger lengthOfData = [[self fftBufferManager] GetNumberFrames] / 2;
            if (lengthOfData != fftLength)
            {
                fftLength = lengthOfData;
            }
            fftData = (SInt32 *)(realloc(fftData, lengthOfData * sizeof(SInt32)));

            memmove(fftData, l_fftData, fftLength * sizeof(Float32));
            
            //NSLog(@"There is new data!");
            NSString *labelText = [NSString stringWithFormat:@"%i",(int)fftData[(int) (lengthOfData*2.0*freq/[session sampleRate]) ]];
            [numLabel setText:labelText];

		}
	} //else NSLog(@"There is NO new data!");
    
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (receiving) [self receiveToggle:nil];
}

- (IBAction)freqChange:(id)sender {
    freq = [freqSlider value];
    freq /= 400;
    freq *= 400;
    [freqLabel setText:[NSString stringWithFormat:@"%i Hz", freq]];
}

//********Add methods to deal with audio interruptions (AVAudioRecorder delegate)
@end
