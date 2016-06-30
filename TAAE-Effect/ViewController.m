//
//  ViewController.m
//  TAAE-Effect
//
//  Created by Patrick Madden on 6/4/16.
//  Copyright © 2016 Secret Base Design. All rights reserved.
//

#import "ViewController.h"
#import "RWKnobControl.h"
#import <mach/mach.h> //for cpu_usage()

#define BOUNDED(x,lo,hi) ((x) < (lo) ? (lo) : (x) > (hi) ? (hi) : (x))

#define TWENTY_OVER_LN10 (8.6858896380650365530225783783321)

@interface ViewController () {
    RWKnobControl *_knobControl1;
}


@end

@implementation ViewController
@synthesize universe;
@synthesize volumeSlider;
//@synthesize volumeStepper;
@synthesize effectGenerator;

static void audioCallback(id THIS, AEAudioController *audioController, void *source, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio);

void iaaChanged(void *inRefCon, AudioUnit inUnit, AudioUnitPropertyID inID, AudioUnitScope inScope, AudioUnitElement inElement);

// Declare DSP parameter variables.
static double volume = 0.0;

// Major hack.  Just grab some static buffer space to hold the incoming
// audio.  We write here in the audioReceiver, and pull out of it in the
// effect generator.  Ideally, this is a circular buffer, but I'm punting
// to get a proof-of-concept app together.
static Float32 bufferLeft[4096];
static Float32 bufferRight[4096];

//- (double) round:(double)inputValue  // rounding function for doubles, WIP. This could be a global (extern??), where should it be placed?
//
//{
//    double a;
//    return a; //return rounded value
//}
- (double) voltTodB:(double) x  // volt to dB function, WIP. This could be a global, where should it be placed?

{
    if (x < 0.00000000000001) return -300;
    
    double v=log(x)*TWENTY_OVER_LN10;
    return v<-281?-300:v;
}


- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.view.tintColor = [UIColor colorWithRed:(1.0) green:(0.5) blue:0.0 alpha:(1.0)];
    ///////////////////// Construct custom controls
   _knobControl1 = [[RWKnobControl alloc] initWithFrame:self.knobPlaceholder1.bounds];
    [self.knobPlaceholder1 addSubview:_knobControl1];
   
    /////////////////////
    
    // set the initial values here
	volume = volumeSlider.value = 0.5;
    
//    _knobControl1.lineWidth = 2.0;
//    _knobControl1.pointerLength = 8.0;
    _knobControl1.minimumValue = 0.0;  //set knob minimum value.
    _knobControl1.maximumValue = 1.0; // set knob maximum value.
    _knobControl1.shape = 0.5;   // set knob shape
    _knobControl1.value = 0.5;  // set knob initial value
    /////////////////////
    [self knobControlsSetIsNormalized];
    /////////////////////
    
    [self updateVolumeLabel];    // init Label
    
    [ _knobControl1 setValue:(_knobControl1.value) animated:false];
    [self updateKnobLabel1:_knobControl1.value];
    
    [_knobControl1 addObserver:self forKeyPath:@"value" options:0 context:NULL];
    
    // Hooks up the knob control
    [_knobControl1 addTarget:self
                     action:@selector(sliderMoved:)
           forControlEvents:UIControlEventValueChanged];
    /////////////////////
    
    
    
    
    
	
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
    
    // get buffer size. //// TEST
   float test = [universe audioController ].currentBufferDuration   ;
    
    int bufferFrames = AEConvertSecondsToFrames( [universe audioController ] ,test );
    
    NSLog(@"Buffer Frames: %d  Buffer Seconds: %f", bufferFrames, test);  // output to console
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

- (IBAction)handleValueChanged:(id)sender {
    
//    if(sender == self.volumeSlider) {
//        _knobControl1.value = self.volumeSlider.value;
//    } else if(sender == _knobControl1) {
//        self.volumeSlider.value = _knobControl1.value;
//    }
}


- (void)updateKnobLabel1:(double)value

{
        self.knobLabel1.text = [NSString stringWithFormat:@"%0.2f", value];
}

- (void)knobControlsSetIsNormalized
{
    if(_knobControl1.maximumValue != 1.0 || _knobControl1.minimumValue != 0.0) {
        
        _knobControl1.isNormalized = false;
    }else{
        
        _knobControl1.isNormalized = true;
    }
}


-(IBAction)sliderMoved:(id)sender
{
    if(sender == self.volumeSlider) {
        
        volume = self.volumeSlider.value; // NSLog(@"Volume set to %f", volume);
        
        [self updateVolumeLabel];
        
    }
}

-(void)updateVolumeLabel
{
    NSString *newValue; // volumeSlider.value  == [volumeSlider value]
    
    if (volumeSlider.value != 1.0 && volumeSlider.value != 0.0) {
        
        self.volumeLabel.text = newValue = [NSString stringWithFormat:@"%0.2f dB", [self voltTodB: volumeSlider.value]/*volumeSlider.value*/];
    }else if (volumeSlider.value == 1.0){
        
        self.volumeLabel.text = newValue = [NSString stringWithFormat:@"-%0.2f dB", 0.0];
    }else{ /*if (volumeSlider.value == 0.0)*/
        
        // self.volumeLabel.text = newValue = [NSString stringWithFormat:@"-inf dB"];
        self.volumeLabel.text = newValue = [NSString stringWithFormat:@"- %C dB", 0x221E]; // - ∞.
    }
}


-(IBAction)stepperChange:(UIStepper *)sender
{
    // Look at change in stepper's value, reset the value to a default (known) value after each run.
    double stepperDefault = 0.5;  // same as initial value set in Interface Builder
    
    if (sender == self.stepper1) {
        
        if (sender.value >= stepperDefault + sender.stepValue){ // test whether + or - was pressed.
            
            sender.value = _knobControl1.value + sender.stepValue;
        }else{
            sender.value = _knobControl1.value - sender.stepValue;
        }
    
        _knobControl1.value = sender.value;
        
        [ _knobControl1 setValue:(_knobControl1.value) animated:false];
        
        [self updateKnobLabel1:_knobControl1.value];
        
    }else if (sender == self.volumeStepper) {
        
        if (sender.value >= stepperDefault + sender.stepValue){ // test whether + or - was pressed.
            
            sender.value = volume + sender.stepValue;
        }else{
            sender.value = volume - sender.stepValue;
        }
        
        volume = self.volumeSlider.value = sender.value; // set slider and volume to stepper value
        
        [self updateVolumeLabel];
    }
    
    sender.value = stepperDefault; // reset stepper value to default
}

-(IBAction)restartAudio:(id)sender
{
	NSError *err;
	
	[[universe audioController] stop];
	[[universe audioController] start:&err];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if(object == _knobControl1 && [keyPath isEqualToString:@"value"]) {
        
        [self updateKnobLabel1:_knobControl1.value];
    }
}



float cpu_usage()
{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
    return tot_cpu;
}

@end
