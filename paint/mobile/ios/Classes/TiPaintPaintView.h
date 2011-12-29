/**
 * Titanium Paint Module
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiUIView.h"
#import "TiPaintModule.h"



@interface TiPaintPaintView : TiUIView {
@private
	UIImageView *drawImage;
	CGPoint lastPoint;
	CGFloat strokeWidth;
	CGFloat strokeAlpha;
	CGColorRef strokeColor;
    bool strokeDynamic;
	DrawModeSelection drawMode;
	NSMutableArray *pointsArray;
    //NSMutableArray *imageHistory;
	UIImage *cleanImage;
}

@end
