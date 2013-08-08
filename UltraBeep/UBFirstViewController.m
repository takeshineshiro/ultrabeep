//
//  UBFirstViewController.m
//  UltraBeep
//
//  Created by Diego von Beck on 7/2/13.
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

#import "UBFirstViewController.h"
#import <AudioToolbox/AudioToolbox.h>


@interface UBFirstViewController ()

@end

@implementation UBFirstViewController

@synthesize theta;
@synthesize freq;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self freqChange:nil];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done:(UIStoryboardSegue *)segue {
    // Optional place to read data from closing controller
}

- (IBAction)freqChange:(id)sender {
    freq = [freqSlider value];
    freq /= 400;
    freq *= 400;
    [freqLabel setText:[NSString stringWithFormat:@"%i Hz", freq]];
}

@end
