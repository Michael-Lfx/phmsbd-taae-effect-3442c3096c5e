//
//  RWKnobControl.m
//  KnobControl
//
//  Created by j on 6/8/16.
//  Copyright © 2016 RayWenderlich. All rights reserved.
//


//#include "RWRotationGestureRecognizer.h"
//#include "RWKnobRenderer.h"
//#include "RWKnobControl.h"
#import "RWRotationGestureRecognizer.h"
#import "RWKnobRenderer.h"
#import "RWKnobControl.h"
//#import "../RWRotationGestureRecognizer.h"
//#import "../RWKnobRenderer.h"
//#import "../RWKnobControl.h"
//#import "KnobControl/RWRotationGestureRecognizer.h"
//#import "KnobControl/RWKnobRenderer.h"
//#import "KnobControl/RWKnobControl.h"

//#define IPMIN(x,y) ((x)<(y)?(x):(y))
//#define IPMAX(x,y) ((x)<(y)?(y):(x))
#define BOUNDED(x,lo,hi) ((x) < (lo) ? (lo) : (x) > (hi) ? (hi) : (x))

@implementation RWKnobControl {
    RWKnobRenderer *_knobRenderer;
    RWRotationGestureRecognizer *_gestureRecognizer;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@dynamic lineWidth;
@dynamic startAngle;
@dynamic endAngle;
@dynamic pointerLength;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _minimumValue = 0.0;
        _maximumValue = 1.0;
        _value = 0.0;
        _continuous = YES;
        _shape = 1.0;
        _gestureRecognizer = [[RWRotationGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handleGesture:)];
        [self addGestureRecognizer:_gestureRecognizer];
        
        [self createKnobUI];
    }
    return self;
}

double FromNormalizedParam(double normalizedValue, double min, double max, double shape)
{
    return min + pow((double) normalizedValue, shape) * (max - min);
}

double ToNormalizedParam(double nonNormalizedValue, double min, double max, double shape)
{
    return pow((nonNormalizedValue - min) / (max - min), 1.0 / shape);
}

#pragma mark - API Methods


- (void)setValue:(CGFloat)value animated:(BOOL)animated
{
    if(value != _value) {
        [self willChangeValueForKey:@"value"];
        // Save the value to the backing ivar
        // Make sure we limit it to the requested bounds
       _value = MIN(self.maximumValue, MAX(self.minimumValue, value));  // add shape here?
        
        double a = _value;
        
        if(!_isNormalized) {  // if is not normalized
            
//        a =  BOUNDED(a, self.minimumValue , self.maximumValue); //needed?
            a = ToNormalizedParam(a, self.minimumValue , self.maximumValue , 1.0); // make normalized
        }
        
        a = FromNormalizedParam(a, self.minimumValue , self.maximumValue , self.shape);  //testing
//        a = IPMIN(a, self.maximumValue);  // needed ?
        
        // Now let's update the knob with the correct angle
        CGFloat angleRange = self.endAngle - self.startAngle;
        CGFloat valueRange = self.maximumValue - self.minimumValue;
        
        CGFloat angleForValue = (a  - self.minimumValue) / valueRange * angleRange + self.startAngle;

        [_knobRenderer setPointerAngle:angleForValue animated:animated];
        
   //     self.tintColor = [UIColor colorWithRed:((1*a)+0.875) green:(-1*(1*a)+1.0) blue:(-1*(1*a)-0.0) alpha:(1.0)]; // color me.
        
        [self didChangeValueForKey:@"value"];
    }
}

- (CGFloat)lineWidth
{
    return _knobRenderer.lineWidth;
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    _knobRenderer.lineWidth = lineWidth;
}

- (CGFloat)startAngle
{
    return _knobRenderer.startAngle;
}

- (void)setStartAngle:(CGFloat)startAngle
{
    _knobRenderer.startAngle = startAngle;
}

- (CGFloat)endAngle
{
    return _knobRenderer.endAngle;
}

- (void)setEndAngle:(CGFloat)endAngle
{
    _knobRenderer.endAngle = endAngle;
}

- (CGFloat)pointerLength
{
    return _knobRenderer.pointerLength;
}

- (void)setPointerLength:(CGFloat)pointerLength
{
    _knobRenderer.pointerLength = pointerLength;
}

#pragma mark - Property overrides
- (void)setValue:(CGFloat)value
{
    // Chain with the animation method version
    [self setValue:value animated:NO];
}


- (void)tintColorDidChange
{
    _knobRenderer.color = self.tintColor;
}

- (void)createKnobUI
{
    _knobRenderer = [[RWKnobRenderer alloc] init];
    [_knobRenderer updateWithBounds:self.bounds];
    _knobRenderer.color = self.tintColor;
    // Set some defaults
    _knobRenderer.startAngle = -M_PI * 10.1 / 8.0; // -M_PI * 11 / 8.0;
    _knobRenderer.endAngle = M_PI * 2.1 / 8.0; // M_PI * 3 / 8.0;
    _knobRenderer.pointerAngle = _knobRenderer.startAngle;
    _knobRenderer.lineWidth = 2.0;
    _knobRenderer.pointerLength = 6.0;
    // Add the layers
    [self.layer addSublayer:_knobRenderer.trackLayer];
    [self.layer addSublayer:_knobRenderer.pointerLayer];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@"value"]) {
        return NO;
    } else {
        return [super automaticallyNotifiesObserversForKey:key];
    }
}

- (void)handleGesture:(RWRotationGestureRecognizer *)gesture
{
    // 1. Mid-point angle
    CGFloat midPointAngle = (2 * M_PI + self.startAngle - self.endAngle) / 2
    + self.endAngle;
    
    // 2. Ensure the angle is within a suitable range
    CGFloat boundedAngle = gesture.touchAngle;
    if(boundedAngle > midPointAngle) {
        boundedAngle -= 2 * M_PI;
    } else if (boundedAngle < (midPointAngle - 2 * M_PI)) {
        boundedAngle += 2 * M_PI;
    }
    // 3. Bound the angle to within the suitable range
    boundedAngle = MIN(self.endAngle, MAX(self.startAngle, boundedAngle));
    
    // 4. Convert the angle to a value
    CGFloat angleRange = self.endAngle - self.startAngle;
    CGFloat valueRange = self.maximumValue - self.minimumValue;
    CGFloat valueForAngle = (boundedAngle - self.startAngle) / angleRange  //orig
    * valueRange + self.minimumValue;
    
//    CGFloat valueForAngle = pow((boundedAngle - self.startAngle) / angleRange
//    * valueRange + self.minimumValue, 1.0/_shape);  //added
    
    // 5. Set the control to this value
    self.value = valueForAngle;
    
    // Notify of value change
    if (self.continuous) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    } else {
        // Only send an update if the gesture has completed
        if(_gestureRecognizer.state == UIGestureRecognizerStateEnded
           || _gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }
}

@end
