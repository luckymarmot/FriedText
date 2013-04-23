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
		[string highlightSyntaxWithParser:[self parser] attributesBlock:NULL];
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
	}
	
	return result;
}

#pragma mark - NSTextDelegate

- (void)textDidChange:(NSNotification *)notification
{
	if (notification.object == [self currentEditor]) {
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

@end
