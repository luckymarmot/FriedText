//
//  NSMutableAttributedString+CocoaExtensions.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/14/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "NSMutableAttributedString+CocoaExtensions.h"

@implementation NSMutableAttributedString (CocoaExtensions)

- (void)removeAllAttributesExcept:(NSArray *)exceptions
{
	[self enumerateAttributesInRange:NSMakeRange(0, [self length]) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
		[attrs enumerateKeysAndObjectsWithOptions:0 usingBlock:^(id key, id obj, BOOL *stop) {
			if (![exceptions containsObject:key]) {
				[self removeAttribute:key range:range];
			}
		}];
	}];
}

@end
