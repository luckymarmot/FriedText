//
//  LMCompletionTableCellView.m
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import "LMCompletionTableCellView.h"
#import "LMCompletionTableView.h"

@implementation LMCompletionTableCellView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	LMCompletionTableView* tableView = (LMCompletionTableView*)self.superview.superview;
	LMCompletionTableCellView* selectedCell = tableView.selectedRow >= 0 ? [tableView viewAtColumn:0 row:tableView.selectedRow makeIfNecessary:NO] : nil;
	BOOL isSelected = selectedCell == self;
	
	//// Frames
	NSRect frame = self.bounds;
	
	//// Rectangle Drawing
	if (isSelected) {
		CGFloat hue = 214.f/360.f;
		BOOL isWindowActive = [[self window] isMainWindow];
		NSColor* color2 = [NSColor colorWithCalibratedHue:hue saturation:(isWindowActive ? 0.27f : 0.f) brightness:0.84f alpha:1.f];
		NSColor* color = [NSColor colorWithCalibratedHue:hue saturation:(isWindowActive ? 0.35f : 0.f) brightness:0.74f alpha:1.f];
		NSColor* strokeColor = [color2 shadowWithLevel: 0.45];
		
		NSGradient* gradient = [[NSGradient alloc] initWithStartingColor: color2 endingColor: color];
		
		NSBezierPath* rectanglePath = [NSBezierPath bezierPathWithRect:frame];
		[gradient drawInBezierPath: rectanglePath angle: -90];
		[strokeColor setStroke];
		[rectanglePath setLineWidth: 1];
		[rectanglePath stroke];
	}
	
	NSRect textRect = CGRectMake(10.f, 2.f, frame.size.width-15.f, frame.size.height-0.f);
	[NSGraphicsContext saveGraphicsState];
	if (isSelected) {
		NSShadow* shadow = [[NSShadow alloc] init];
		[shadow setShadowColor: [NSColor blackColor]];
		[shadow setShadowOffset: NSMakeSize(0.1, 0.1)];
		[shadow setShadowBlurRadius: 1];
		[shadow set];
	}
	
	NSColor* textColor = isSelected ? [NSColor whiteColor] : [NSColor blackColor];
	NSString* fontName = isSelected ? @"Menlo-Bold" : @"Menlo";
	
	NSMutableParagraphStyle* textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
	[textStyle setAlignment: NSLeftTextAlignment];
	
	NSMutableDictionary* textFontAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											   [NSFont fontWithName: fontName size: 11.f], NSFontAttributeName,
											   textColor, NSForegroundColorAttributeName,
											   textStyle, NSParagraphStyleAttributeName, nil];
	
	id<LMCompletionOption>completionOption = [self completionOption];
	if ([completionOption respondsToSelector:@selector(attributedStringValue)]) {
		NSMutableAttributedString* attributedString = [[completionOption attributedStringValue] mutableCopy];
		[attributedString addAttributes:textFontAttributes range:NSMakeRange(0, [attributedString length])];
		[attributedString drawInRect: textRect];
	}
	else {
		[[completionOption stringValue] drawInRect: textRect withAttributes: textFontAttributes];
	}
	
	
	[NSGraphicsContext restoreGraphicsState];
}

@end
