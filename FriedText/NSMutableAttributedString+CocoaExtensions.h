//
//  NSMutableAttributedString+CocoaExtensions.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/14/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LMTextParser.h"

@interface NSMutableAttributedString (CocoaExtensions)

- (void)removeAllAttributesExcept:(NSArray*)exceptions;

- (void)highlightSyntaxWithParser:(id<LMTextParser>)parser defaultAttributes:(NSDictionary*)defaultAttributes attributesBlock:(NSDictionary*(^)(NSUInteger parserTokenMask, NSRange range))attributesBlock;

@end
