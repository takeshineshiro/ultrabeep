//
//  UBFirstViewController.h
//  UltraBeep
//
//  Created by Diego von Beck on 7/2/13.
//  Copyright (c) 2013 Diego von Beck. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UBFirstViewController : UIViewController
{
    __weak IBOutlet UILabel *freqLabel;
    __weak IBOutlet UISlider *freqSlider;
}

@property double theta;
@property uint freq;


- (IBAction)freqChange:(id)sender;


@end
