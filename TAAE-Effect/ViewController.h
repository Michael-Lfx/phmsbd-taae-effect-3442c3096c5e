//
//  ViewController.h
//  TAAE-Effect
//
//  Created by Patrick Madden on 6/4/16.
//  Copyright © 2016 Secret Base Design. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Universe.h"

@interface ViewController : UIViewController<AEAudioReceiver>
@property (nonatomic, strong) Universe *universe;

@property (nonatomic, strong) IBOutlet UISlider *volumeSlider;
@property (nonatomic, strong) IBOutlet UIStepper *volumeStepper;
@property (strong, nonatomic) IBOutlet UILabel *volumeLabel; // add a label

@property (nonatomic, retain) AEBlockChannel *effectGenerator;


//-(IBAction)sliderMoved:(id)sender;
//-(IBAction)stepperChange:(id)sender;
//-(IBAction)restartAudio:(id)sender;
//- (double) voltTodB:(double)volume;
//
//- (double) round:(double)inputValue;


@end






