//
//  LMTextTestingWindow.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/5/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMTextViewWindow.h"

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
	NSTextAttachment* textAttachment = [LMTokenAttachmentCell tokenAttachmentWithString:_tokenPopoverValue];
	
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

- (void)textView:(NSTextView *)textView clickedOnCell:(id<NSTextAttachmentCell>)cell inRect:(NSRect)cellFrame atIndex:(NSUInteger)charIndex
{
	NSLog(@"Clicked");
}

- (void)textView:(NSTextView *)textView doubleClickedOnCell:(id<NSTextAttachmentCell>)cell inRect:(NSRect)cellFrame atIndex:(NSUInteger)charIndex
{
	NSLog(@"Double Clicked");
}

//- (NSURL *)textView:(NSTextView *)textView URLForContentsOfTextAttachment:(NSTextAttachment *)textAttachment atIndex:(NSUInteger)charIndex
//{
//	return [NSURL fileURLWithPath:@"/Users/michamazaheri/Desktop/iOS Simulator Screen shot Apr 12, 2013 5.48.21 PM.png"];
//}

//- (NSArray *)textView:(NSTextView *)view writablePasteboardTypesForCell:(id<NSTextAttachmentCell>)cell atIndex:(NSUInteger)charIndex
//{
//	NSLog(@"1");
//	return @[NSPasteboardTypePNG];
//}
//
//- (BOOL)textView:(NSTextView *)view writeCell:(id<NSTextAttachmentCell>)cell atIndex:(NSUInteger)charIndex toPasteboard:(NSPasteboard *)pboard type:(NSString *)type
//{
//	NSLog(@"2:%@", type);
//	[pboard clearContents];
//	return [pboard setData:[NSData dataWithContentsOfFile:@"/Users/michamazaheri/Desktop/iOS Simulator Screen shot Apr 12, 2013 5.48.21 PM.png"] forType:NSPasteboardTypePNG];
//}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	NSLog(@"Words: %@ CharRange: %@, Index: %ld", words, NSStringFromRange(charRange), *index);
	*index = 2;
	return @[@"Accept", @"Accept-Encoding", @"Accept-Language"];
//	return @[
//			@{@"word":@"Reina"},
//			@{@"word":@"Micha"},
//		  ];
}

- (void)textView:(LMTextView *)textView mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray *)keyPath
{
	_tokenPopoverRange = range;
	_tokenPopoverValue = [keyPath keyPathDescription];
	if (NO) {
		[self.tokenPopover showRelativeToRect:bounds ofView:textView preferredEdge:CGRectMaxYEdge];
		[(NSTextField*)[self.tokenPopover.contentViewController.view viewWithTag:1] setStringValue:[keyPath keyPathDescription]];
		[(NSTextField*)[self.tokenPopover.contentViewController.view viewWithTag:2] setStringValue:[self.textView.textStorage.string substringWithRange:range]];
	}
	else {
		[self tokenize:nil];
	}
}

@end
