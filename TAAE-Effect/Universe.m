//
//  Universe.m
//  TAAE-Effect
//
//  Created by Patrick Madden on 6/4/16.
//  Copyright © 2016 Secret Base Design. All rights reserved.
//

#import "Universe.h"

@implementation Universe
@synthesize audioController;

-(id)init
{
	self = [super init];
	if (self)
	{
		audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription] inputEnabled:YES];
		[audioController setPreferredBufferDuration:0.005];
		NSError *err;
		[audioController start:&err];
	}
	
	return self;
}
@end
