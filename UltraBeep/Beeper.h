//
//  Beeper.h
//  UltraBeep
//
//  Created by Diego von Beck on 8/9/13.
//  Copyright (c) 2013 Diego von Beck. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@interface Beeper : NSObject

{
	AudioComponentInstance toneUnit;
    __weak IBOutlet UILabel *volumeWarningLabel;
    
@public
	double frequency;
	double sampleRate;
	double theta;
    bool isPlaying;
}

- (void)togglePlay;
- (void)start;
- (void)stop;
- (id)initWithFrequency: (double)freq;



@end
