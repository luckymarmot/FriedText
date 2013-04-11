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

@class LMTextField;

@protocol LMTextFieldDelegate <NSTextFieldDelegate>

- (void)textField:(LMTextField*)textField usingTextView:(LMTextView*)textView mouseDownForTokenAtRange:(NSRange)range withBounds:(NSRect)bounds keyPath:(NSArray*)keyPath;

@end

@interface LMTextField : NSTextField <LMTextViewDelegate>

@property (strong, nonatomic) IBOutlet id <LMTextParser> parser;

@end
