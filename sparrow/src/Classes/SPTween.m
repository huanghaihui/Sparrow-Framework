//
//  SPTween.m
//  Sparrow
//
//  Created by Daniel Sperl on 09.05.09.
//  Copyright 2009 Incognitek. All rights reserved.
//

#import "SPTween.h"
#import "SPTransitions.h"
#import "SPTweenedProperty.h"
#import "SPMacros.h"

#define TRANS_SUFFIX  @"WithDelta:ratio:"

typedef float (*FnPtrTransition) (id, SEL, float, float);

@implementation SPTween

@synthesize time = mTotalTime;
@synthesize delay = mDelay;
@synthesize target = mTarget;

- (id)initWithTarget:(id)target time:(double)time transition:(NSString*)transition
{
    if (self = [super init])
    {
        mTarget = [target retain];
        mTotalTime = MAX(0.0001, time); // zero is not allowed
        mCurrentTime = 0;
        mDelay = 0;
        mProperties = [[NSMutableArray alloc] init];        
        
        // create function pointer for transition
        NSString *transMethod = [transition stringByAppendingString:TRANS_SUFFIX];
        mTransSelector = NSSelectorFromString(transMethod);    
        if (![SPTransitions respondsToSelector:mTransSelector])
            [NSException raise:SP_EXC_INVALID_OPERATION 
                        format:@"transition not found: '%@'", transition];
        mTransFunc = [SPTransitions methodForSelector:mTransSelector];
    }
    return self;
}

- (id)initWithTarget:(id)target time:(double)time
{
    return [self initWithTarget:target time:time transition:SP_TRANSITION_LINEAR];
}

- (void)animateProperty:(NSString*)property targetValue:(float)value
{    
    SPTweenedProperty *tweenedProp = [[SPTweenedProperty alloc] 
        initWithTarget:mTarget name:property endValue:value];
    [mProperties addObject:tweenedProp];
    [tweenedProp release];
}

- (void)advanceTime:(double)seconds
{
    double previousTime = mCurrentTime;    
    mCurrentTime = MIN(mTotalTime, mCurrentTime + seconds);

    if (mCurrentTime < 0 || previousTime >= mTotalTime) return;

    if (previousTime <= 0 && mCurrentTime >= 0 &&
        [self hasEventListenerForType:SP_EVENT_TYPE_TWEEN_STARTED])
    {
        SPEvent *event = [[SPEvent alloc] initWithType:SP_EVENT_TYPE_TWEEN_STARTED];        
        [self dispatchEvent:event];
        [event release];        
    }   
    
    float ratio = mCurrentTime / mTotalTime;    
    FnPtrTransition transFunc = (FnPtrTransition) mTransFunc;
    Class transClass = [SPTransitions class];
    
    for (SPTweenedProperty *prop in mProperties)
    {        
        if (previousTime <= 0 && mCurrentTime >= 0) 
            prop.startValue = prop.currentValue;
        
        float startValue = prop.startValue;
        float delta = prop.delta;
        float transitionValue = transFunc(transClass, mTransSelector, delta, ratio);        
        prop.currentValue = startValue + transitionValue;
    }
   
    if ([self hasEventListenerForType:SP_EVENT_TYPE_TWEEN_UPDATED])
    {
        SPEvent *event = [[SPEvent alloc] initWithType:SP_EVENT_TYPE_TWEEN_UPDATED];
        [self dispatchEvent:event];    
        [event release];
    }
    
    if (previousTime < mTotalTime && mCurrentTime >= mTotalTime &&
        [self hasEventListenerForType:SP_EVENT_TYPE_TWEEN_COMPLETED])
    {
        SPEvent *event = [[SPEvent alloc] initWithType:SP_EVENT_TYPE_TWEEN_COMPLETED];
        [self dispatchEvent:event];
        [event release];        
    }
}

- (NSString*)transition
{
    NSString *selectorName = NSStringFromSelector(mTransSelector);
    return [selectorName substringToIndex:selectorName.length - [TRANS_SUFFIX length]];
}

- (BOOL)isComplete
{
    return mCurrentTime >= mTotalTime;
}

- (void)setDelay:(double)delay
{
    mCurrentTime = mCurrentTime + mDelay - delay;
    mDelay = delay;
}

+ (SPTween*)tweenWithTarget:(id)target time:(double)time transition:(NSString*)transition
{
    return [[[SPTween alloc] initWithTarget:target time:time transition:transition] autorelease];
}

+ (SPTween*)tweenWithTarget:(id)target time:(double)time
{
    return [[[SPTween alloc] initWithTarget:target time:time] autorelease];
}

- (void)dealloc
{
    [mTarget release];
    [mProperties release];
    [super dealloc];
}

@end
