//
//  LMAttributedStringValueTransformer.m
//  FriedText
//
//  Created by Micha Mazaheri on 4/23/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMAttributedStringValueTransformer.h"
#import "NSMutableAttributedString+CocoaExtensions.h"

#import "LMTextField.h"

@implementation LMAttributedStringValueTransformer

+ (id)attributedStringValueTransformerForTextField:(LMTextField *)textField
{
	LMAttributedStringValueTransformer* valueTransformer = [[LMAttributedStringValueTransformer alloc] initWithTextParser:[textField parser] defaultAttributes:[textField textAttributes] attributesBlock:^NSDictionary *(NSUInteger tokenTypeMask, NSRange range) {
		if ([textField delegate] && [[textField delegate] respondsToSelector:@selector(textField:fieldEditor:attributesForTextWithParser:tokenMask:atRange:)]) {
			return [(id<LMTextFieldDelegate>)[textField delegate] textField:textField fieldEditor:(LMTextView*)[textField currentEditor] attributesForTextWithParser:[textField parser] tokenMask:tokenTypeMask atRange:range];
		}
		else {
			return nil;
		}
	}];
	return valueTransformer;
}

- (id)initWithTextParser:(id<LMTextParser>)parser defaultAttributes:(NSDictionary *)defaultAttributes attributesBlock:(NSDictionary *(^)(NSUInteger, NSRange))attributesBlock
{
	self = [super init];
	if (self) {
		self.parser = parser;
		self.attributesBlock = attributesBlock;
		self.defaultAttributes = defaultAttributes;
	}
	return self;
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

+ (Class)transformedValueClass
{
	return [NSAttributedString class];
}

- (id)transformedValue:(id)value
{
	NSMutableAttributedString* attributedString;
	if (value && value != [NSNull null]) {
		attributedString = [[NSMutableAttributedString alloc] initWithString:value];
		if ([self parser]) {
			[attributedString highlightSyntaxWithParser:self.parser defaultAttributes:self.defaultAttributes attributesBlock:[self attributesBlock]];
		}
		else if ([self defaultAttributes]) {
			[attributedString setAttributes:[self defaultAttributes] range:NSMakeRange(0, [attributedString length])];
		}
	}
	return attributedString;
}

- (id)reverseTransformedValue:(id)value
{
	if ([[value class] isSubclassOfClass:[NSAttributedString class]]) {
		return [(NSAttributedString*)value string];
	}
	else {
		return value;
	}
}

@end
