//
//  LMTextField.h
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LMTextParser.h"

@interface LMTextField : NSTextView
- (void)t;
- (void)boundsDidChange;
- (void)textDidChange;
- (void)_k:(NSTimer*)timer;

@property (strong, nonatomic) id <LMTextParser> parser;

@end
