//
//  LMTextFieldWindow.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/11/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMTextFieldWindow.h"

#import "LMTextView.h"

#import "LMTokenAttachmentCell.h"

#import "NSArray+KeyPath.h"

@implementation LMTextFieldWindow

#pragma mark - LMTextFieldDelegate

- (void)textField:(LMTextField *)textField fieldEditor:(LMTextView*)textView mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray *)keyPath
{
	LMTokenAttachmentCell* tokenCell = [[LMTokenAttachmentCell alloc] init];
	tokenCell.string = [keyPath keyPathDescription];
	
	NSTextAttachment* textAttachment = [[NSTextAttachment alloc] init];
	textAttachment.attachmentCell = tokenCell;
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
