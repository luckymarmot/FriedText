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

@interface LMTextTestingWindow () /* <LMTextFieldDelegate> */ <NSTextStorageDelegate, NSTextViewDelegate>

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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:self.textField.enclosingScrollView.contentView];
	
	[self.textField setParser:[[LMJSONTextParser alloc] init]];
	
	[self.textField setString:[[NSString alloc] initWithData:[NSData dataWithContentsOfFile:@"/Users/michamazaheri/Desktop/Photoshot.json"] encoding:NSUTF8StringEncoding]];
	[self.textField didChangeText];
}

- (void)boundsDidChange:(NSNotification*)notification
{
//	NSLog(@"BDC");
	[self.textField boundsDidChange];
}

#pragma mark - NSTextViewDelegate

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	return @[
			@{@"word":@"Reina"},
			@{@"word":@"Micha"},
		  ];
}

- (void)textDidChange:(NSNotification *)notification
{
	[self.textField t];
	[self.textField textDidChange];
}

#pragma mark - NSTextStorageDelegate

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
	
//	NSTextStorage* textStorage = notification.object;
//	
//	NSRange range = NSMakeRange(0, textStorage.length);
//	
//	NSMutableDictionary* attributesDefault = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//											  [NSFont fontWithName:@"Menlo" size:11.f], NSFontAttributeName,
//											  [NSColor colorWithCalibratedWhite:0.0f alpha:1.f], NSForegroundColorAttributeName,
//											  nil];
//	
//	[textStorage setAttributes:attributesDefault range:range];
//	
//	[textStorage removeAttribute:NSForegroundColorAttributeName range:range];
	
	//add new coloring
//	[textStorage addAttribute:NSForegroundColorAttributeName
//						value:[NSColor yellowColor]
//						range:range];
}

@end
