//
//  LMTextField.h
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LMTextParser.h"

@class LMTextField;

@protocol LMTextFieldDelegate <NSTextViewDelegate>

@optional
- (void)textView:(LMTextField*)textView mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray*)keyPath;
- (void)mouseDownOutsideTokenInTextView:(LMTextField*)textView;

@end

@interface LMTextField : NSTextView
- (void)_k:(NSTimer*)timer;

@property (strong, nonatomic) id <LMTextParser> parser;

@property (nonatomic) BOOL changeCursorOnTokens;

@end
