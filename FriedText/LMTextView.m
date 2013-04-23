//
//  LMTextField.m
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import "LMTextView.h"
#import "LMTextField.h"

#import "LMCompletionView.h"
#import "LMCompletionTableView.h"

#import <QuartzCore/QuartzCore.h>

#import "NSView+CocoaExtensions.h"

#import "jsmn.h"

#import "NSArray+KeyPath.h"

#import "NSMutableAttributedString+CocoaExtensions.h"

#import "LMTokenAttachmentCell.h"
#import "LMTextAttachmentCell.h"

#import "LMFriedTextDefaultColors.h"

#warning Make a smart system to force users to allow rich text if using tokens, while blocking rich text input if needed

@interface LMTextView () {
	NSRect _oldBounds;
}

@property (strong, nonatomic) NSTimer* timer;

@property (strong, nonatomic, readwrite) NSMutableArray* textAttachmentCellClasses;

@end



@implementation LMTextView

#pragma mark - Initializers / Setup

- (void)_setup
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:self.enclosingScrollView.contentView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:self.enclosingScrollView.contentView];
	
	NSColor* baseColor = [NSColor colorWithCalibratedRed:93.f/255.f green:72.f/255.f blue:55.f/255.f alpha:1.f];
	[self setTextColor:baseColor];
	
	self.useTemporaryAttributesForSyntaxHighlight = YES;
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

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Accessors

- (void)setParser:(id<LMTextParser>)parser
{
	[self willChangeValueForKey:@"parser"];
	_parser = parser;
	__unsafe_unretained LMTextView* textView = self;
	[_parser setStringBlock:^NSString *{
		return [textView string];
	}];
	[_parser invalidateString];
	[self didChangeValueForKey:@"parser"];
}

- (NSMutableArray *)textAttachmentCellClasses
{
	if (_textAttachmentCellClasses == nil) {
		_textAttachmentCellClasses = [NSMutableArray arrayWithObjects:
									  [NSTextAttachmentCell class],
									  [LMTokenAttachmentCell class],
									  nil];
	}
	return _textAttachmentCellClasses;
}

#pragma mark - Observers / View Events

- (BOOL)becomeFirstResponder
{
	[self highlightSyntax:nil];
	return [super becomeFirstResponder];
}

- (void)textStorageDidProcessEditing:(NSNotification*)notification
{
	[self.parser invalidateString];
}

- (void)boundsDidChange:(NSNotification*)notification
{
	NSAssert([[NSThread currentThread] isMainThread], @"Not main thread");

	if (_optimizeHighlightingOnScrolling) {
		if (self.timer != nil) {
			[self.timer invalidate];
			self.timer = nil;
		}
		self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(highlightSyntax:) userInfo:@(1) repeats:NO];
	}
	else {
		[self highlightSyntax:nil];
	}
}

- (void)textDidChange:(NSNotification *)notification
{
	if (_optimizeHighlightingOnEditing) {
		if (self.timer != nil) {
			[self.timer invalidate];
			self.timer = nil;
		}
		self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(highlightSyntax:) userInfo:@(1) repeats:NO];
	}
	else {
		[self highlightSyntax:nil];
	}
}

#pragma mark - Pasteboard

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
	NSData* data = [pboard dataForType:type];
	if (!data) {
		return NO;
	}
	
	NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithData:data options:nil documentAttributes:nil error:NULL];
	if (!attributedString) {
		return NO;
	}
	
	[attributedString enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, [attributedString length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
		if (value) {
			NSTextAttachment* textAttachment = value;
			textAttachment.attachmentCell = [self textAttachmentCellForTextAttachment:textAttachment];
		}
	}];
	
	if ([self shouldChangeTextInRange:[self selectedRange] replacementString:[attributedString string]]) {
		[[self textStorage] replaceCharactersInRange:[self selectedRange] withAttributedString:attributedString];
		[self didChangeText];
		
		return YES;
	}
	
	return NO;
}

#pragma mark - Helpers

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

#pragma mark - Mouse Events

- (void)mouseMoved:(NSEvent *)theEvent {
    NSLayoutManager *layoutManager = [self layoutManager];
    
    // Remove any existing coloring.
    [layoutManager removeTemporaryAttribute:NSUnderlineStyleAttributeName forCharacterRange:NSMakeRange(0, [[self textStorage] length])];
	
	BOOL needsCursor = NO;
	
	NSUInteger charIndex = [self charIndexForPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
    if (charIndex != NSNotFound) {
		if (self.parser) {
			NSRange tokenRange;
			[self.parser keyPathForObjectAtRange:NSMakeRange(charIndex, 1) objectRange:&tokenRange];
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
			NSArray* path = [self.parser keyPathForObjectAtRange:NSMakeRange(charIndex, 1) objectRange:&tokenRange];
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

#pragma mark - Syntax Highlighting

- (void)highlightSyntax:(id)sender
{
	if ([[sender class] isSubclassOfClass:[NSTimer class]] &&
		[[(NSTimer*)sender userInfo] isEqual:@(1)]) {
		return;
	}
	
	_oldBounds = self.enclosingScrollView.contentView.bounds;
	
	NSLayoutManager *layoutManager = [self layoutManager];
	
	NSRange characterRange;
	if ([self isFieldEditor]) {
		characterRange = NSMakeRange(0, [self.textStorage.string length]);
	}
	else {
		NSRange glyphRange = [self.layoutManager glyphRangeForBoundingRect:self.enclosingScrollView.documentVisibleRect inTextContainer:self.textContainer];
		characterRange = [self.layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
	}
	
	NSTextStorage* textStorage = [self textStorage];
	
	if (_useTemporaryAttributesForSyntaxHighlight) {
		[layoutManager removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:NSMakeRange(0, [self.textStorage.string length])];
	}
	else {
		[textStorage beginEditing];
		
		[textStorage removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, [self.textStorage.string length])];
	}
	
	BOOL usingDelegate = [self.delegate respondsToSelector:@selector(textView:attributesForTextWithParser:tokenMask:atRange:)];
	
	[[self parser] applyAttributesInRange:characterRange withBlock:^(NSUInteger tokenTypeMask, NSRange range) {
		
		NSDictionary* attributes = nil;
		if (usingDelegate) {
			attributes = [(id<LMTextViewDelegate>)self.delegate textView:self attributesForTextWithParser:[self parser] tokenMask:tokenTypeMask atRange:range];
		}
		
		if (attributes == nil) {
			NSColor* color = nil;
			switch (tokenTypeMask & LMTextParserTokenTypeMask) {
				case LMTextParserTokenTypeBoolean:
					color = LMFriedTextDefaultColorPrimitive;
					break;
				case LMTextParserTokenTypeNumber:
					color = LMFriedTextDefaultColorPrimitive;
					break;
				case LMTextParserTokenTypeString:
					color = LMFriedTextDefaultColorString;
					break;
				case LMTextParserTokenTypeOther:
					color = LMFriedTextDefaultColorPrimitive;
					break;
			}
			attributes = @{NSForegroundColorAttributeName:color};
		}
		
		if (_useTemporaryAttributesForSyntaxHighlight) {
			[layoutManager addTemporaryAttributes:attributes forCharacterRange:range];
		}
		else {
			[textStorage addAttributes:attributes range:range];
		}
	}];
	
	if (!_useTemporaryAttributesForSyntaxHighlight) {
		[textStorage endEditing];
	}
}

#pragma mark - Text Attachments

- (id<NSTextAttachmentCell>)textAttachmentCellForTextAttachment:(NSTextAttachment *)textAttachment
{
	__block id<NSTextAttachmentCell> textAttachmentCell = nil;
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(textview:textAttachmentCellForTextAttachment:)]) {
		textAttachmentCell = [(id<LMTextViewDelegate>)self.delegate textview:self textAttachmentCellForTextAttachment:textAttachment];
	}
	
	if (textAttachmentCell == nil) {
		[[self textAttachmentCellClasses] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if ([obj respondsToSelector:@selector(textAttachmentCellWithTextAttachment:)]) {
				textAttachmentCell = [(Class<LMTextAttachmentCell>)obj textAttachmentCellWithTextAttachment:textAttachment];
			}
			*stop = !!textAttachmentCell;
		}];
	}
	
	return textAttachmentCell;
}

#pragma mark - Completion

- (NSRange)rangeForUserCompletion
{
	if (self.parser) {
		NSRange range = {NSNotFound, 0};
		[self.parser keyPathForObjectAtRange:self.selectedRange objectRange:&range];
		
		if ([[self string] length] == 0 && range.location == NSNotFound) {
			range = NSMakeRange(0, 0);
		}
		
		return range;
	}
	else {
		return [super rangeForUserCompletion];
	}
}

@end
