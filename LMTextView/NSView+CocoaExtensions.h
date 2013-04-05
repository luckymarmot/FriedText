//
//  NSView+CocoaExtensions.h
//  Paw
//
//  Created by Micha Mazaheri on 11/24/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	LMViewResizeConstantTopMargin,
	LMViewResizeConstantBottomMargin,
} LMViewResizeConstantParameter;

@interface NSView (CocoaExtensions)

- (void)centerHorizontallyInContainer;
- (void)centerVerticallyInContainer;
- (void)centerInContainer;
- (void)setDistanceFromTop:(CGFloat)distanceFromTop;
- (void)setDistanceFromBottom:(CGFloat)distanceFromBottom;
- (CGFloat)distanceFromTop;
- (CGFloat)distanceFromBottom;

- (void)setWidth:(CGFloat)width;
- (void)setHeight:(CGFloat)height;
- (void)setHeight:(CGFloat)height constantParameter:(LMViewResizeConstantParameter)constantParameter;

- (void)setAnchorPoint:(CGPoint)anchorPoint;

@end

CGRect LMViewRectWithMargin(CGRect rect, CGFloat topMargin, CGFloat rightMargin, CGFloat bottomMargin, CGFloat leftMargin);
CGPoint LMViewRectGetMidPoint(CGRect rect);
CGRect LMViewRectCenteredInSuperRect(NSRect superRect, NSSize size, BOOL snapToPixel);
