//
//  NSMutableAttributedString+CocoaExtensions.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/14/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "NSMutableAttributedString+CocoaExtensions.h"
#import "LMTextParser.h"

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

- (void)highlightSyntaxWithParser:(id<LMTextParser>)parser
{
	[parser setStringBlock:^NSString *{
		return [self string];
	}];
	[parser invalidateString];
	
	[self beginEditing];
	
	[self removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, [self.string length])];
	
	NSColor* primitiveColor = [NSColor colorWithCalibratedRed:160.f/255.f green:208.f/255.f blue:202.f/255.f alpha:1.f];
	NSColor* stringColor = [NSColor colorWithCalibratedRed:33.f/255.f green:82.f/255.f blue:116.f/255.f alpha:1.f];
	
	[parser applyAttributesInRange:NSMakeRange(0, [self length]) withBlock:^(NSUInteger tokenTypeMask, NSRange range) {
		NSColor* color = nil;
		
		switch (tokenTypeMask & LMTextParserTokenTypeMask) {
			case LMTextParserTokenTypeBoolean:
				color = primitiveColor;
				break;
			case LMTextParserTokenTypeNumber:
				color = primitiveColor;
				break;
			case LMTextParserTokenTypeString:
				color = stringColor;
				break;
			case LMTextParserTokenTypeOther:
				color = primitiveColor;
				break;
		}
		
		
		[self addAttribute:NSForegroundColorAttributeName value:color range:range];
	}];
	
	[self endEditing];
}

@end
