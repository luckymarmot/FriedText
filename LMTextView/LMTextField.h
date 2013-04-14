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

@protocol LMTextFieldDelegate <NSTextFieldDelegate>

@optional

- (void)textField:(LMTextField*)textField fieldEditor:(LMTextView*)fieldEditor mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray*)keyPath;

- (NSArray *)textField:(LMTextField*)textField fieldEditor:(LMTextView *)fieldEditor completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index;

@end

@interface LMTextField : NSTextField <LMTextViewDelegate>

@property (strong, nonatomic) IBOutlet id <LMTextParser> parser;

@end
