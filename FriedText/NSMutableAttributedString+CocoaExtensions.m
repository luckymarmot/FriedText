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
	[self enumerateAttributesInRange:NSMakeRange(0, [self length]) options:kNilOptions usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
		[attrs enumerateKeysAndObjectsWithOptions:kNilOptions usingBlock:^(id key, id obj, BOOL *stop) {
			if (![exceptions containsObject:key]) {
				[self removeAttribute:key range:range];
			}
		}];
	}];
}

- (void)highlightSyntaxWithParser:(id<LMTextParser>)parser defaultAttributes:(NSDictionary*)defaultAttributes attributesBlock:(NSDictionary *(^)(NSUInteger, NSRange))attributesBlock
{
	// Backup the current parser's string block, to restore it after highlighting
	// It is common pattern to use same parser for field editor and binding value transformer,
	// so we should care both won't interfere
	NSString*(^previousParserStringBlock)(void) = [parser stringBlock];
	
	// Set custom string block, and invalidate string
	[parser setStringBlock:^NSString *{
		return [self string];
	}];
	[parser invalidateString];
	
	// Batch changes between begin/end editing calls
	[self beginEditing];
	
	// Remove attributes
	[self removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, [self.string length])];
	[defaultAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		[self removeAttribute:key range:NSMakeRange(0, [self.string length])];
	}];

	// Set Default Attributes
	[self addAttributes:defaultAttributes range:NSMakeRange(0, [self.string length])];
	
	// Call parser's method to set attributes giving the block
	[parser applyAttributesInRange:NSMakeRange(0, [self length]) withBlock:^(NSUInteger tokenTypeMask, NSRange range) {
		
		NSDictionary* attributes = nil;
		
		// Trying to use attributes provided by `attributesBlock`
		if (attributesBlock) {
			attributes = attributesBlock(tokenTypeMask, range);
		}
		
		// If no attributes set (not even an empty dictionary), set default ones
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
		
		// Set attributes
		[self addAttributes:attributes range:range];
	}];
	
	// End batch changes
	[self endEditing];
	
	// Restore previous string block & invalidate string
	[parser setStringBlock:previousParserStringBlock];
	[parser invalidateString];
}

@end
