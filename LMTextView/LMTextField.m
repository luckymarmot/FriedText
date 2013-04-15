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

@end

@implementation LMTextField

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
		[string highlightSyntaxWithParser:[self parser]];
	}
	
	[super setAttributedStringValue:[string copy]];
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
	}
	
	return result;
}

#pragma mark - NSTextDelegate

- (void)textDidEndEditing:(NSNotification *)notification
{
	[self propagateValue:[[(LMTextView*)[self currentEditor] textStorage] copy] forBinding:LMTextFieldAttributedStringValueBinding];
	
	[super textDidEndEditing:notification];
	
	[self setAttributedStringValue:[self attributedStringValue]];
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

@end
