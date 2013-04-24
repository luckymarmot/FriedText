//
//  LMTextField.h
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LMTextParser.h"

@class LMTextView, LMTextField;


#pragma mark - LMTextViewDelegate

@protocol LMTextViewDelegate <NSTextViewDelegate>

@optional
- (void)textView:(LMTextView*)textView mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray*)keyPath;
- (void)mouseDownOutsideTokenInTextView:(LMTextView*)textView;
- (id<NSTextAttachmentCell>)textview:(LMTextView*)textView textAttachmentCellForTextAttachment:(NSTextAttachment*)textAttachment;
- (NSDictionary*)textView:(LMTextView*)textView attributesForTextWithParser:(id<LMTextParser>) parser tokenMask:(NSUInteger)parserTokenMask atRange:(NSRange)range;

@end

#pragma mark - LMTextView

@interface LMTextView : NSTextView

@property (strong, nonatomic) id <LMTextParser> parser;

@property (nonatomic) BOOL changeCursorOnTokens;

@property (nonatomic) BOOL optimizeHighlightingOnScrolling;
@property (nonatomic) BOOL optimizeHighlightingOnEditing;

@property (nonatomic) BOOL useTemporaryAttributesForSyntaxHighlight;

@property (strong, nonatomic, readonly) NSMutableArray* textAttachmentCellClasses;

- (IBAction)highlightSyntax:(id)sender;

- (id<NSTextAttachmentCell>)textAttachmentCellForTextAttachment:(NSTextAttachment*)textAttachment;

- (BOOL)setString:(NSString *)string isUserInitiated:(BOOL)isUserInitiated;

- (NSDictionary*)textAttributes;

@end
