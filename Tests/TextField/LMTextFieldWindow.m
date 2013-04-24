//
//  LMTextFieldWindow.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/11/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMTextFieldWindow.h"
#import "LMAttributedStringValueTransformer.h"

@implementation LMTextFieldWindow

- (void)awakeFromNib
{
	[self.jsonField bind:LMTextFieldAttributedStringValueBinding toObject:[NSUserDefaults standardUserDefaults] withKeyPath:@"TestBindingsKey" options:@{NSValueTransformerNameBindingOption:@"LMAttributedTokenStringValueTransformer"}];
	[self.serializationTestField bind:LMTextFieldAttributedStringValueBinding toObject:[NSUserDefaults standardUserDefaults] withKeyPath:@"TestBindingsKey" options:@{NSValueTransformerNameBindingOption:@"LMAttributedTokenStringValueTransformer"}];
	[self.stringField bind:NSValueBinding toObject:[NSUserDefaults standardUserDefaults] withKeyPath:@"TextFieldStringUserDefault" options:@{NSValueTransformerBindingOption:[LMAttributedStringValueTransformer attributedStringValueTransformerForTextField:self.stringField]}];
	self.jsonField.richText = NO;
	self.jsonField2.richText = NO;
}

#pragma mark - LMTextFieldDelegate

- (void)textField:(LMTextField *)textField fieldEditor:(LMTextView*)textView mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray *)keyPath
{
	NSTextAttachment* textAttachment = [LMTokenAttachmentCell tokenAttachmentWithString:[keyPath keyPathDescription]];
	
	NSAttributedString* attributedString = [NSAttributedString attributedStringWithAttachment:textAttachment];
	if ([textView shouldChangeTextInRange:range replacementString:[attributedString string]]) {
		[textView.textStorage replaceCharactersInRange:range withAttributedString:attributedString];
		[textView didChangeText];
	}
}

- (NSArray *)textField:(LMTextField *)textField fieldEditor:(LMTextView *)fieldEditor completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	NSLog(@"Words: %@ CharRange: %@, Index: %ld", words, NSStringFromRange(charRange), *index);
	*index = 2;
	return @[@"Accept", @"Accept-Encoding", @"Accept-Language"];
}

@end
