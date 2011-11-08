/**
 * Titanium Paint Module
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiPaintPaintView.h"
#import "TiUtils.h"

@interface TiPaintPaintView ()
-(void)drawBezier;
@end


@implementation TiPaintPaintView

- (id)init
{
	if ((self = [super init]))
	{
		useBezierCorrection = false;
		straightLineMode = false;
		strokeWidth = 5;
        strokeAlpha = 1;
		strokeColor = CGColorRetain([[TiUtils colorValue:@"#000"] _color].CGColor);
	}
	return self;
}

- (void)dealloc
{
	RELEASE_TO_NIL(drawImage);
	CGColorRelease(strokeColor);
	[super dealloc];
}

- (void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
	[super frameSizeChanged:frame bounds:bounds];
	if (drawImage!=nil)
	{
		[drawImage setFrame:bounds];
	}
}

- (UIImageView*)imageView
{
	if (drawImage==nil)
	{
		drawImage = [[UIImageView alloc] initWithImage:nil];
		drawImage.frame = [self bounds];
		[self addSubview:drawImage];
	}
	return drawImage;
}

- (void)drawSolidLine:(CGPoint)currentPoint
{
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), strokeWidth);
    CGContextSetAlpha(UIGraphicsGetCurrentContext(), strokeAlpha);
    CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), strokeColor);
    CGContextBeginPath(UIGraphicsGetCurrentContext());
	CGPoint start = lastPoint;
	if (straightLineMode) {
		start = [(NSValue*)[pointsArray objectAtIndex:0] CGPointValue];
	}
	CGContextMoveToPoint(UIGraphicsGetCurrentContext(), start.x, start.y);
	CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
}

- (void)drawEraserLine:(CGPoint)currentPoint
{
    // This is an implementation of Bresenham's line algorithm
    int x0 = currentPoint.x, y0 = currentPoint.y;
    int x1 = lastPoint.x, y1 = lastPoint.y;
    int dx = abs(x0-x1), dy = abs(y0-y1);
    int sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
    int err = dx - dy, e2;
    
    while(true)
    {
        CGContextClearRect(UIGraphicsGetCurrentContext(), CGRectMake(x0, y0, strokeWidth, strokeWidth));
        if (x0 == x1 && y0 == y1)
        {
            break;
        }
        e2 = 2 * err;
        if (e2 > -dy)
        {
            err -= dy;
            x0 += sx;
        }
        if (e2 < dx)
        {
            err += dx;
            y0 += sy;
        }
    }
}

- (void)drawAt:(CGPoint)currentPoint
{
	UIView *view = [self imageView];
	UIGraphicsBeginImageContext(view.frame.size);
	UIImage *targetImage = drawImage.image;
	if (straightLineMode && !erase){
		targetImage = cleanImage;
	}
	[targetImage drawInRect:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)];
    if (erase) {
        [self drawEraserLine:currentPoint];
    }
    else {
        [self drawSolidLine:currentPoint];
    }
    CGContextStrokePath(UIGraphicsGetCurrentContext());
	drawImage.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	lastPoint = currentPoint;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesBegan:touches withEvent:event];
	cleanImage = [self.imageView.image retain];
	
	UITouch *touch = [touches anyObject];
	lastPoint = [touch locationInView:[self imageView]];
	pointsArray = [[NSMutableArray arrayWithObject:[NSValue valueWithCGPoint:lastPoint]] retain];
	//Add it twice otherwise first point is dropped... (a hack?)
	[pointsArray addObject:[NSValue valueWithCGPoint:lastPoint]];
	[self drawAt:lastPoint];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesMoved:touches withEvent:event];
	
	UITouch *touch = [touches anyObject];	
	CGPoint currentPoint = [touch locationInView:[self imageView]];
	[self drawAt:currentPoint];
	[pointsArray addObject:[NSValue valueWithCGPoint:currentPoint]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesEnded:touches withEvent:event];
	UITouch *touch = [touches anyObject];	
	CGPoint currentPoint = [touch locationInView:[self imageView]];
	[self drawAt:currentPoint];
	[pointsArray addObject:[NSValue valueWithCGPoint:currentPoint]];
	//Add it twice otherwise last point is dropped... (a hack?)
	[pointsArray addObject:[NSValue valueWithCGPoint:currentPoint]];
	
	// Only smooth if there are more than 4 points (since we double up at start and end)
	if (!erase && !straightLineMode && useBezierCorrection && [pointsArray count]>4) {
		[self drawBezier];
	}
	[pointsArray release];
	[cleanImage release];
}

// Bezier Code nearly entirely taken from   : https://github.com/levinunnink/Smooth-Line-View/
// "Clean Image" correction idea taken from : http://tonyngo.net/2011/09/smooth-line-drawing-in-ios/
- (void)drawBezier {
    UIGraphicsBeginImageContext(CGSizeMake(self.imageView.frame.size.width, self.imageView.frame.size.height));
    [cleanImage drawInRect:CGRectMake(0, 0, self.imageView.frame.size.width, self.imageView.frame.size.height)];
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(), strokeWidth);
	CGContextSetAlpha(UIGraphicsGetCurrentContext(), strokeAlpha);
    CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), strokeColor);
    CGContextBeginPath(UIGraphicsGetCurrentContext());
	
    int curIndex = 0;
    CGFloat x0,y0,x1,y1,x2,y2,x3,y3;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path,NULL,[[pointsArray objectAtIndex:0] CGPointValue].x,[[pointsArray objectAtIndex:0] CGPointValue].y);
	
    for(NSValue *v in pointsArray){
        
        if(curIndex >= 4){
            for (int i=curIndex;i>=curIndex-4;i--) {
                int step = (curIndex-i);
                switch (step) {
                    case 0:
                        x3 = [(NSValue*)[pointsArray objectAtIndex:i-1] CGPointValue].x;
                        y3 = [(NSValue*)[pointsArray objectAtIndex:i-1] CGPointValue].y;	
                        break;
                    case 1:
                        x2 = [(NSValue*)[pointsArray objectAtIndex:i-1] CGPointValue].x;
                        y2 = [(NSValue*)[pointsArray objectAtIndex:i-1] CGPointValue].y;						
                        break;
                    case 2:
                        x1 = [(NSValue*)[pointsArray objectAtIndex:i-1] CGPointValue].x;
                        y1 = [(NSValue*)[pointsArray objectAtIndex:i-1] CGPointValue].y;						
                        break;
                    case 3:
                        x0 = [(NSValue*)[pointsArray objectAtIndex:i-1] CGPointValue].x;
                        y0 = [(NSValue*)[pointsArray objectAtIndex:i-1] CGPointValue].y;						
                        break;	
                    default:
                        break;
                }			
            }
            
            
            double smooth_value = 0.5;
            
            double xc1 = (x0 + x1) / 2.0;
            double yc1 = (y0 + y1) / 2.0;
            double xc2 = (x1 + x2) / 2.0;
            double yc2 = (y1 + y2) / 2.0;
            double xc3 = (x2 + x3) / 2.0;
            double yc3 = (y2 + y3) / 2.0;
            
            double len1 = sqrt((x1-x0) * (x1-x0) + (y1-y0) * (y1-y0));
            double len2 = sqrt((x2-x1) * (x2-x1) + (y2-y1) * (y2-y1));
            double len3 = sqrt((x3-x2) * (x3-x2) + (y3-y2) * (y3-y2));
            
            double k1 = len1 / (len1 + len2);
            double k2 = len2 / (len2 + len3);
            
            double xm1 = xc1 + (xc2 - xc1) * k1;
            double ym1 = yc1 + (yc2 - yc1) * k1;
            
            double xm2 = xc2 + (xc3 - xc2) * k2;
            double ym2 = yc2 + (yc3 - yc2) * k2;
            
            // Resulting control points. Here smooth_value is mentioned
            // above coefficient K whose value should be in range [0...1].
            double ctrl1_x = xm1 + (xc2 - xm1) * smooth_value + x1 - xm1;
            double ctrl1_y = ym1 + (yc2 - ym1) * smooth_value + y1 - ym1;
            
            double ctrl2_x = xm2 + (xc2 - xm2) * smooth_value + x2 - xm2;
            double ctrl2_y = ym2 + (yc2 - ym2) * smooth_value + y2 - ym2;	
            
            CGPathMoveToPoint(path,NULL,x1,y1);
            CGPathAddCurveToPoint(path,NULL,ctrl1_x,ctrl1_y,ctrl2_x,ctrl2_y, x2,y2);
            CGPathAddLineToPoint(path,NULL,x2,y2);
        }
        curIndex++;
    }
	CGContextAddPath(UIGraphicsGetCurrentContext(), path);
    CGContextStrokePath(UIGraphicsGetCurrentContext());
	CGContextSetShouldAntialias(UIGraphicsGetCurrentContext(),YES);
    self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

}	

#pragma mark Public APIs

- (void)setEraseMode_:(id)value
{
	erase = [TiUtils boolValue:value];
}

- (void)setStraightLineMode_:(id)value
{
	straightLineMode = [TiUtils boolValue:value];
}

- (void)setStrokeWidth_:(id)width
{
	strokeWidth = [TiUtils floatValue:width];
}

- (void)setStrokeColor_:(id)value
{
	CGColorRelease(strokeColor);
	TiColor *color = [TiUtils colorValue:value];
	strokeColor = [color _color].CGColor;
	CGColorRetain(strokeColor);
}

- (void)setStrokeAlpha_:(id)alpha
{
    strokeAlpha = [TiUtils floatValue:alpha] / 255.0;
}

- (void)setImage_:(id)value
{
	UIImage *image = value==nil ? nil : [TiUtils image:value proxy:(TiProxy*)self.proxy];
	if (image!=nil)
	{
		self.imageView.image = image;
	}
	else
	{
		self.imageView.image=nil;
	}
}

- (void)setUseBezierCorrection_:(id)value
{
	useBezierCorrection = [TiUtils boolValue:value];
}

- (void)clear:(id)args
{
	if (drawImage!=nil)
	{
		drawImage.image = nil;
	}
}

@end
