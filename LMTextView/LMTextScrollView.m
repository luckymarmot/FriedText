//
//  LMTextScrollView.m
//  Paw
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import "LMTextScrollView.h"

#import "LMTextView.h"

@implementation LMTextScrollView

#ifdef __DISABLED__
- (void)drawRect:(NSRect)dirtyRect
{
	//// General Declarations
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	CGRect frame = CGRectMake(self.bounds.origin.x + 0.5f, self.bounds.origin.y + 0.5f, self.bounds.size.width - 1.f, self.bounds.size.height-2.f);
	
	//// Rounded Rectangle Drawing
	NSColor* color2 = [NSColor colorWithCalibratedWhite:1.f alpha:1.f];
	NSColor* color = [NSColor colorWithCalibratedWhite:0.90f alpha:1.f];
	NSColor* strokeColor = [color2 shadowWithLevel: 0.4f];
	if ([(LMTextField*)self.documentView enabled] == NO) {
		color = [NSColor colorWithCalibratedWhite:0.98f alpha:1.f];
		strokeColor = [color2 shadowWithLevel: 0.1f];
	}
	
	NSGradient* gradient = [[NSGradient alloc] initWithColorsAndLocations:
							color2, 0.8f,
							color, 1.0f,
							nil];
	
	NSShadow* shadow = [[NSShadow alloc] init];
	[shadow setShadowColor: [NSColor whiteColor]];
	[shadow setShadowOffset: NSMakeSize(0.1, -1.1)];
	[shadow setShadowBlurRadius: 1];
	
	CGFloat radius = 4.f;
	
	NSBezierPath* roundedRectanglePath = [NSBezierPath bezierPathWithRoundedRect: frame xRadius: radius yRadius: radius];
	[NSGraphicsContext saveGraphicsState];
	[shadow set];
	CGContextBeginTransparencyLayer(context, NULL);
	[gradient drawInBezierPath: roundedRectanglePath angle: -90];
	CGContextEndTransparencyLayer(context);
	[NSGraphicsContext restoreGraphicsState];
	
	[strokeColor setStroke];
	[roundedRectanglePath setLineWidth: 1];
	[roundedRectanglePath stroke];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	[self.nextResponder scrollWheel:theEvent];
}
#endif

@end
