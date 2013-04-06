//
//  LMTextTestingWindow.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/5/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LMTextField, LMTextScrollView;

@interface LMTextTestingWindow : NSWindow

@property (strong) IBOutlet LMTextScrollView *textScrollView;
@property (strong) IBOutlet LMTextField *textField;
@property (weak) IBOutlet NSPopover *tokenPopover;

@end
