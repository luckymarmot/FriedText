//
//  LMTextField.h
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LMTextField;

@protocol LMTextFieldDelegate <NSTextViewDelegate>

@optional

- (void)shouldSetNextResponder:(LMTextField*)textField;
- (void)shouldSetPreviousResponder:(LMTextField*)textField;

@end

@interface LMTextField : NSTextView

@property (strong, nonatomic) NSMutableCharacterSet* completionSeparatingCharacterSet;
@property (weak, nonatomic) NSView* completionContainer;
@property (strong, nonatomic) NSMutableCharacterSet* forbiddenCharacterSet;

@property (nonatomic) BOOL enabled;

- (void)setMultiline:(BOOL)multiline;
- (BOOL)isMultiline;

@end
