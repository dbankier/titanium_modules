/**
 * Titanium Paint Module
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiPaintModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"

@implementation TiPaintModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"43f13063-d426-4e9c-8a7a-72dc5e4aec57";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"ti.paint++";
}

#pragma mark Lifecycle

-(void)startup
{
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
	
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably
	
	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)dealloc
{
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

-(NSInteger)ERASE
{
	return DrawModeErase;
}

-(NSInteger)STRAIGHT_LINE
{
	return DrawModeStraightLine;
}

-(NSInteger)CURVE_LINE
{
	return DrawModeCurve;
}

-(NSInteger)CIRCLE
{
	return DrawModeCircle;
}

-(NSInteger)RECTANGLE
{
	return DrawModeRectangle;
}

@end
