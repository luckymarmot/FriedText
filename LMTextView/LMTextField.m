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

@interface LMTextField () <LMCompletionViewDelegate> {
	BOOL _continueCompletion;
}

- (NSRange)_completionRangeWithRange:(NSRange)range;

@property (strong) LMCompletionView* completionView;
- (BOOL)isCompleting;
- (void)stopCompletion:(id)sender validated:(BOOL)validated animated:(BOOL)animated;
- (void)complete:(id)sender animated:(BOOL)animated;

@property NSRange temporaryCompletingRange;

@property NSMutableString* stringWithoutCompletion;

@end

/*
 * TODO: Clean this class by reading more carefully this doc:
 * https://developer.apple.com/library/mac/#documentation/TextFonts/Conceptual/CocoaTextArchitecture/TextEditing/TextEditing.html#//apple_ref/doc/uid/TP40009459-CH3-SW16
 * In particular the "Subclassing NSTextView" part
 */

@implementation LMTextField

#pragma mark - Initialization

- (void)_initialize
{
	_enabled = YES;
	self.forbiddenCharacterSet = [NSMutableCharacterSet characterSetWithRange:NSMakeRange(0, 0)];
	self.completionSeparatingCharacterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
	
	[self addObserver:self forKeyPath:@"editable" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:NULL];
	[self addObserver:self forKeyPath:@"multiline" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)setMultiline:(BOOL)multiline
{
	if (multiline) {
		[self.forbiddenCharacterSet formIntersectionWithCharacterSet:[[NSCharacterSet newlineCharacterSet] invertedSet]];
	}
	else {
		[self.forbiddenCharacterSet formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];
	}
}

- (BOOL)isMultiline
{
	return ![self.forbiddenCharacterSet isSupersetOfSet:[NSCharacterSet newlineCharacterSet]];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self _initialize];
	}
	return self;
}

- (id)init
{
	self = [super init];
	if (self) {
		[self _initialize];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container
{
	self = [super initWithFrame:frameRect textContainer:container];
	if (self) {
		[self _initialize];
	}
	return self;
}

#pragma KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSLog(@"KVO: %@ %@ > %@", NSStringFromClass([object class]), keyPath, [change objectForKey:NSKeyValueChangeNewKey]);
	
	if (object == self.completionView && [keyPath isEqualToString:@"completingString"]) {
		NSString* completingString = [self.completionView completingString];
		[self insertCompletion:completingString forPartialWordRange:self.rangeForUserCompletion movement:0 isFinal:NO];
	}
}

#pragma Implementation

- (NSRange)secureTemporaryCompletingRange
{
	NSInteger position = MIN(MAX(0, _temporaryCompletingRange.location), self.textStorage.length);
	NSRange securedRange = NSMakeRange(position, MIN(_temporaryCompletingRange.length, self.textStorage.length - position));
	return securedRange;
}

- (BOOL)acceptsFirstResponder
{
	return _enabled;
}

- (BOOL)isCompleting
{
	return [self.completionView superview] != nil;
}

- (void)awakeFromNib
{
	_temporaryCompletingRange = NSMakeRange(NSNotFound, 0);
	_continueCompletion = NO;
	
	self.completionView = [[LMCompletionView alloc] initWithFrame:NSMakeRect(0.f, 0.f, 200.f, 100.f)];
	self.completionView.delegate = self;
	
	[self.completionView addObserver:self forKeyPath:@"completingString" options:0 context:NULL];
	
	[self setContinuousSpellCheckingEnabled:NO];
	[self setAutomaticSpellingCorrectionEnabled:NO];
	[self setGrammarCheckingEnabled:NO];
	
	const float LargeNumberForText = 1.0e7;
	
	NSScrollView *scrollView = [self enclosingScrollView];
	[scrollView setHasVerticalScroller:NO];
	[scrollView setHasHorizontalScroller:NO];
	
	NSTextContainer *textContainer = [self textContainer];
	[textContainer setContainerSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
	[textContainer setWidthTracksTextView:NO];
	[textContainer setHeightTracksTextView:NO];
	
	[self setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
	[self setHorizontallyResizable:YES];
	[self setVerticallyResizable:YES];
	[self setAutoresizingMask:NSViewNotSizable];
	
	[self setTextContainerInset:NSMakeSize(2.f, 4.f)];
	
	[self setSelectedTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
									[NSColor colorWithCalibratedWhite:0.6f alpha:0.4f], NSBackgroundColorAttributeName,
									nil]];

}

- (void)_setAttributes
{
	NSMutableDictionary* attributesDefault = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											  [NSFont fontWithName:@"Menlo" size:11.f], NSFontAttributeName,
											  [NSColor colorWithCalibratedWhite:0.0f alpha:1.f], NSForegroundColorAttributeName,
											  nil];
	
	NSMutableDictionary* attributesTemporaryCompleting = [attributesDefault mutableCopy];
	[attributesTemporaryCompleting setValue:[NSColor colorWithCalibratedWhite:0.3f alpha:1.f] forKey:NSForegroundColorAttributeName];
	
	[self.textStorage setAttributes:attributesDefault range:NSMakeRange(0, self.textStorage.length)];
	if (_temporaryCompletingRange.location != NSNotFound) {
		[self.textStorage setAttributes:attributesTemporaryCompleting range:[self secureTemporaryCompletingRange]];
	}
}

- (void)insertText:(id)insertString
{
	[super insertText:insertString];
	
	if (_stringWithoutCompletion) {
		[_stringWithoutCompletion appendString:insertString];
	}
	
	[self complete:nil animated:NO];
}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	return [self.delegate textView:self completions:nil forPartialWordRange:charRange indexOfSelectedItem:index];
}

- (NSRange)rangeForUserCompletion
{
	return [self _completionRangeWithRange:self.selectedRange];
}

- (void)stopCompletion:(id)sender validated:(BOOL)validated animated:(BOOL)animated
{
	if (_stringWithoutCompletion && !validated) {
		[self.textStorage replaceCharactersInRange:NSMakeRange(0, [self.textStorage length]) withString:[_stringWithoutCompletion substringWithRange:NSMakeRange(0, MIN([_stringWithoutCompletion length], [self.textStorage length]))]];
	}
	_stringWithoutCompletion = nil;
	_temporaryCompletingRange = NSMakeRange(NSNotFound, 0);

	if ([self isCompleting]) {
		if (animated) {
			[self.completionView setWantsLayer:YES];

			CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
			animation.fromValue = [NSNumber numberWithDouble:1.0];
			animation.toValue = [NSNumber numberWithDouble:0.0];
			animation.delegate = self;
			animation.fillMode = kCAFillModeForwards;
			animation.removedOnCompletion = NO;
			
			[self.completionView.layer addAnimation:animation forKey:@"opacity"];
		}
		else {
			[self.completionView removeFromSuperview];
		}
	}
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self.completionView removeFromSuperview];
}

- (void)cancelCompletion:(id)sender
{
	// Erase previous completion
	if (_temporaryCompletingRange.location != NSNotFound) {
		[self.textStorage replaceCharactersInRange:[self secureTemporaryCompletingRange] withString:@""];
	}
	_temporaryCompletingRange = NSMakeRange(NSNotFound, 0);
}

- (void)complete:(id)sender
{
	[self complete:sender animated:YES];
}

- (void)complete:(id)sender animated:(BOOL)animated
{
	NSRange rangeForUserCompletion = self.rangeForUserCompletion;
	NSArray* completions = [self completionsForPartialWordRange:rangeForUserCompletion indexOfSelectedItem:NULL];

	if ([completions count] == 0) {
		[self.completionView removeFromSuperview];
	}
	else {
		_continueCompletion = YES;
		
		[self.completionView setCompletions:completions];

		// Calculating completion view frame
		NSRect glyphRange = [self.layoutManager boundingRectForGlyphRange:rangeForUserCompletion inTextContainer:self.textContainer];
		NSRect glyphRangeInTextView = NSOffsetRect(glyphRange, self.textContainerOrigin.x, self.textContainerOrigin.y);
		
		CGFloat completionWidth = self.superview.bounds.size.width + 28.f;
		CGFloat completionHeight = MIN(self.completionView.tableView.rowHeight * [self.completionView.completions count],
									   self.completionContainer.bounds.size.height > 550.f ? 250.f : 100.f)  + self.completionView.textFieldHeight + self.completionView.completionInset.height * 2;
		CGFloat completionVerticalMargin = 10.f;

		// Get the container rect in the view's coordinates to check if the completion view won't move outside the text when text is scrolled
		CGRect containerRect = [self convertRect:self.enclosingScrollView.bounds fromView:self.enclosingScrollView];

		CGRect completionRect = CGRectMake(round(MAX(glyphRangeInTextView.origin.x, containerRect.origin.x) - completionVerticalMargin - self.completionView.completionInset.width),
										   round(glyphRangeInTextView.origin.y + glyphRangeInTextView.size.height - self.completionView.completionInset.height),
										   completionWidth,
										   completionHeight);
		CGRect completionRectConverted = [self.completionContainer convertRect:completionRect fromView:self];
		CGPoint anchorPoint = CGPointMake(0.5,1.0);
		
		// If completion view cannot fit downside the text view, move it upside
		if (!CGRectContainsRect(self.completionContainer.bounds, completionRectConverted)) {
			anchorPoint = CGPointMake(0.5,0.0);
			completionRect.origin.y = round(glyphRangeInTextView.origin.y - completionHeight);
			completionRectConverted = [self.completionContainer convertRect:completionRect fromView:self];
		}

		self.completionView.frame = completionRectConverted;
		
		if (self.completionView.superview == nil) {
			[self.completionContainer addSubview:self.completionView positioned:NSWindowAbove relativeTo:nil];
			
			[self.completionView setWantsLayer:YES];

			if (animated) {
				[self.completionView setAnchorPoint:anchorPoint];
				{
					CAKeyframeAnimation *animation = [CAKeyframeAnimation
													  animationWithKeyPath:@"transform"];
					NSArray *frameValues = [NSArray arrayWithObjects:
											[NSValue valueWithCATransform3D:CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(0.1f, 0.1f))],
											[NSValue valueWithCATransform3D:CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(1.1f, 1.1f))],
											[NSValue valueWithCATransform3D:CATransform3DMakeAffineTransform(CGAffineTransformMakeScale(1.0f, 1.0f))],
											nil];
					[animation setValues:frameValues];
					NSArray *frameTimes = [NSArray arrayWithObjects:
										   [NSNumber numberWithFloat:0.0],
										   [NSNumber numberWithFloat:0.9],
										   [NSNumber numberWithFloat:1.0],
										   nil];
					[animation setKeyTimes:frameTimes];
					animation.fillMode = kCAFillModeForwards;
					animation.removedOnCompletion = YES;
					
					[self.completionView.layer addAnimation:animation forKey:@"popup"];
				}
				
				{
					CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
					animation.fromValue = [NSNumber numberWithDouble:0.0];
					animation.toValue = [NSNumber numberWithDouble:1.0];
					animation.fillMode = kCAFillModeForwards;
					animation.removedOnCompletion = YES;
					
					[self.completionView.layer addAnimation:animation forKey:@"opacity"];
				}
			}
		}
	}
}

- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(NSInteger)movement isFinal:(BOOL)isFinal
{
	if (_stringWithoutCompletion == nil) {
		_stringWithoutCompletion = [[self.textStorage string] mutableCopy];
	}
	
	NSRange selectedRange = self.selectedRange;
	NSRange replaceRange;
	NSRange secureTemporaryCompletingRange = [self secureTemporaryCompletingRange];
	if (secureTemporaryCompletingRange.location == NSNotFound) {
		replaceRange = charRange;
	}
	else {
		replaceRange = NSMakeRange(charRange.location, secureTemporaryCompletingRange.location + secureTemporaryCompletingRange.length - charRange.location);
	}
	
	if (![self shouldChangeTextInRange:replaceRange replacementString:word]) {
		return;
	}
	
	[self.textStorage replaceCharactersInRange:replaceRange withString:word];

	if (isFinal) {
		_temporaryCompletingRange = NSMakeRange(NSNotFound, 0);
		[self setSelectedRange:NSMakeRange(replaceRange.location + [word length], 0)];
		[self stopCompletion:nil validated:YES animated:YES];
	}
	else {
		_temporaryCompletingRange = NSMakeRange(selectedRange.location, [word length] - (selectedRange.location - replaceRange.location));
		[self setSelectedRange:selectedRange];
	}

	[self didChangeText];
}

- (void)didChangeText
{
	NSRange forbiddenCharactersRange = [[self.textStorage string] rangeOfCharacterFromSet:self.forbiddenCharacterSet];
	if (forbiddenCharactersRange.location != NSNotFound) {
		[self.textStorage replaceCharactersInRange:NSMakeRange(forbiddenCharactersRange.location, [self.textStorage length] - forbiddenCharactersRange.location) withString:@""];
	}
	
	[self _setAttributes];

	[super didChangeText];
}

- (NSRange)_completionRangeWithRange:(NSRange)range
{
	NSRange whiteRange = [self.string rangeOfCharacterFromSet:self.completionSeparatingCharacterSet options:NSBackwardsSearch range:NSMakeRange(0, range.location)];
	NSRange completionWordRange;
	if (whiteRange.location == NSNotFound) {
		completionWordRange = NSMakeRange(0, range.location);
	}
	else {
		completionWordRange = NSMakeRange(whiteRange.location + whiteRange.length, range.location - whiteRange.location - whiteRange.length);
	}
	return completionWordRange;
}

- (void)keyDown:(NSEvent *)theEvent
{
	if (theEvent.keyCode == 36) { // ENTER
		if ([self isCompleting]) {
			NSString* completingString = [self.completionView completingString];
			[self insertCompletion:completingString forPartialWordRange:self.rangeForUserCompletion movement:0 isFinal:YES];
		}
		else {
			if ([self isMultiline]) {
				[super keyDown:theEvent];
			}
		}
	}
	else if (theEvent.keyCode == 53) { // ESC
		if ([self isCompleting]) {
			[self stopCompletion:nil validated:NO animated:YES];
		}
		else {
			[self complete:nil animated:YES];
		}
	}
	else if (theEvent.keyCode == 125) { // Move down
		if ([self isCompleting]) {
			[self.completionView selectNextCompletion];
		}
		else {
			[super keyDown:theEvent];
		}
	}
	else if (theEvent.keyCode == 126) { // Move up
		if ([self isCompleting]) {
			[self.completionView selectPreviousCompletion];
		}
		else {
			[super keyDown:theEvent];
		}
	}
	else if (theEvent.keyCode == 48) { // TAB
		[self stopCompletion:nil validated:NO animated:YES];
		
		if (theEvent.modifierFlags & NSShiftKeyMask) {
			if ([self.delegate respondsToSelector:@selector(shouldSetPreviousResponder:)]) {
				[self.delegate performSelector:@selector(shouldSetPreviousResponder:)withObject:self];
			}
		}
		else {
			if ([self.delegate respondsToSelector:@selector(shouldSetNextResponder:)]) {
				[self.delegate performSelector:@selector(shouldSetNextResponder:)withObject:self];
			}
		}
	}
	else {
		_continueCompletion = NO;
		[self cancelCompletion:nil];
		[super keyDown:theEvent];
		if (!_continueCompletion) {
			[self stopCompletion:nil validated:NO animated:NO];
		}
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[self stopCompletion:nil validated:NO animated:YES];
	[super mouseDown:theEvent];
}

- (void)setEnabled:(BOOL)enabled
{
	_enabled = enabled;
	self.alphaValue = enabled ? 1.0f : 0.3f;
	[self setEditable:enabled];
	[self setNeedsDisplay:YES];
}

- (BOOL)resignFirstResponder
{
	self.selectedRange = NSMakeRange(self.selectedRange.location, 0);
	[self stopCompletion:nil validated:NO animated:NO];
	[super resignFirstResponder];
	return YES;
}

#pragma mark - LMCompletionViewDelegate

- (void)didSelectCompletingString:(NSString *)completingString
{
	[self insertCompletion:completingString forPartialWordRange:self.rangeForUserCompletion movement:0 isFinal:YES];
}

@end
