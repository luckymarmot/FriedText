//
//  LMTextTestingWindow.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/5/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMTextViewWindow.h"

#import "LMTextView.h"
#import "LMTextScrollView.h"

#import "LMJSONTextParser.h"

#import "NSArray+KeyPath.h"

#import "LMTokenAttachmentCell.h"
#import "LMFoldingTextAttachmentCell.h"
#import "LMLineNumberRuler.h"

@interface LMTextViewWindow () <NSTextStorageDelegate, LMTextViewDelegate> {
	NSRange _tokenPopoverRange;
	NSString* _tokenPopoverValue;
}

@end

@implementation LMTextViewWindow

- (void)awakeFromNib
{
	self.textView.delegate = self;
	self.textView.textStorage.delegate = self;
	[self.textView setRichText:NO];
	[self.textView setFont:[NSFont fontWithName:@"Menlo" size:11.f]];
	[self.textView setContinuousSpellCheckingEnabled:NO];
	[self.textView setAutomaticSpellingCorrectionEnabled:NO];
	[self.textView setChangeCursorOnTokens:YES];
	
	[self.textView setParser:[[LMJSONTextParser alloc] init]];
	
	[self.textView setString:[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:@"/Users/michamazaheri/Desktop/Photoshot.json"] encoding:NSUTF8StringEncoding]];
	[self.textView didChangeText];

	[self.tokenPopover setBehavior:NSPopoverBehaviorTransient];
	
	LMLineNumberRuler *rulerView = [[LMLineNumberRuler alloc] initWithTextView:self.textView];
	[self.textScrollView setHasHorizontalRuler:NO];
	[self.textScrollView setHasVerticalRuler:YES];
	[self.textScrollView setVerticalRulerView:rulerView];
	[self.textScrollView setRulersVisible:YES];
}

- (void)tokenize:(id)sender
{
	LMTokenAttachmentCell* tokenCell = [[LMTokenAttachmentCell alloc] init];
	tokenCell.string = _tokenPopoverValue;
	
	NSTextAttachment* textAttachment = [[NSTextAttachment alloc] init];
	textAttachment.attachmentCell = tokenCell;
	NSAttributedString* attributedString = [NSAttributedString attributedStringWithAttachment:textAttachment];
	if ([self.textView shouldChangeTextInRange:_tokenPopoverRange replacementString:[attributedString string]]) {
		[self.textView.textStorage replaceCharactersInRange:_tokenPopoverRange withAttributedString:attributedString];
		[self.textView didChangeText];
	}
	
	[self.tokenPopover close];
}

- (void)foldSelection:(id)sender
{
	NSMutableArray* ranges = [NSMutableArray array];
	NSMutableArray* attributedStrings = [NSMutableArray array];
	NSMutableArray* strings = [NSMutableArray array];
	
	[[self.textView selectedRanges] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if ([obj rangeValue].length > 0 && [obj rangeValue].location != NSNotFound) {
			LMFoldingTextAttachmentCell* cell = [[LMFoldingTextAttachmentCell alloc] init];
			
			NSTextAttachment* textAttachment = [[NSTextAttachment alloc] init];
			textAttachment.attachmentCell = cell;
			NSAttributedString* attributedString = [NSAttributedString attributedStringWithAttachment:textAttachment];
			[ranges addObject:obj];
			[attributedStrings addObject:attributedString];
			[strings addObject:[attributedString string]];
		}
	}];

	if ([ranges count] > 0 && [self.textView shouldChangeTextInRanges:ranges replacementStrings:strings]) {
		[self.textView.textStorage beginEditing];
		for (NSUInteger i = 0; i < [ranges count]; i++) {
			[self.textView.textStorage replaceCharactersInRange:[[ranges objectAtIndex:i] rangeValue] withAttributedString:[attributedStrings objectAtIndex:i]];
		}
		[self.textView.textStorage endEditing];
		[self.textView didChangeText];
	}
}

#pragma mark - NSTextViewDelegate

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	return @[
			@{@"word":@"Reina"},
			@{@"word":@"Micha"},
		  ];
}

- (void)textView:(LMTextView *)textView mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray *)keyPath
{
	_tokenPopoverRange = range;
	_tokenPopoverValue = [keyPath keyPathDescription];
	[self.tokenPopover showRelativeToRect:bounds ofView:textView preferredEdge:CGRectMaxYEdge];
	[(NSTextField*)[self.tokenPopover.contentViewController.view viewWithTag:1] setStringValue:[keyPath keyPathDescription]];
	[(NSTextField*)[self.tokenPopover.contentViewController.view viewWithTag:2] setStringValue:[self.textView.textStorage.string substringWithRange:range]];
}

@end
