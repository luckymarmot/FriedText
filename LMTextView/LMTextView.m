//
//  LMTextField.m
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import "LMTextView.h"

#import "LMCompletionView.h"
#import "LMCompletionTableView.h"

#import <QuartzCore/QuartzCore.h>

#import "NSView+CocoaExtensions.h"

#import "jsmn.h"

#import "NSArray+KeyPath.h"

#define NUM_TOKENS 100024

@interface LMTextView () {
	BOOL _kIsProcessing;
	NSRect _oldBounds;
} /*<LMCompletionViewDelegate>*/

@property (strong, nonatomic) NSTimer* timer;

@end



@implementation LMTextView

- (void)_setup
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:self.enclosingScrollView.contentView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:self.enclosingScrollView.contentView];
	
	NSColor* baseColor = [NSColor colorWithCalibratedRed:93.f/255.f green:72.f/255.f blue:55.f/255.f alpha:1.f];
	[self setTextColor:baseColor];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self _setup];
	}
	return self;
}

- (id)init
{
	self = [super init];
	if (self) {
		[self _setup];
	}
	return self;
}

- (BOOL)becomeFirstResponder
{
	[self _k:nil];
	return [super becomeFirstResponder];
}

- (void)setParser:(id<LMTextParser>)parser
{
	[self willChangeValueForKey:@"parser"];
	_parser = parser;
	__unsafe_unretained LMTextView* textView = self;
	[_parser setStringBlock:^NSString *{
		return [textView string];
	}];
	[self didChangeValueForKey:@"parser"];
}

- (void)textStorageDidProcessEditing:(NSNotification*)notification
{
	[self.parser invalidateString];
}

- (void)boundsDidChange:(NSNotification*)notification
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

- (void)textDidChange:(NSNotification *)notification
{
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
	if ([timer.userInfo isEqual:@(1)] && NSEqualRects(self.enclosingScrollView.contentView.bounds, _oldBounds)) {
		return;
	}
	
	_oldBounds = self.enclosingScrollView.contentView.bounds;
	
	_kIsProcessing = YES;

	NSLayoutManager *layoutManager = [self layoutManager];
	
	NSColor* primitiveColor = [NSColor colorWithCalibratedRed:160.f/255.f green:208.f/255.f blue:202.f/255.f alpha:1.f];
	NSColor* stringColor = [NSColor colorWithCalibratedRed:33.f/255.f green:82.f/255.f blue:116.f/255.f alpha:1.f];
	
	NSRange characterRange;
	if ([self isFieldEditor]) {
		characterRange = NSMakeRange(0, [self.textStorage.string length]);
	}
	else {
		NSRange glyphRange = [self.layoutManager glyphRangeForBoundingRect:self.enclosingScrollView.documentVisibleRect inTextContainer:self.textContainer];
		characterRange = [self.layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
	}

	[layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:NSMakeRange(0, [self.textStorage.string length])];
	
	[self.parser applyAttributesInRange:characterRange withBlock:^(NSUInteger tokenTypeMask, NSRange range) {
		switch (tokenTypeMask & LMTextParserTokenTypeMask) {
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

- (NSUInteger)charIndexForPoint:(NSPoint)point
{
	NSLayoutManager *layoutManager = [self layoutManager];
	NSUInteger glyphIndex = 0;
    NSRect glyphRect;
	NSTextContainer *textContainer = [self textContainer];
	
	// Convert view coordinates to container coordinates
    point.x -= [self textContainerOrigin].x;
    point.y -= [self textContainerOrigin].y;
	
	// Convert those coordinates to the nearest glyph index
    glyphIndex = [layoutManager glyphIndexForPoint:point inTextContainer:textContainer];

	// Check to see whether the mouse actually lies over the glyph it is nearest to
    glyphRect = [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1) inTextContainer:textContainer];

	if (NSPointInRect(point, glyphRect)) {
		// Convert the glyph index to a character index
        return [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
	}
	else {
		return NSNotFound;
	}
}

- (void)mouseMoved:(NSEvent *)theEvent {
    NSLayoutManager *layoutManager = [self layoutManager];
    
    // Remove any existing coloring.
    [layoutManager removeTemporaryAttribute:NSUnderlineStyleAttributeName forCharacterRange:NSMakeRange(0, [[self textStorage] length])];
	
	BOOL needsCursor = NO;
	
	NSUInteger charIndex = [self charIndexForPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
    if (charIndex != NSNotFound) {
		if (self.parser) {
			NSRange tokenRange;
			[self.parser keyPathForObjectAtCharIndex:charIndex correctedRange:&tokenRange];
			if (tokenRange.location != NSNotFound) {
				[layoutManager addTemporaryAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlinePatternDot | NSUnderlineStyleSingle) forCharacterRange:tokenRange];
				
				needsCursor = YES;
			}
		}
    }
	
	if (needsCursor) {
		if ([NSCursor currentCursor] != [NSCursor pointingHandCursor] && self.changeCursorOnTokens) {
			[[NSCursor pointingHandCursor] push];
		}
	}
	else {
		[[NSCursor pointingHandCursor] pop];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSLayoutManager *layoutManager = [self layoutManager];
	NSTextContainer *textContainer = [self textContainer];
	NSUInteger charIndex = [self charIndexForPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
    if (charIndex != NSNotFound) {
		if ([[self.textStorage string] characterAtIndex:charIndex] == 0xFFFC) {
			
		}
		else if (self.parser) {
			NSRange tokenRange;
			NSArray* path = [self.parser keyPathForObjectAtCharIndex:charIndex correctedRange:&tokenRange];
			NSRect bounds = [layoutManager boundingRectForGlyphRange:tokenRange inTextContainer:textContainer];
			
			if (tokenRange.location != NSNotFound) {
				if ([self.delegate respondsToSelector:@selector(textView:mouseDownForTokenAtRange:withBounds:keyPath:)]) {
					[(id<LMTextViewDelegate>)self.delegate textView:self mouseDownForTokenAtRange:tokenRange withBounds:bounds keyPath:path];
				}
				return;
			}
		}
    }
	
	if ([self.delegate respondsToSelector:@selector(mouseDownOutsideTokenInTextView:)]) {
		[(id<LMTextViewDelegate>)self.delegate mouseDownOutsideTokenInTextView:self];
	}
	
	[super mouseDown:theEvent];
}

@end
