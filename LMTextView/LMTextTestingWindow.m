//
//  LMTextTestingWindow.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/5/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMTextTestingWindow.h"

#import "LMTextField.h"

#import "LMJSONTextParser.h"

#import "NSArray+KeyPath.h"

#import "LMTokenAttachmentCell.h"

@interface LMTextTestingWindow () <NSTextStorageDelegate, LMTextFieldDelegate> {
	NSRange _tokenPopoverRange;
	NSString* _tokenPopoverValue;
}

@end

@implementation LMTextTestingWindow

- (void)awakeFromNib
{
	self.textField.delegate = self;
	self.textField.textStorage.delegate = self;
	[self.textField setRichText:NO];
	[self.textField setFont:[NSFont fontWithName:@"Menlo" size:11.f]];
	[self.textField setContinuousSpellCheckingEnabled:NO];
	[self.textField setAutomaticSpellingCorrectionEnabled:NO];
	[self.textField setChangeCursorOnTokens:YES];
	
	[self.textField setParser:[[LMJSONTextParser alloc] init]];
	
	[self.textField setString:[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:@"/Users/michamazaheri/Desktop/Photoshot.json"] encoding:NSUTF8StringEncoding]];
	[self.textField didChangeText];

	[self.tokenPopover setBehavior:NSPopoverBehaviorTransient];
}

- (void)tokenize:(id)sender
{
	LMTokenAttachmentCell* tokenCell = [[LMTokenAttachmentCell alloc] init];
	tokenCell.string = _tokenPopoverValue;
	
	NSTextAttachment* textAttachment = [[NSTextAttachment alloc] init];
	textAttachment.attachmentCell = tokenCell;
	NSAttributedString* attributedString = [NSAttributedString attributedStringWithAttachment:textAttachment];
	[self.textField.textStorage replaceCharactersInRange:_tokenPopoverRange withAttributedString:attributedString];
	[self.textField didChangeText];
	
	[self.tokenPopover close];
}

#pragma mark - NSTextViewDelegate

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	return @[
			@{@"word":@"Reina"},
			@{@"word":@"Micha"},
		  ];
}

- (void)textView:(LMTextField *)textView mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray *)keyPath
{
	_tokenPopoverRange = range;
	_tokenPopoverValue = [keyPath keyPathDescription];
	[self.tokenPopover showRelativeToRect:bounds ofView:textView preferredEdge:CGRectMaxYEdge];
	[(NSTextField*)[self.tokenPopover.contentViewController.view viewWithTag:1] setStringValue:[keyPath keyPathDescription]];
	[(NSTextField*)[self.tokenPopover.contentViewController.view viewWithTag:2] setStringValue:[self.textField.textStorage.string substringWithRange:range]];
}

@end
