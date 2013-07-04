//
//  UBSecondViewController.h
//  UltraBeep
//
//  Created by Diego von Beck on 7/2/13.
//  Copyright (c) 2013 Diego von Beck. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UBSecondViewController : UIViewController
{
    __weak IBOutlet UILabel *freqLabel;
    __weak IBOutlet UISlider *freqSlider;
    __weak IBOutlet UILabel *numLabel;
    __weak IBOutlet UIButton *startButton;
    uint freq;
    BOOL receiving;
    
}
- (IBAction)receiveToggle:(id)sender;
- (IBAction)freqChange:(id)sender;
@end
