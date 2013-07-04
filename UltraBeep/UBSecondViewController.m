//
//  UBSecondViewController.m
//  UltraBeep
//
//  Created by Diego von Beck on 7/2/13.
//  Copyright (c) 2013 Diego von Beck. All rights reserved.
//

#import "UBSecondViewController.h"

@interface UBSecondViewController ()

@end

@implementation UBSecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self freqChange:nil];
    receiving = false;
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)receiveToggle:(id)sender {
    if (!receiving) {
        [freqSlider setEnabled:NO];
        [startButton setTitle: @"Stop Receiving" forState:UIControlStateNormal];
    } else {
        [freqSlider setEnabled:YES];
        [startButton setTitle: @"Start Receiving" forState:UIControlStateNormal];
    }
    
    receiving = !receiving;
}

- (IBAction)freqChange:(id)sender {
    freq = [freqSlider value];
    freq /= 400;
    freq *= 400;
    [freqLabel setText:[NSString stringWithFormat:@"%i Hz", freq]];
}
@end
