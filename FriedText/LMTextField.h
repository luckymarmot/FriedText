//
//  LMTextField.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/11/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LMTextParser.h"
#import "LMTextView.h"

extern NSString* LMTextFieldAttributedStringValueBinding;

@class LMTextField;


#pragma mark - LMTextFieldDelegate

@protocol LMTextFieldDelegate <NSTextFieldDelegate>

@optional

- (void)textField:(LMTextField*)textField fieldEditor:(LMTextView*)fieldEditor mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray*)keyPath;

- (NSArray *)textField:(LMTextField*)textField fieldEditor:(LMTextView *)fieldEditor completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index;

- (void)textField:(LMTextField *)textField textDidChangeWithFieldEditor:(LMTextView *)fieldEditor;

- (NSDictionary*)textField:(LMTextField *)textField fieldEditor:(LMTextView*)fieldEditor attributesForTextWithParser:(id<LMTextParser>)parser tokenMask:(NSUInteger)parserTokenMask atRange:(NSRange)range;

- (id<NSTextAttachmentCell>)textField:(LMTextField*)textField fieldEditor:(LMTextView *)textView textAttachmentCellForTextAttachment:(NSTextAttachment *)textAttachment;

- (void)textField:(LMTextField *)textField fieldEditor:(LMTextView *)fieldEditor clickedOnCell:(id<NSTextAttachmentCell>)cell inRect:(NSRect)cellRect atIndex:(NSUInteger)charIndex;

@end


#pragma mark - LMTextField

@interface LMTextField : NSTextField <LMTextViewDelegate>

@property (strong, nonatomic) IBOutlet id <LMTextParser> parser;

@property (nonatomic, getter = isRichText) BOOL richText;

- (NSDictionary*)textAttributes;

@property (strong, nonatomic, readonly) NSMutableArray* textAttachmentCellClasses;

/**
 * Whether the text editor will be using temporary text attribtues for syntax
 * highlighting, or will be changing the text storage attributes.
 * Default: NO (Note: this default value is different than the one used in
 * LMTextView, this is for optimization purposes in LMTextView).
 */
@property (nonatomic) BOOL useTemporaryAttributesForSyntaxHighlight;

@end
