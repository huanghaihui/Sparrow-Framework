//
//  DemoAppDelegate.m
//  Demo
//
//  Created by Daniel Sperl on 25.07.09.
//  Copyright Incognitek 2009. All rights reserved.
//

#import "DemoAppDelegate.h"
#import "Game.h"
#import "Sparrow.h"

#import "SPNSExtensions.h"

// --- c functions ---

void onUncaughtException(NSException *exception) 
{
	NSLog(@"uncaught exception: %@", exception.description);
}

// ---

@implementation DemoAppDelegate

@synthesize window;
@synthesize sparrowView;

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{    
    SP_CREATE_POOL(pool);    
    
    NSSetUncaughtExceptionHandler(&onUncaughtException); 
    
    Game *game = [[Game alloc] initWithWidth:320 height:480];        
    sparrowView.stage = game;
    sparrowView.isStarted = YES;     
    sparrowView.frameRate = 30;
    sparrowView.multipleTouchEnabled = YES;
    [window makeKeyAndVisible];
    [game release];    
    
    SP_RELEASE_POOL(pool);
}

- (void)applicationWillResignActive:(UIApplication *)application 
{    
    sparrowView.frameRate = 5;
}

- (void)applicationDidBecomeActive:(UIApplication *)application 
{
	sparrowView.frameRate = 30;
}

- (void)dealloc 
{
    [window release];
    [super dealloc];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    [SPPoint purgePool];
    [SPRectangle purgePool];
    [SPMatrix purgePool];    
}

@end
