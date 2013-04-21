//
//  LMLineNumberRuler.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/10/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LMLineNumberRuler : NSRulerView

@property (strong, nonatomic) NSFont * font;
@property (strong, nonatomic) NSColor * textColor;
@property (strong, nonatomic) NSColor * backgroundColor;

- (id)initWithTextView:(NSTextView*)textView;

@end
