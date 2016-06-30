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

@property (weak, nonatomic) IBOutlet UIView *knobPlaceholder1;
@property (weak, nonatomic) IBOutlet UILabel *knobLabel1;
@property (weak, nonatomic) IBOutlet UIStepper *stepper1;


@property (nonatomic, strong) IBOutlet UISlider *volumeSlider;
@property (nonatomic, strong) IBOutlet UIStepper *volumeStepper;
@property (strong, nonatomic) IBOutlet UILabel *volumeLabel; // add a label

@property (strong, nonatomic) IBOutlet UILabel *bufferSizeLabel;
@property (strong, nonatomic) IBOutlet UILabel *sampleRateLabel;

@property (nonatomic, retain) AEBlockChannel *effectGenerator;


@end






