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

@protocol LMTextViewDelegate <NSTextViewDelegate>

@optional
- (void)textView:(LMTextView*)textView mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray*)keyPath;
- (void)mouseDownOutsideTokenInTextView:(LMTextView*)textView;

@end

@interface LMTextView : NSTextView

@property (strong, nonatomic) id <LMTextParser> parser;

@property (nonatomic) BOOL changeCursorOnTokens;

@property (nonatomic) BOOL optimizeHighlightingOnScrolling;
@property (nonatomic) BOOL optimizeHighlightingOnEditing;

@end
