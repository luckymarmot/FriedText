//
//  LMTextTestingWindow.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/5/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LMTextViewWindow : NSWindow

@property (strong) IBOutlet LMTextScrollView *textScrollView;
@property (strong) IBOutlet LMTextView *textView;
@property (weak) IBOutlet NSPopover *tokenPopover;

- (IBAction)tokenize:(id)sender;
- (IBAction)foldSelection:(id)sender;

@end
