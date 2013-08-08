//
//  UBTransmissionViewController.h
//  UltraBeep
//
//  Created by Diego von Beck on 8/4/13.
//  Copyright (c) 2013 Diego von Beck. All rights reserved.
//
//  Part of this code was written by Matt Gallagher on 2010/10/20.
//
//  The next parragraph spacifies the licensing attributed to the code
//  wrriten by him only:
//
//  "Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required."
//
//  His original code can be found here:
//  http://projectswithlove.com/projects/ToneGenerator.zip
//

#import <UIKit/UIKit.h>
#import <AudioUnit/AudioUnit.h>

@interface UBTransmissionViewController : UIViewController

{
	AudioComponentInstance toneUnit;
    __weak IBOutlet UILabel *volumeWarningLabel;
    
@public
	double frequency;
	double sampleRate;
	double theta;
}

- (void)togglePlay;

- (IBAction)touchDown:(id)sender;
- (IBAction)touchUp:(id)sender;

-(void)stop;


@end
