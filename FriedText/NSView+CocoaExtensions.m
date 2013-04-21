//
//  NSView+CocoaExtensions.m
//  Paw
//
//  Created by Micha Mazaheri on 11/24/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import "NSView+CocoaExtensions.h"

@implementation NSView (CocoaExtensions)

- (void)centerHorizontallyInContainer
{
	[self setFrameOrigin:NSMakePoint((self.superview.bounds.size.width - self.frame.size.width) / 2, self.frame.origin.y)];
}

- (void)centerVerticallyInContainer
{
	[self setFrameOrigin:NSMakePoint(self.frame.origin.x, (self.superview.bounds.size.height - self.frame.size.height) / 2)];
}

- (void)centerInContainer
{
	[self centerHorizontallyInContainer];
	[self centerVerticallyInContainer];
}

- (void)setDistanceFromTop:(CGFloat)distanceFromTop
{
	[self setFrameOrigin:NSMakePoint(self.frame.origin.x, self.superview.bounds.size.height - self.frame.size.height - distanceFromTop)];
}

- (void)setDistanceFromBottom:(CGFloat)distanceFromBottom
{
	[self setFrameOrigin:NSMakePoint(self.frame.origin.x, distanceFromBottom)];
}

- (CGFloat)distanceFromBottom
{
	return self.frame.origin.y;
}

- (CGFloat)distanceFromTop
{
	return self.superview.bounds.size.height - self.frame.size.height - self.frame.origin.y;
}

- (void)setWidth:(CGFloat)width
{
	[self setFrameSize:NSMakeSize(width, self.frame.size.height)];
}

- (void)setHeight:(CGFloat)height
{
	[self setFrameSize:NSMakeSize(self.frame.size.width, height)];
}

- (void)setHeight:(CGFloat)height constantParameter:(LMViewResizeConstantParameter)constantParameter
{
	switch (constantParameter) {
		case LMViewResizeConstantBottomMargin:
			[self setFrameSize:NSMakeSize(self.frame.size.width, height)];
			break;
		case LMViewResizeConstantTopMargin:
		{
			CGFloat distanceFromTop = [self distanceFromTop];
			[self setFrameSize:NSMakeSize(self.frame.size.width, height)];
			[self setDistanceFromTop:distanceFromTop];
		}
			break;
	}
}

- (void)setAnchorPoint:(CGPoint)anchorPoint
{
    CGPoint newPoint = CGPointMake(self.bounds.size.width * anchorPoint.x, self.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(self.bounds.size.width * self.layer.anchorPoint.x, self.bounds.size.height * self.layer.anchorPoint.y);
	
	//    newPoint = CGPointApplyAffineTransform(newPoint, self.transform);
	//    oldPoint = CGPointApplyAffineTransform(oldPoint, self.transform);
	
    CGPoint position = self.layer.position;
	
    position.x -= oldPoint.x;
    position.x += newPoint.x;
	
    position.y -= oldPoint.y;
    position.y += newPoint.y;
	
    self.layer.position = position;
    self.layer.anchorPoint = anchorPoint;
}

@end

CGRect LMViewRectWithMargin(CGRect rect, CGFloat topMargin, CGFloat rightMargin, CGFloat bottomMargin, CGFloat leftMargin)
{
	return CGRectMake(NSMinX(rect) + leftMargin, NSMinY(rect) + bottomMargin, NSWidth(rect) - leftMargin - rightMargin, NSHeight(rect) - topMargin - bottomMargin);
}

CGPoint LMViewRectGetMidPoint(CGRect rect)
{
	return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CGRect LMViewRectCenteredInSuperRect(NSRect superRect, NSSize size, BOOL snapToPixel)
{
	if (snapToPixel) {
		CGSize roundedSize = CGSizeMake(round(size.width),
										round(size.height));
		return CGRectMake(round(superRect.origin.x + (superRect.size.width - roundedSize.width)/2),
						  round(superRect.origin.y + (superRect.size.height - roundedSize.height)/2),
						  roundedSize.width,
						  roundedSize.height);
	}
	else {
		return CGRectMake(superRect.origin.x + (superRect.size.width - size.width)/2,
						  superRect.origin.y + (superRect.size.height - size.height)/2,
						  size.width,
						  size.height);
	}
}
