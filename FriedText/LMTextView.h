//
//  LMTextView.h
//  LMTextView
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LMTextParser.h"

@class LMTextView, LMTextField, LMCompletionView;


#pragma mark - LMTextViewDelegate

@protocol LMTextViewDelegate <NSTextViewDelegate>

@optional
- (void)textView:(LMTextView*)textView mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray*)keyPath;
- (void)mouseDownOutsideTokenInTextView:(LMTextView*)textView;
- (id<NSTextAttachmentCell>)textView:(LMTextView*)textView textAttachmentCellForTextAttachment:(NSTextAttachment*)textAttachment;
- (NSDictionary*)textView:(LMTextView*)textView attributesForTextWithParser:(id<LMTextParser>) parser tokenMask:(NSUInteger)parserTokenMask atRange:(NSRange)range;

// Handling Pasteboard

- (NSArray*)preferredPasteboardTypesForTextView:(LMTextView*)textView;
- (NSAttributedString*)textView:(LMTextView*)textView attributedStringFromPasteboard:(NSPasteboard*)pboard type:(NSString*)type range:(NSRange)range;

// Handling Menu

- (NSMenu*)textView:(NSTextView *)view menu:(NSMenu *)menu forEvent:(NSEvent *)event forTokenRange:(NSRange)tokenRange withBounds:(NSRect)bounds keyPath:(NSArray*)keyPath selectToken:(BOOL*)selectToken;

// Handling Completion

- (NSValue*)rangeForUserCompletionInTextView:(LMTextView*)textView;
- (LMCompletionView*)completionViewForTextView:(LMTextView*)textView;

@end

#pragma mark - LMTextView

@interface LMTextView : NSTextView

@property (strong, nonatomic) id <LMTextParser> parser;

@property (nonatomic) BOOL changeCursorOnTokens;

@property (nonatomic) BOOL optimizeHighlightingOnScrolling;
@property (nonatomic) BOOL optimizeHighlightingOnEditing;

@property (nonatomic) BOOL useTemporaryAttributesForSyntaxHighlight;

@property (nonatomic) BOOL enableAutocompletion;

+ (NSArray*)defaultTextAttachmentCellClasses;

@property (strong, nonatomic, readonly) NSMutableArray* textAttachmentCellClasses;

- (IBAction)highlightSyntax:(id)sender;

- (id<NSTextAttachmentCell>)textAttachmentCellForTextAttachment:(NSTextAttachment*)textAttachment;

- (BOOL)setString:(NSString *)string isUserInitiated:(BOOL)isUserInitiated;

- (NSDictionary*)textAttributes;

@end
