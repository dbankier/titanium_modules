/**
 * Titanium Paint Module
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiPaintPaintView.h"
#import "TiUtils.h"


@implementation TiPaintPaintView

- (id)init
{
	if ((self = [super init]))
	{
		drawMode = DrawModeCurve;
		strokeWidth = 5;
        strokeAlpha = 1;
        strokeDynamic = false;
        blurredEdges = false;
		strokeColor = CGColorRetain([[TiUtils colorValue:@"#000"] _color].CGColor);
        imageHistory = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
    [imageHistory release];
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
    CGContextBeginPath(UIGraphicsGetCurrentContext());
	CGPoint start = [(NSValue*)[pointsArray objectAtIndex:0] CGPointValue];
	CGContextMoveToPoint(UIGraphicsGetCurrentContext(), start.x, start.y);
	CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
}

- (void)drawCircle:(CGPoint)currentPoint
{
    CGPoint start = [(NSValue*)[pointsArray objectAtIndex:0] CGPointValue];
    CGRect rectangle = CGRectMake( start.x, start.y, currentPoint.x - start.x , currentPoint.y - start.y);
    CGContextAddEllipseInRect(UIGraphicsGetCurrentContext(), rectangle);
}

- (void)drawRectangle: (CGPoint)currentPoint
{
    CGPoint start = [(NSValue*)[pointsArray objectAtIndex:0] CGPointValue];
    CGRect rectangle = CGRectMake( start.x, start.y, currentPoint.x - start.x , currentPoint.y - start.y);
    CGContextAddRect(UIGraphicsGetCurrentContext(), rectangle);
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
- (void)drawBezierCurve {
    
    CGContextBeginPath(UIGraphicsGetCurrentContext());
    CGFloat x0,y0,x1,y1,x2,y2,x3,y3;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path,NULL,[[pointsArray objectAtIndex:0] CGPointValue].x,[[pointsArray objectAtIndex:0] CGPointValue].y);
    
    int pLength = [pointsArray count];
    
    if(pLength >= 4){
        x3 = [(NSValue*)[pointsArray objectAtIndex:pLength-1] CGPointValue].x;
        y3 = [(NSValue*)[pointsArray objectAtIndex:pLength-1] CGPointValue].y;	
        
        x2 = [(NSValue*)[pointsArray objectAtIndex:pLength-2] CGPointValue].x;
        y2 = [(NSValue*)[pointsArray objectAtIndex:pLength-2] CGPointValue].y;						
        
        x1 = [(NSValue*)[pointsArray objectAtIndex:pLength-3] CGPointValue].x;
        y1 = [(NSValue*)[pointsArray objectAtIndex:pLength-3] CGPointValue].y;						
        
        x0 = [(NSValue*)[pointsArray objectAtIndex:pLength-4] CGPointValue].x;
        y0 = [(NSValue*)[pointsArray objectAtIndex:pLength-4] CGPointValue].y;						
        
        
        double smooth_value = 0.8;
        
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
        
        
        double step_limit = 0.4; // limit for dynamic width step
        double width_limit = 0.6; // smallest percentage change in width
        
        double width = strokeWidth * (1 - ((len1 -10)/40 * (1-width_limit)));
        if (lastWidth > -1) {
            if (abs(width - lastWidth) > step_limit) {
                if (width > lastWidth) {
                    width = lastWidth + step_limit;
                } else {
                    width = lastWidth -step_limit;
                }
            }
        }
        
        if (width > strokeWidth || !strokeDynamic) {
            width = strokeWidth;
        } else if (width < strokeWidth * width_limit) {
            width = strokeWidth * width_limit;
        }
        
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), width);
        lastWidth = width;
        if (blurredEdges) {
            CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0.0, 0.0), 2.0, strokeColor);
        }
        lastWidth = width;

    }
	CGContextAddPath(UIGraphicsGetCurrentContext(), path);
	CGContextSetShouldAntialias(UIGraphicsGetCurrentContext(),YES); 
}	

- (void)drawAt:(CGPoint)currentPoint endDraw:(bool)endDraw
{
	UIView *view = [self imageView];
	UIGraphicsBeginImageContext(view.frame.size);
	UIImage *targetImage = drawImage.image;
	if ((drawMode == DrawModeStraightLine || drawMode == DrawModeCircle || drawMode == DrawModeRectangle) && targetImage != nil){
		if ([imageHistory count] == 0) {
            targetImage = nil;
        } else {
            targetImage = [imageHistory objectAtIndex:[imageHistory count] -1];
        }
	}
	[targetImage drawInRect:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)];
    if (drawMode == DrawModeErase) {
        [self drawEraserLine:currentPoint];
    } else {
        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), strokeWidth);
        CGContextSetAlpha(UIGraphicsGetCurrentContext(), strokeAlpha);
        CGContextSetStrokeColorWithColor(UIGraphicsGetCurrentContext(), strokeColor);
        
        if (drawMode == DrawModeCurve && (!endDraw || [pointsArray count] > 3)) {
            [self drawBezierCurve];
        } else if (drawMode == DrawModeCircle) {
            [self drawCircle:currentPoint];
        } else if (drawMode == DrawModeRectangle) {
            [self drawRectangle:currentPoint];
        } else {
            [self drawSolidLine:currentPoint];
        }
    }
    CGContextStrokePath(UIGraphicsGetCurrentContext());
	drawImage.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	lastPoint = currentPoint;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
    lastWidth = -1;
	[super touchesBegan:touches withEvent:event];
    if (self.imageView.image != nil) {
        [imageHistory addObject:[self.imageView.image retain]];
	}
	UITouch *touch = [touches anyObject];
	lastPoint = [touch locationInView:[self imageView]];
	pointsArray = [[NSMutableArray arrayWithObject:[NSValue valueWithCGPoint:lastPoint]] retain];
	[self drawAt:lastPoint endDraw:false];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesMoved:touches withEvent:event];
	
	UITouch *touch = [touches anyObject];	
	CGPoint currentPoint = [touch locationInView:[self imageView]];
	[pointsArray addObject:[NSValue valueWithCGPoint:currentPoint]];
    [self drawAt:currentPoint endDraw:false];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[super touchesEnded:touches withEvent:event];
	UITouch *touch = [touches anyObject];	
	CGPoint currentPoint = [touch locationInView:[self imageView]];
	[self drawAt:currentPoint endDraw:true];
	[pointsArray release];
	
}




#pragma mark Public APIs



-(void) setDrawMode_:(id)mode
{
    drawMode = [TiUtils intValue:mode];
}

- (void)setStrokeWidth_:(id)width
{
	strokeWidth = [TiUtils floatValue:width];
}

- (void)setStrokeDynamic_:(id)value
{
    strokeDynamic = [TiUtils boolValue:value];
}

- (void) setBlurredEdges_: (id)value
{
    blurredEdges = [TiUtils boolValue:value];
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

- (void)undo:(id)args
{
    if ([imageHistory count] > 0)
	{
		self.imageView.image = [imageHistory objectAtIndex:[imageHistory count] -1];
        [imageHistory removeObjectAtIndex:[imageHistory count] -1];
	} else if (drawImage!=nil)
	{
		drawImage.image = nil;
	}
}



- (void)clear:(id)args
{
	if (drawImage!=nil)
	{
		drawImage.image = nil;
	}
}

@end
