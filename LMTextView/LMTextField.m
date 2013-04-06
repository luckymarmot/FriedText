//
//  LMTextField.m
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import "LMTextField.h"

#import "LMCompletionView.h"
#import "LMCompletionTableView.h"

#import <QuartzCore/QuartzCore.h>

#import "NSView+CocoaExtensions.h"

#import "jsmn.h"

#import "NSArray+KeyPath.h"

#define NUM_TOKENS 100024

@interface LMTextField () {
	BOOL _kIsProcessing;
	NSRect _oldBounds;
} /*<LMCompletionViewDelegate>*/

@property (strong, nonatomic) NSTimer* timer;

@end



@implementation LMTextField

- (void)awakeFromNib {
    [[self window] setAcceptsMouseMovedEvents:YES];
}

- (void)t
{
	[self.parser parseString:[self.textStorage string]];
}

- (void)boundsDidChange
{
	NSAssert([[NSThread currentThread] isMainThread], @"Not main thread");

	if (!_kIsProcessing) {
		if (self.timer != nil) {
			[self.timer invalidate];
			self.timer = nil;
		}
		self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_k:) userInfo:@(1) repeats:NO];
	}
}

- (void)textDidChange
{
	NSAssert([[NSThread currentThread] isMainThread], @"Not main thread");
	
	if (!_kIsProcessing) {
		if (self.timer != nil) {
			[self.timer invalidate];
			self.timer = nil;
		}
		self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_k:) userInfo:@(2) repeats:NO];
	}
}

- (void)_k:(NSTimer*)timer
{
	NSAssert([[NSThread currentThread] isMainThread], @"Not main thread");
	NSAssert(timer == self.timer, @"Weird timer");
	
	if ([timer.userInfo isEqual:@(1)] && NSEqualRects(self.enclosingScrollView.contentView.bounds, _oldBounds)) {
		return;
	}
	
	_oldBounds = self.enclosingScrollView.contentView.bounds;
	
	_kIsProcessing = YES;

	NSLayoutManager *layoutManager = [self layoutManager];
	
	NSColor* baseColor = [NSColor colorWithCalibratedRed:93.f/255.f green:72.f/255.f blue:55.f/255.f alpha:1.f];
	NSColor* primitiveColor = [NSColor colorWithCalibratedRed:160.f/255.f green:208.f/255.f blue:202.f/255.f alpha:1.f];
	NSColor* stringColor = [NSColor colorWithCalibratedRed:33.f/255.f green:82.f/255.f blue:116.f/255.f alpha:1.f];
	
	[self setTextColor:baseColor];
	
	NSRange glyphRange = [self.layoutManager glyphRangeForBoundingRect:self.enclosingScrollView.documentVisibleRect inTextContainer:self.textContainer];
//	NSRange characterRange = [self.textStorage editedRange];
	NSRange characterRange = [self.layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
//	NSRange characterRange = NSMakeRange(0, [self.textStorage.string length]);

	[layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:NSMakeRange(0, [self.textStorage.string length])];
	
	[self.parser applyAttributesInRange:characterRange withBlock:^(LMTextParserTokenType tokenType, NSRange range) {
		switch (tokenType) {
			case LMTextParserTokenTypeBoolean:
				[layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:primitiveColor forCharacterRange:range];
				break;
			case LMTextParserTokenTypeNumber:
				[layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:primitiveColor forCharacterRange:range];
				break;
			case LMTextParserTokenTypeString:
				[layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:stringColor forCharacterRange:range];
				break;
			case LMTextParserTokenTypeOther:
				[layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:primitiveColor forCharacterRange:range];
				break;
		}
	}];
	
	_kIsProcessing = NO;
}

- (void)mouseMoved:(NSEvent *)theEvent {
    NSLayoutManager *layoutManager = [self layoutManager];
    NSTextContainer *textContainer = [self textContainer];
    NSUInteger glyphIndex, charIndex, textLength = [[self textStorage] length];
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSRect glyphRect;
    
    // Remove any existing coloring.
    [layoutManager removeTemporaryAttribute:NSUnderlineStyleAttributeName forCharacterRange:NSMakeRange(0, textLength)];
    
    // Convert view coordinates to container coordinates
    point.x -= [self textContainerOrigin].x;
    point.y -= [self textContainerOrigin].y;
    
    // Convert those coordinates to the nearest glyph index
    glyphIndex = [layoutManager glyphIndexForPoint:point inTextContainer:textContainer];
    
    // Check to see whether the mouse actually lies over the glyph it is nearest to
    glyphRect = [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1) inTextContainer:textContainer];
    if (NSPointInRect(point, glyphRect)) {
        // Convert the glyph index to a character index
        charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
        
		NSRange tokenRange;
		
		NSArray* path = [self.parser keyPathForObjectAtCharIndex:charIndex correctedRange:&tokenRange];
        
		if (tokenRange.location != NSNotFound) {
			[layoutManager addTemporaryAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlinePatternDot | NSUnderlineStyleSingle | NSUnderlineByWordMask) forCharacterRange:tokenRange];
		}
		
		if (path) {
			NSLog(@"> %@", [path keyPathDescription]);
		}
    }
}

@end
