//
//  LMTextField.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/11/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMTextField.h"
#import "LMTextFieldCell.h"

#import "NSObject+TDBindings.h"

#import "NSMutableAttributedString+CocoaExtensions.h"

NSString* LMTextFieldAttributedStringValueBinding = @"attributedStringValue";

@interface LMTextField ()

@property (strong, nonatomic, readwrite) NSMutableArray* textAttachmentCellClasses;

@end

@implementation LMTextField

- (void)_setup
{
	self.useTemporaryAttributesForSyntaxHighlight = NO; // This is different default than LMTextView
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:self];
}

- (id)init
{
	self = [super init];
	if (self) {
		[self _setup];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self _setup];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
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
				NSFontAttributeName:[self font],
				NSForegroundColorAttributeName:[self textColor],
		  };
}

- (NSMutableArray *)textAttachmentCellClasses
{
	if (_textAttachmentCellClasses == nil) {
		_textAttachmentCellClasses = [NSMutableArray arrayWithArray:[LMTextView defaultTextAttachmentCellClasses]];
	}
	return _textAttachmentCellClasses;
}

#pragma mark - NSControl Overrides

+ (Class)cellClass
{
	return [LMTextFieldCell class];
}

- (void)setAttributedStringValue:(NSAttributedString *)obj
{
	NSMutableAttributedString* string = [obj mutableCopy];
	
	// If not rich text, remove any attributes
	if (![self isRichText]) {
		[string addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, [string length])];
		[string addAttribute:NSForegroundColorAttributeName value:self.textColor range:NSMakeRange(0, [string length])];
	}
	
	// Set syntax highlight attribtues
	if ([self parser]) {
		[string highlightSyntaxWithParser:self.parser defaultAttributes:[self textAttributes] attributesBlock:^NSDictionary *(NSUInteger parserTokenMask, NSRange range) {
			if ([self.delegate respondsToSelector:@selector(textField:fieldEditor:attributesForTextWithParser:tokenMask:atRange:)]) {
				return [(id<LMTextFieldDelegate>)self.delegate textField:self fieldEditor:nil attributesForTextWithParser:[self parser] tokenMask:parserTokenMask atRange:range];
			}
			else {
				return nil;
			}
		}];
	}
	
	[super setAttributedStringValue:[string copy]];
}

#pragma mark - NSView Overrides

- (NSSize)intrinsicContentSize
{
    if (![self.cell wraps]) {
        return [super intrinsicContentSize];
    }
	
    NSRect frame = [self frame];
	
    CGFloat width = frame.size.width;
	
    // Make the frame very high, while keeping the width
    frame.size.height = CGFLOAT_MAX;
	
    // Calculate new height within the frame
    // with practically infinite height.
    CGFloat height = [self.cell cellSizeForBounds: frame].height;
	
	if ([self currentEditor] && [[[self currentEditor] class] isSubclassOfClass:[NSTextView class]]) {
		
		// Thanks to: https://github.com/DouglasHeriot/AutoGrowingNSTextField/blob/master/autoGrowingExample/TSTTextGrowth.m
		NSRect usedRect = [[[(NSTextView*)[self currentEditor] textContainer] layoutManager] usedRectForTextContainer:[(NSTextView*)[self currentEditor] textContainer]];
		height = usedRect.size.height + 5;
	}
	
	return NSMakeSize(width, height);
}

#pragma mark - NSResponder Overrides

- (BOOL)becomeFirstResponder
{
	// Super: resigns current responder, then binds the text editor with this field, make the text editor first responder
	BOOL result = [super becomeFirstResponder];

	// Customize the Field Editor
	[[self currentEditor] setRichText:[self isRichText]];
	
	if ([[[self currentEditor] class] isSubclassOfClass:[LMTextView class]]) {
		[(LMTextView*)[self currentEditor] setParser:[self parser]];
		
		[(LMTextView*)[self currentEditor] highlightSyntax:nil];
		
		[(LMTextView*)[self currentEditor] setUseTemporaryAttributesForSyntaxHighlight:self.useTemporaryAttributesForSyntaxHighlight];
		
		[[(LMTextView*)[self currentEditor] textAttachmentCellClasses] setArray:[self textAttachmentCellClasses]];
		
		[(LMTextView*)[self currentEditor] setEnableAutocompletion:self.enableAutocompletion];
	}
	
	return result;
}

#pragma mark - NSTextDelegate

- (void)textDidChange:(NSNotification *)notification
{
	if (notification.object == [self currentEditor]) {
		
#warning Fix the shouldUpdateContinuouslyBinding for LMTextFieldAttributedStringValueBinding
		if ([self shouldUpdateContinuouslyBinding:LMTextFieldAttributedStringValueBinding]) {
			
		}
		[self propagateValue:[[(LMTextView*)[self currentEditor] textStorage] copy] forBinding:LMTextFieldAttributedStringValueBinding];
		
		[super textDidChange:notification];
		
		[self invalidateIntrinsicContentSize];
		if ([self.delegate respondsToSelector:@selector(textField:textDidChangeWithFieldEditor:)]) {
			[(id<LMTextFieldDelegate>)self.delegate textField:self textDidChangeWithFieldEditor:(LMTextView*)[self currentEditor]];
		}
	}
}

- (void)textDidEndEditing:(NSNotification *)notification
{
	if (notification.object == [self currentEditor]) {
		[self propagateValue:[[(LMTextView*)[self currentEditor] textStorage] copy] forBinding:LMTextFieldAttributedStringValueBinding];
		
		[super textDidEndEditing:notification];
		
		[self setAttributedStringValue:[self attributedStringValue]];
		
		[self invalidateIntrinsicContentSize];
	}
}

#pragma mark - NSTextViewDelegate

- (void)textView:(NSTextView *)textView clickedOnCell:(id<NSTextAttachmentCell>)cell inRect:(NSRect)cellFrame atIndex:(NSUInteger)charIndex
{
	if (textView == [self currentEditor]) {
		if ([self.delegate respondsToSelector:@selector(textField:fieldEditor:clickedOnCell:inRect:atIndex:)]) {
			[(id<LMTextFieldDelegate>)self.delegate textField:self fieldEditor:(LMTextView*)textView clickedOnCell:cell inRect:cellFrame atIndex:charIndex];
		}
	}
}

- (NSMenu *)textView:(NSTextView *)textView menu:(NSMenu *)menu forEvent:(NSEvent *)event atIndex:(NSUInteger)charIndex
{
	if ([self.delegate respondsToSelector:@selector(textField:fieldEditor:menu:forEvent:atIndex:)]) {
		return [(id<LMTextFieldDelegate>)self.delegate textField:self fieldEditor:(LMTextView*)textView menu:menu forEvent:event atIndex:charIndex];
	}
	else {
		return menu;
	}
}

#pragma mark - LMTextViewDelegate

- (void)textView:(LMTextView *)textView mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray *)keyPath
{
	if (textView == [self currentEditor]) {
		if ([self.delegate respondsToSelector:@selector(textField:fieldEditor:mouseDownForTokenAtRange:withBounds:keyPath:)]) {
			[(id<LMTextFieldDelegate>)self.delegate textField:self fieldEditor:textView mouseDownForTokenAtRange:range withBounds:bounds keyPath:keyPath];
		}
	}
}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	if (textView == [self currentEditor]) {
		if ([self.delegate respondsToSelector:@selector(textField:fieldEditor:completions:forPartialWordRange:indexOfSelectedItem:)]) {
			return [(id<LMTextFieldDelegate>)self.delegate textField:self fieldEditor:(LMTextView*)textView completions:words forPartialWordRange:charRange indexOfSelectedItem:index];
		}
	}

	return nil;
}

- (NSDictionary *)textView:(LMTextView *)textView attributesForTextWithParser:(id<LMTextParser>)parser tokenMask:(NSUInteger)parserTokenMask atRange:(NSRange)range
{
	if ([self.delegate respondsToSelector:@selector(textField:fieldEditor:attributesForTextWithParser:tokenMask:atRange:)]) {
		return [(id<LMTextFieldDelegate>)self.delegate textField:self fieldEditor:textView attributesForTextWithParser:parser tokenMask:parserTokenMask atRange:range];
	}
	else {
		return nil;
	}
}

- (id<NSTextAttachmentCell>)textView:(LMTextView *)textView textAttachmentCellForTextAttachment:(NSTextAttachment *)textAttachment
{
	if ([self.delegate respondsToSelector:@selector(textField:fieldEditor:textAttachmentCellForTextAttachment:)]) {
		return [(id<LMTextFieldDelegate>)self.delegate textField:self fieldEditor:textView textAttachmentCellForTextAttachment:textAttachment];
	}
	else {
		return nil;
	}
}

- (NSArray *)preferredPasteboardTypesForTextView:(LMTextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(preferredPasteboardTypesForTextField:fieldEditor:)]) {
		return [(id<LMTextFieldDelegate>)self.delegate preferredPasteboardTypesForTextField:self fieldEditor:textView];
	}
	else {
		return nil;
	}
}

- (NSAttributedString *)textView:(LMTextView *)textView attributedStringFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type range:(NSRange)range
{
	if ([self.delegate respondsToSelector:@selector(textField:fieldEditor:attributedStringFromPasteboard:type:range:)]) {
		return [(id<LMTextFieldDelegate>)self.delegate textField:self fieldEditor:textView attributedStringFromPasteboard:pboard type:type range:range];
	}
	else {
		return nil;
	}
}

- (NSValue*)rangeForUserCompletionInTextView:(LMTextView *)textView
{
	if (self.delegate && [self.delegate respondsToSelector:@selector(rangeForUserCompletionInTextField:fieldEditor:)]) {
		return [(id<LMTextFieldDelegate>)self.delegate rangeForUserCompletionInTextField:self fieldEditor:textView];
	}
	else {
		return nil;
	}
}

- (LMCompletionView *)completionViewForTextView:(LMTextView *)textView
{
	if (self.delegate && [self.delegate respondsToSelector:@selector(completionViewForTextField:fieldEditor:)]) {
		return [(id<LMTextFieldDelegate>)self.delegate completionViewForTextField:self fieldEditor:textView];
	}
	else {
		return nil;
	}
}

#pragma mark - Observing Frame / Bounds

- (void)frameDidChange:(NSNotification*)notification
{
	[self invalidateIntrinsicContentSize];
}

- (void)boundsDidChange:(NSNotification*)notification
{
	[self invalidateIntrinsicContentSize];
}

@end
