//
//  NSWindow+FriedText.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/15/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSWindow (FriedText)

- (void)setFieldEditor:(NSTextView*)fieldEditor forKey:(NSString*)key;

- (NSTextView*)fieldEditorForKey:(NSString*)key;

- (NSMutableDictionary*)fieldEditors;

- (void)setFieldEditors:(NSMutableDictionary*)fieldEditors;

@end
