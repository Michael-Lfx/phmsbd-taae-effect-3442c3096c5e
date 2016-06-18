//
//  ViewController.m
//  TAAE-Effect
//
//  Created by Patrick Madden on 6/4/16.
//  Copyright © 2016 Secret Base Design. All rights reserved.
//

#import "ViewController.h"

#define TWENTY_OVER_LN10 (8.6858896380650365530225783783321)

@interface ViewController ()

@end

@implementation ViewController
@synthesize universe;
@synthesize volumeSlider;
//@synthesize volumeStepper;
@synthesize effectGenerator;

static void audioCallback(id THIS, AEAudioController *audioController, void *source, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio);
void iaaChanged(void *inRefCon, AudioUnit inUnit, AudioUnitPropertyID inID, AudioUnitScope inScope, AudioUnitElement inElement);

static double volume = 0;

// Major hack.  Just grab some static buffer space to hold the incoming
// audio.  We write here in the audioReceiver, and pull out of it in the
// effect generator.  Ideally, this is a circular buffer, but I'm punting
// to get a proof-of-concept app together.
static Float32 bufferLeft[4096];
static Float32 bufferRight[4096];

- (double) round:(double)inputValue  // rounding function for doubles, WIP. This could be a global (extern??), where should it be placed?

{
    double a;
    return a; //return rounded value
}
- (double) voltTodB:(double) x  // volt to dB function, WIP. This could be a global, where should it be placed?

{
    if (x < 0.00000000000001) return -300;
    
    double v=log(x)*TWENTY_OVER_LN10;
    return v<-281?-300:v;
}


- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

	volume = volumeSlider.value = 0.6;  // set the initial values here
   
    [self updateVolumeLabel];    // init Label
	
	universe = [[Universe alloc] init];
	[[universe audioController] addInputReceiver:self];
	// AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, uiAudioSessionPropertyListener, (__bridge void *)self);
	
	AudioUnitAddPropertyListener([[universe audioController] audioUnit], kAudioUnitProperty_IsInterAppConnected,
								 iaaChanged, (__bridge void * _Nullable)(self));
	
	AudioComponentDescription desc = { kAudioUnitType_RemoteEffect, 'sbfx', 'sbda', 0, 0 };
	AudioOutputUnitPublish(&desc, CFSTR("TAAE Effect"), 0, [[universe audioController] audioUnit]);
	
	effectGenerator = [AEBlockChannel channelWithBlock:^(const AudioTimeStamp  *time,
														 UInt32           frames,
														 AudioBufferList *audio)
	{
		static int count = 0;
		Float32 *left, *right;
		float total = 0;
		left = (Float32 *)audio->mBuffers[0].mData;
		right = (Float32 *)audio->mBuffers[1].mData;

		for ( int i=0; i<frames; i++ )
		{
			left[i] = bufferLeft[i] * volume;
			right[i] = bufferRight[i] * volume;
			
			total += fabs(left[i]);
		}
		if ((count % 100) == 0)
		{
		//	NSLog(@"Output process %d %f", count, total);
		}
		++count;
	}];

	effectGenerator.audioDescription = [AEAudioController nonInterleavedFloatStereoAudioDescription];
	[[universe audioController] addChannels:[NSArray arrayWithObjects:effectGenerator, nil]];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


-(AEAudioControllerAudioCallback)receiverCallback {
	return &audioCallback;
}


static void audioCallback(id THISptr, AEAudioController *audioController, void *source, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio)
{
	static int count = 0;
	float total = 0;
	Float32 *leftPtr = audio->mBuffers[0].mData;
	Float32 *rightPtr = audio->mBuffers[1].mData;

	for (int i = 0; i < frames; ++i)
	{
		bufferLeft[i] = leftPtr[i];
		bufferRight[i] = rightPtr[i];
		total += fabs(leftPtr[i]);
	}
	if ((count % 100) == 0)
	{
		// NSLog(@"Input process %d  %f", count, total);
	}
	++count;
}


// Callback for detecting changes to the Inter-App connection chain.  When inserted or removed, you need to stop, and
// then start the audio graph.  Why?  Because, that's why!
void iaaChanged(void *inRefCon, AudioUnit inUnit, AudioUnitPropertyID inID, AudioUnitScope inScope, AudioUnitElement inElement)
{
	ViewController *SELF = (__bridge ViewController *)inRefCon;
	
	NSLog(@"IAA change callback.");
	NSError *err;
	[[[SELF universe] audioController] stop];
	[[[SELF universe] audioController] start:&err];
}


-(IBAction)volumeSliderMoved:(id)sender
{
    if(sender == self.volumeSlider) {
        
        volume = self.volumeSlider.value; // NSLog(@"Volume set to %f", volume);
        
//        _knobControl.value = self.volumeSlider.value;
        [self updateVolumeLabel];
        
    }
//    else if(sender == _knobControl) {
    
//        volume = _knobControl.value;
//        [volumeSlider value] = volume;
    
//        [self updateVolumeLabel];

//    }
}

-(void)updateVolumeLabel
{
    NSString *newValue; // volumeSlider.value  == [volumeSlider value]
    
    if (volumeSlider.value != 1.0 && volumeSlider.value != 0.0) {
        self.volumeLabel.text = newValue = [NSString stringWithFormat:@"%0.2f dB", [self voltTodB: volumeSlider.value]/*volumeSlider.value*/];
    }else if (volumeSlider.value == 1.0){
        self.volumeLabel.text = newValue = [NSString stringWithFormat:@"-%0.2f dB", 0.0];
    } else /*if (volumeSlider.value == 0.0)*/{
        // self.volumeLabel.text = newValue = [NSString stringWithFormat:@"-inf dB"];
        self.volumeLabel.text = newValue = [NSString stringWithFormat:@"- %C dB", 0x221E]; // - ∞.
    }
}



-(IBAction)volumeStepperChange:(id)sender
{                                                    // NSLog(@"clicked on the stepper.");
    UIStepper *volumeStepper = (UIStepper *)sender;  // pointer to the stepper object, so we can manipulate it here.
    //   NSLog(@"Stepper value is %f", [stepper value]);

    // stepper.value cannot be manipulated outside this scope, so we'll reset to its default (known) value after each run.
    double volumeStepperDefault = 0.5;

    if (volumeStepper.value >= volumeStepperDefault + volumeStepper.stepValue){ // test whether + or - was pressed. "0.5" is default in IB.
        
        volumeStepper.value = volume + volumeStepper.stepValue;
    }else{
        volumeStepper.value = volume - volumeStepper.stepValue;
    }

    volume = volumeSlider.value = volumeStepper.value; // set slider and volume to stepper value

    [self updateVolumeLabel];
    
    volumeStepper.value = volumeStepperDefault; // reset volumeStepper value to default.
}

-(IBAction)restartAudio:(id)sender
{
	NSError *err;
	
	[[universe audioController] stop];
	[[universe audioController] start:&err];
}


@end
