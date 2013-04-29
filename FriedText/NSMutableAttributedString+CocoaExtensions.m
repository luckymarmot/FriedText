//
//  NSMutableAttributedString+CocoaExtensions.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/14/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "NSMutableAttributedString+CocoaExtensions.h"
#import "LMTextParser.h"
#import "LMFriedTextDefaultColors.h"

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

- (void)highlightSyntaxWithParser:(id<LMTextParser>)parser defaultAttributes:(NSDictionary*)defaultAttributes attributesBlock:(NSDictionary *(^)(NSUInteger, NSRange))attributesBlock
{
	[parser setStringBlock:^NSString *{
		return [self string];
	}];
	[parser invalidateString];
	
	[self beginEditing];
	
	// Remove attributes
	[self removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, [self.string length])];
	[defaultAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[self removeAttribute:key range:NSMakeRange(0, [self.string length])];
	}];

	// Set Default Attributes
	[self addAttributes:defaultAttributes range:NSMakeRange(0, [self.string length])];

	[parser applyAttributesInRange:NSMakeRange(0, [self length]) withBlock:^(NSUInteger tokenTypeMask, NSRange range) {
		
		NSDictionary* attributes = nil;
		if (attributesBlock) {
			attributes = attributesBlock(tokenTypeMask, range);
		}
		
		if (attributes == nil) {
			NSColor* color = nil;
			switch (tokenTypeMask & LMTextParserTokenTypeMask) {
				case LMTextParserTokenTypeBoolean:
					color = LMFriedTextDefaultColorPrimitive;
					break;
				case LMTextParserTokenTypeNumber:
					color = LMFriedTextDefaultColorPrimitive;
					break;
				case LMTextParserTokenTypeString:
					color = LMFriedTextDefaultColorString;
					break;
				case LMTextParserTokenTypeOther:
					color = LMFriedTextDefaultColorPrimitive;
					break;
			}
			attributes = @{NSForegroundColorAttributeName: color};
		}
		
		
		[self addAttributes:attributes range:range];
	}];
	
	[self endEditing];
}

@end
