//
//  LMFoldingTextAttachmentCell.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/6/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMFoldingTextAttachmentCell.h"

@interface LMFoldingTextAttachmentCell ()

@property (nonatomic) BOOL highlighted;

@end

@implementation LMFoldingTextAttachmentCell

- (NSSize)cellSize
{
	return NSMakeSize(20.f, 13.f);
}

- (NSPoint)cellBaselineOffset
{
	return NSMakePoint(-1.f, -3.f);
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[self drawWithFrame:cellFrame inView:controlView characterIndex:NSNotFound layoutManager:nil];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView characterIndex:(NSUInteger)charIndex
{
	[self drawWithFrame:cellFrame inView:controlView characterIndex:charIndex layoutManager:nil];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView characterIndex:(NSUInteger)charIndex layoutManager:(NSLayoutManager *)layoutManager
{
//	NSLog(@"Draw");
	
	NSColor* bgColor = [NSColor colorWithCalibratedRed:0.f/255.f green:179.f/255.f blue:182.f/255.f alpha:1.f];
	NSColor* borderColor = [NSColor colorWithCalibratedRed:0.f/255.f green:116.f/255.f blue:114.f/255.f alpha:1.f];
	
	NSRect frame = cellFrame;
	CGFloat radius = ceilf([self cellSize].height / 2.f);
	NSBezierPath* roundedRectanglePath = [NSBezierPath bezierPathWithRoundedRect: NSMakeRect(NSMinX(frame) + 0.5, NSMinY(frame) + 0.5, NSWidth(frame) - 1, NSHeight(frame) - 1) xRadius: radius yRadius: radius];
	[(_highlighted ? [NSColor purpleColor] : bgColor) setFill];
	[roundedRectanglePath fill];
	[borderColor setStroke];
	[roundedRectanglePath setLineWidth: 1];
	[roundedRectanglePath stroke];
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	self.highlighted = flag;
	[controlView setNeedsDisplayInRect:cellFrame];
	NSLog(@"Highlight");
}

- (BOOL)wantsToTrackMouse
{
	return YES;
}

- (BOOL)wantsToTrackMouseForEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView atCharacterIndex:(NSUInteger)charIndex
{
	return YES;
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag
{
	return [self trackMouse:theEvent inRect:cellFrame ofView:controlView atCharacterIndex:NSNotFound untilMouseUp:flag];
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView atCharacterIndex:(NSUInteger)charIndex untilMouseUp:(BOOL)flag
{
	NSLog(@"Mouse");
	return YES;
}

@end
