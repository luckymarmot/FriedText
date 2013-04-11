//
//  LMTextField.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/11/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LMTextParser.h"

@interface LMTextField : NSTextField

@property (strong, nonatomic) IBOutlet id <LMTextParser> parser;

@end
