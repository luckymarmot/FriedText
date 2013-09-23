//
//  LMTextView.m
//  LMTextView
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import "LMTextView.h"
#import "LMTextField.h"

#import <QuartzCore/QuartzCore.h>

#import "NSView+CocoaExtensions.h"

#import "jsmn.h"

#import "NSArray+KeyPath.h"

#import "NSMutableAttributedString+CocoaExtensions.h"

#import "LMTokenAttachmentCell.h"
#import "LMTextAttachmentCell.h"

#import "LMFriedTextDefaultColors.h"

#import "LMCompletionOption.h"
#import "NSString+LMCompletionOption.h"
#import "LMCompletionView.h"

#define NSLog(...)

/* Pasteboard Constant Values:
 * NSPasteboardTypeRTFD: com.apple.flat-rtfd
 * kUTTypeFlatRTFD: com.apple.flat-rtfd
 * NSRTFDPboardType: NeXT RTFD pasteboard type
 */

#warning Make a smart system to force users to allow rich text if using tokens, while blocking rich text input if needed

typedef enum {
	LMCompletionEventTextDidChange,
	LMCompletionEventResignFirstResponder,
	LMCompletionEventSystemCompletion,
	LMCompletionEventFinalCompletionInserted,
	LMCompletionEventEscapeKey,
} LMCompletionEventType;

@interface LMTextView () <LMCompletionViewDelegate> {
	NSRect _oldBounds;
	NSRange _completionRange;
	NSMutableAttributedString* _originalStringBeforeCompletion;
	id _insertedString;
	BOOL _handlingCompletion;
	LMCompletionView* _completionView;
	NSWindow* _completionWindow;
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
	
	_completionRange.location = NSNotFound;
	_originalStringBeforeCompletion = nil;
	_insertedString = nil;
	_handlingCompletion = NO;
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

- (NSDictionary *)textAttributes
{
	return @{
		  NSFontAttributeName:[self font] ?: [NSFont systemFontOfSize:[NSFont systemFontSize]],
	NSForegroundColorAttributeName:[self textColor] ?: [NSColor blackColor],
	};
}

- (BOOL)setString:(NSString *)string isUserInitiated:(BOOL)isUserInitiated
{
	BOOL shouldSet = YES;
	
	if (isUserInitiated) {
		shouldSet = [self shouldChangeTextInRange:NSMakeRange(0, [[self string] length]) replacementString:string];
	}
	
	if (shouldSet) {
		[self setString:string];
		[self didChangeText];
	}
	
	return shouldSet;
}

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

+ (NSArray*)defaultTextAttachmentCellClasses
{
	return [NSArray arrayWithObjects:
			[NSTextAttachmentCell class],
			[LMTokenAttachmentCell class],
			nil];
}

- (NSMutableArray *)textAttachmentCellClasses
{
	if (_textAttachmentCellClasses == nil) {
		_textAttachmentCellClasses = [NSMutableArray arrayWithArray:[[self class] defaultTextAttachmentCellClasses]];
	}
	return _textAttachmentCellClasses;
}

#pragma mark - Observers / View Events

- (BOOL)becomeFirstResponder
{
	[self highlightSyntax:nil];
	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
	// End autocompletion
	if (self.enableAutocompletion) {
		[self _handleCompletion:LMCompletionEventResignFirstResponder];
	}
	
	return [super resignFirstResponder];
}

// Always called before textDidChange:
- (void)textStorageDidProcessEditing:(NSNotification*)notification
{
//	NSLog(@"textStorageDidProcessEditing:");
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
//	NSLog(@"textDidChange:");
	
	// If Field Editor, enforce field's attributes
	if ([self isFieldEditor] && [self.delegate isKindOfClass:[LMTextField class]]) {
		LMTextField* textField = (LMTextField*)[self delegate];
		NSTextStorage* textStorage = [self textStorage];
		[textStorage addAttributes:[textField textAttributes] range:NSMakeRange(0, [textStorage length])];
	}
	
	// Syntax Highlighting
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
	
	// Autocompletion
	if (self.enableAutocompletion) {
		[self _handleCompletion:LMCompletionEventTextDidChange];
	}
}

#pragma mark - Pasteboard

- (NSString *)preferredPasteboardTypeFromArray:(NSArray *)availableTypes restrictedToTypesFromArray:(NSArray *)allowedTypes
{
	NSArray* types;
	if (allowedTypes) {
		NSMutableSet* set = [NSMutableSet setWithArray:availableTypes];
		[set intersectSet:[NSSet setWithArray:allowedTypes]];
		types = [set allObjects];
	}
	else {
		types = availableTypes;
	}
	
	NSArray* preferredTypes = nil;
	if ([self.delegate respondsToSelector:@selector(preferredPasteboardTypesForTextView:)]) {
		preferredTypes = [(id<LMTextViewDelegate>)self.delegate preferredPasteboardTypesForTextView:self];
	}
	preferredTypes = [(preferredTypes ?: @[]) arrayByAddingObjectsFromArray:@[NSPasteboardTypeRTFD, NSRTFDPboardType]];
	
	for (NSString* type in preferredTypes) {
		if ([types containsObject:type]) {
			return type;
		}
	}
	
	return [super preferredPasteboardTypeFromArray:availableTypes restrictedToTypesFromArray:allowedTypes];
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
	// Hack: We override the type since there is a bug when drag-and-dropping files
	type = [self preferredPasteboardTypeFromArray:[pboard types] restrictedToTypesFromArray:nil];
	
	NSAttributedString* attributedString = nil;
	
	// Try to get an attributed string from the delegate
	if ([self.delegate respondsToSelector:@selector(textView:attributedStringFromPasteboard:type:range:)]) {
		attributedString = [(id<LMTextViewDelegate>)self.delegate textView:self attributedStringFromPasteboard:pboard type:type range:[self rangeForUserTextChange]];
	}
	
	// If not set by the delegate, try to read as NSPasteboardTypeRTFD or NSRTFDPboardType
	// Note: Even if doc says that NSRTFDPboardType should be replaced by NSPasteboardTypeRTFD, it is still used by the framework
	if (attributedString == nil &&
		([type isEqualToString:NSPasteboardTypeRTFD] || [type isEqualToString:NSRTFDPboardType])) {
		
		NSData* data = [pboard dataForType:type];
		if (data) {
			attributedString = [[NSMutableAttributedString alloc] initWithData:data options:nil documentAttributes:nil error:NULL];
		}
	}
	
	// If an attributedString is set before, insert it
	if (attributedString) {
		[attributedString enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, [attributedString length]) options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
			if (value) {
				NSTextAttachment* textAttachment = value;
				textAttachment.attachmentCell = [self textAttachmentCellForTextAttachment:textAttachment];
			}
		}];
		
		NSRange range = [self rangeForUserTextChange];
		if ([self shouldChangeTextInRange:range replacementString:[attributedString string]]) {
			[[self textStorage] replaceCharactersInRange:range withAttributedString:attributedString];
			[self didChangeText];
			
			return YES;
		}
		else {
			NSLog(@"readSelectionFromPasteboard: Text View rejected replacement by %@ at range %@", attributedString, NSStringFromRange(range));
		}
	}
	
	return [super readSelectionFromPasteboard:pboard type:type];
}

- (NSArray *)writablePasteboardTypes
{
	// Interesting experiment: without subclassing -writablePasteboardTypes, NSPasteboardTypeRTFD and NSRTFDPboardType are used only when another app supporting rich text such as TextEdit is open...
	
	NSMutableArray* writablePasteboardTypes = [[super writablePasteboardTypes] mutableCopy];
	
	if (![writablePasteboardTypes containsObject:NSPasteboardTypeRTFD]) {
		[writablePasteboardTypes addObject:NSPasteboardTypeRTFD];
	}
	if (![writablePasteboardTypes containsObject:NSRTFDPboardType]) {
		[writablePasteboardTypes addObject:NSRTFDPboardType];
	}
	
	return writablePasteboardTypes;
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

#pragma mark - Contextual Menu

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu* menu = [super menuForEvent:theEvent];
	
	NSLayoutManager *layoutManager = [self layoutManager];
	NSTextContainer *textContainer = [self textContainer];
	NSUInteger charIndex = [self charIndexForPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
	NSRange tokenRange = NSMakeRange(NSNotFound, 0);
	
    if (charIndex != NSNotFound) {
		if ([[self.textStorage string] characterAtIndex:charIndex] == 0xFFFC) {
			
		}
		else if (self.parser) {
			NSArray* path = [self.parser keyPathForObjectAtRange:NSMakeRange(charIndex, 1) objectRange:&tokenRange];
			NSRect bounds = [layoutManager boundingRectForGlyphRange:tokenRange inTextContainer:textContainer];
			
			if (tokenRange.location != NSNotFound) {
				BOOL selectToken = NO;
				
				if ([self.delegate respondsToSelector:@selector(textView:menu:forEvent:forTokenRange:withBounds:keyPath:selectToken:)]) {
					menu = [(id<LMTextViewDelegate>)self.delegate textView:self menu:menu forEvent:theEvent forTokenRange:tokenRange withBounds:bounds keyPath:path selectToken:&selectToken];
				}
				
				if (selectToken) {
					[self setSelectedRange:tokenRange];
				}
			}
		}
    }
	
	return menu;
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
	NSRange tokenRange = NSMakeRange(NSNotFound, 0);
    if (charIndex != NSNotFound) {
		if ([[self.textStorage string] characterAtIndex:charIndex] == 0xFFFC) {
			
		}
		else if (self.parser) {
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
	NSRange fullRange = NSMakeRange(0, [self.textStorage.string length]);
	
	NSRange characterRange;
	if ([self isFieldEditor]) {
		characterRange = fullRange;
	}
	else {
		NSRange glyphRange = [self.layoutManager glyphRangeForBoundingRect:self.enclosingScrollView.documentVisibleRect inTextContainer:self.textContainer];
		characterRange = [self.layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
	}
	
	NSTextStorage* textStorage = [self textStorage];
	NSMutableArray* removedAttribtues = [NSMutableArray array]; // Used to store which attributes were removed once
	
	if (!_useTemporaryAttributesForSyntaxHighlight) {
		[textStorage beginEditing];
	}
	
	// Store whether we can use the delegate to get the attribtues
	BOOL usingDelegate = [self.delegate respondsToSelector:@selector(textView:attributesForTextWithParser:tokenMask:atRange:)];
	
	[[self parser] applyAttributesInRange:characterRange withBlock:^(NSUInteger tokenTypeMask, NSRange range) {
		
		NSDictionary* attributes = nil;
		
		// Trying to get attribtues from delegate
		if (usingDelegate) {
			attributes = [(id<LMTextViewDelegate>)self.delegate textView:self attributesForTextWithParser:[self parser] tokenMask:tokenTypeMask atRange:range];
		}
		
		// If delegate wasn't implemented or returned nil, set default attributes
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
		
		// Remove attributes when used for first time
		for (NSString* attributeName in attributes) {
			// If not already removed...
			if (![removedAttribtues containsObject:attributeName]) {
				// Remove it
				if (_useTemporaryAttributesForSyntaxHighlight) {
					[layoutManager removeTemporaryAttribute:attributeName forCharacterRange:fullRange];
				}
				else {
					[textStorage removeAttribute:attributeName range:fullRange];
				}
				// Mark this attribute as removed
				[removedAttribtues addObject:attributeName];
			}
		}
		
		// Apply attribtue
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
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(textView:textAttachmentCellForTextAttachment:)]) {
		textAttachmentCell = [(id<LMTextViewDelegate>)self.delegate textView:self textAttachmentCellForTextAttachment:textAttachment];
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

#pragma mark - NSTextView (NSCompletion)

- (NSRange)rangeForUserCompletion
{
	// Check if delegate can handle it (delegate may return nil as the value to set the default behavior)
	if (self.delegate && [self.delegate respondsToSelector:@selector(rangeForUserCompletionInTextView:)]) {
		NSValue* range = [(id<LMTextViewDelegate>)self.delegate rangeForUserCompletionInTextView:self];
		if (range) {
			return [range rangeValue];
		}
	}
	
	if (self.parser) {
		NSRange range = {NSNotFound, 0};
		[self.parser keyPathForObjectAtRange:[self rangeForUserTextChange] objectRange:&range];
		
		if ([[self string] length] == 0) {
			range = NSMakeRange(0, 0);
		}
		else if (range.location == NSNotFound) {
			range = [self rangeForUserTextChange];
		}
		
		return range;
	}
	else {
		return [super rangeForUserCompletion];
	}
}

- (void)insertText:(id)insertString
{
	_insertedString = insertString;
	[super insertText:insertString];
	_insertedString = nil;
}

- (NSRect)_frameForCompletionWindowRangeForUserCompletion:(NSRange)rangeForUserCompletion
{
	// Determine the frame for the completion view in the screen coordinate system
	NSRect glyphRange = [self.layoutManager boundingRectForGlyphRange:rangeForUserCompletion inTextContainer:self.textContainer];
	NSRect glyphRangeInTextView = NSOffsetRect(glyphRange, self.textContainerOrigin.x, self.textContainerOrigin.y);
	CGSize completionViewSize = [_completionView intrinsicContentSize];
	CGRect completionRect = CGRectMake(round(glyphRangeInTextView.origin.x - _completionView.completionInset.width),
									   round(glyphRangeInTextView.origin.y + glyphRangeInTextView.size.height - _completionView.completionInset.height),
									   completionViewSize.width,
									   completionViewSize.height);
	NSRect frameInWindow = [self convertRect:completionRect toView:nil];
	return [self.window convertRectToScreen:frameInWindow];
}

- (void)keyDown:(NSEvent *)theEvent
{
	// This fixes a weird Cocoa behavior: in some cases, ESCAPE key is handled in keyDown:
	// to remove focus on the text field before we can handle completion: or doCoomandBySelector:
	if (theEvent.keyCode == 53 /* ESCAPE Key */) {
		if (_completionWindow == nil) {
			[self _handleCompletion:LMCompletionEventSystemCompletion];
		}
		else {
			[self _handleCompletion:LMCompletionEventEscapeKey];
		}
	}
	else {
		[super keyDown:theEvent];
	}
}

- (void)doCommandBySelector:(SEL)aSelector
{
	BOOL handled = NO;
	
	// Completion
	if (_completionWindow) {
		if (aSelector == @selector(moveDown:)) {
			[_completionView selectNextCompletion];
			handled = YES;
		}
		else if (aSelector == @selector(moveUp:)) {
			[_completionView selectPreviousCompletion];
			handled = YES;
		}
		else if (aSelector == @selector(insertNewline:)) {
			id<LMCompletionOption>completionOption = [_completionView currentCompletionOption];
			[self insertCompletionOption:completionOption inRange:[self rangeForUserCompletion] isFinal:YES];
			handled = YES;
		}
		else if (aSelector == @selector(moveToBeginningOfDocument:)) {
			[_completionView selectFirstCompletion];
			handled = YES;
		}
		else if (aSelector == @selector(moveToEndOfDocument:)) {
			[_completionView selectLastCompletion];
			handled = YES;
		}
	}
	
	if (!handled) {
		[super doCommandBySelector:aSelector];
	}
}

- (void)_handleCompletion:(LMCompletionEventType)completionEvent
{
	NSAssert(self.enableAutocompletion, @"Called _handleCompletion when enableAutocompletion is NO");
	
	if (_handlingCompletion) {
		return;
	}
	_handlingCompletion = YES;
	
	NSRange rangeForUserCompletion = [self rangeForUserCompletion];
	NSRange rangeForUserTextChange = [self rangeForUserTextChange];
	NSUInteger insertedStringLength = _insertedString ? [_insertedString length] : 0;
	NSRange rangeOfInsertedText = NSMakeRange(rangeForUserTextChange.location - insertedStringLength, insertedStringLength);
	
	NSLog(@"rangeForUserTextChange: %@", NSStringFromRange(rangeForUserTextChange));
	
	BOOL updateCompletions = NO;
	
	// START completion session
	// No completion before, start a new completion session
	
	if ((
			(completionEvent == LMCompletionEventTextDidChange && insertedStringLength > 0) ||
			completionEvent == LMCompletionEventSystemCompletion
		 ) &&
		_completionRange.location == NSNotFound) {
		NSLog(@"START completion");
		_completionRange = rangeForUserCompletion;
		_originalStringBeforeCompletion = [[[self textStorage] attributedSubstringFromRange:rangeForUserCompletion] mutableCopy];
		
		updateCompletions = YES;
	}
	
	// CONTINUE completion session
	
	else if ((
				(completionEvent == LMCompletionEventTextDidChange && insertedStringLength > 0) ||
				completionEvent == LMCompletionEventSystemCompletion
			  ) &&
			 _completionRange.location != NSNotFound &&
			 _completionRange.location >= rangeForUserCompletion.location &&
			 _completionRange.location + _completionRange.length <= rangeForUserCompletion.location + rangeForUserCompletion.length) {
		NSLog(@"CONTINUE completion");
		_completionRange = rangeForUserCompletion;
		
		NSAttributedString* originalStringToAdd = [[self textStorage] attributedSubstringFromRange:rangeOfInsertedText];
		[_originalStringBeforeCompletion appendAttributedString:originalStringToAdd];
		
		updateCompletions = YES;
	}
	
	// END completion session
	
	else if (_completionRange.location != NSNotFound) {
		NSLog(@"END completion");
		
		NSLog(@"Length: %ld Range: %@", [[self textStorage] length], NSStringFromRange(_completionRange));
		
		// There may be characters left in the text storage and have been modified by completions
		// We need to restore them as they were if there were no completion mechanism
		// We shouldn't replace by original completion if called by insertCompletion: for final insertions
		if ([[self textStorage] length] > _completionRange.location &&
			completionEvent != LMCompletionEventFinalCompletionInserted) {
			
			// In the case characters have been deleted
			if (_completionRange.length + _completionRange.location > [[self textStorage] length]) {
				[_originalStringBeforeCompletion deleteCharactersInRange:NSMakeRange([[self textStorage] length] - _completionRange.location, _completionRange.location + _completionRange.length - [[self textStorage] length])];
				_completionRange.length = [[self textStorage] length] - _completionRange.location;
			}
			
			NSAssert(_completionRange.length == [_originalStringBeforeCompletion length], @"Ending completion with a wrong length for original string");
			
			[[self textStorage] replaceCharactersInRange:_completionRange withAttributedString:_originalStringBeforeCompletion];
			_completionRange.location = NSNotFound;
			
			[self didChangeText];
		}
		else {
			_completionRange.location = NSNotFound;
		}
		
		// Remove completion window
		[self.window removeChildWindow:_completionWindow];
		_completionWindow = nil;
		_completionView = nil;
		
		_originalStringBeforeCompletion = nil;
	}
	
	// Nothing to do, completion is already ended
	else {
		NSLog(@"ALREADY ENDED");
	}
	
	// On START or CONTINUE completions, set their values
	if (updateCompletions) {
		NSInteger indexOfSelectedItem = 0;
		NSArray* completions = [self completionsForPartialWordRange:rangeForUserCompletion indexOfSelectedItem:&indexOfSelectedItem];
		
		if ([completions count] > 0) {
			
			// If completion view is nil, create it
			if (_completionView == nil) {
				// Try to use delegate's completion view
				if (self.delegate && [self.delegate respondsToSelector:@selector(completionViewForTextView:)]) {
					_completionView = [(id<LMTextViewDelegate>)self.delegate completionViewForTextView:self];
				}
				// If delegate didn't set the view, init the default one
				if (_completionView == nil) {
					_completionView = [[LMCompletionView alloc] init];
				}
				// Set self as delegate
				[_completionView setDelegate:self];
			}
			
			// Set completions in the view
			[_completionView setCompletions:completions];
			
			// If completion window is nil, create it
			if (_completionWindow == nil) {
				
				// Create the completion window
				_completionWindow = [[NSWindow alloc] initWithContentRect:[self _frameForCompletionWindowRangeForUserCompletion:rangeForUserCompletion] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
				_completionWindow.backgroundColor = [NSColor clearColor];
				[_completionWindow setOpaque:NO];
				[_completionWindow setAnimationBehavior:NSWindowAnimationBehaviorAlertPanel];
				[self.window addChildWindow:_completionWindow ordered:NSWindowAbove];
				
				// Set the completion view in its window
				[_completionWindow setContentView:_completionView];
			}
			// Set the frame if window already existed
			else {
				[_completionWindow setFrame:[self _frameForCompletionWindowRangeForUserCompletion:rangeForUserCompletion] display:YES];
			}
		}
		
		// When no completions
		else {
			// Remove completion window
			[self.window removeChildWindow:_completionWindow];
			_completionWindow = nil;
			_completionView = nil;
		}
	}
	
	
	if (_completionRange.location != NSNotFound) {
		NSLog(@"Completing Range: %@", NSStringFromRange(_completionRange));
		NSLog(@"Completing String: %@", [[[self textStorage] attributedSubstringFromRange:_completionRange] string]);
		NSLog(@"String Before Completion: %@", [_originalStringBeforeCompletion string]);
	}
	
	_handlingCompletion = NO;
}

- (void)complete:(id)sender
{
	// Use LMTextView's custom completion mechanism
	
	if (self.enableAutocompletion) {
		[self _handleCompletion:LMCompletionEventSystemCompletion];
	}
	
	// If not, use system completion mechanism
	
	else {
		[super complete:sender];
	}
}

- (void)insertCompletionOption:(id<LMCompletionOption>)completionOption inRange:(NSRange)range isFinal:(BOOL)isFinal
{
	NSAssert(self.enableAutocompletion, @"Calling -insertCompletionOption:inRange:isFinal when using system completion");
	
	// TODO: handle non final insertions (XCode style)
	if (!isFinal) {
		return;
	}
	
	// We need to set the _handlingCompletion flag here too
	// because calling didChangeText triggers _handleCompletion:
	if (_handlingCompletion) {
		return;
	}
	_handlingCompletion = YES;
	
	NSString* completionString = nil;
	NSAttributedString* completionAttributedString = nil;
	if ([completionOption respondsToSelector:@selector(attributedStringValue)]) {
		completionAttributedString = [completionOption attributedStringValue];
		completionString = [completionAttributedString string];
	}
	else {
		completionString = [completionOption stringValue];
	}
	
	if ([self shouldChangeTextInRange:range replacementString:completionString]) {
		if (completionAttributedString) {
			[[self textStorage] replaceCharactersInRange:range withAttributedString:completionAttributedString];
		}
		else {
			[[self textStorage] replaceCharactersInRange:range withString:[completionOption stringValue]];
		}
		[self didChangeText];
	}
	
	_handlingCompletion = NO;
	
	[self _handleCompletion:LMCompletionEventFinalCompletionInserted];
}

- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(NSInteger)movement isFinal:(BOOL)flag
{
	if (self.enableAutocompletion) {
		[self insertCompletionOption:word inRange:charRange isFinal:flag];
	}
	else {
		[super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
	}
}

#pragma mark - LMCompletionViewDelegate

- (void)didSelectCompletionOption:(id<LMCompletionOption>)completionOption
{
	[self insertCompletionOption:completionOption inRange:[self rangeForUserCompletion] isFinal:YES];
}

@end
