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
#import "LMTextView.h"

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

+ (id)attributedStringValueTransformerForTextView:(LMTextView *)textView
{
	LMAttributedStringValueTransformer* valueTransformer = [[LMAttributedStringValueTransformer alloc] initWithTextParser:[textView parser] defaultAttributes:[textView textAttributes] attributesBlock:^NSDictionary *(NSUInteger tokenTypeMask, NSRange range) {
		if ([textView delegate] && [[textView delegate] respondsToSelector:@selector(textView:attributesForTextWithParser:tokenMask:atRange:)]) {
			return [(id<LMTextViewDelegate>)[textView delegate] textView:textView attributesForTextWithParser:[textView parser] tokenMask:tokenTypeMask atRange:range];
		}
		else {
			return nil;
		}
	}];
	return valueTransformer;
}

- (id)init
{
	self = [super init];
	if (self) {
		self.parser = nil;
		self.attributesBlock = NULL;
		self.defaultAttributes = nil;
		self.useData = NO;
		self.stringDataEncoding = NSUTF8StringEncoding;
	}
	return self;
}

- (id)initWithTextParser:(id<LMTextParser>)parser defaultAttributes:(NSDictionary *)defaultAttributes attributesBlock:(NSDictionary *(^)(NSUInteger, NSRange))attributesBlock
{
	self = [self init];
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
	NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] init];
	if (value && value != [NSNull null]) {
		
		// Get the NSString
		NSString* string = value;
		if ([[value class] isSubclassOfClass:[NSData class]]) {
			string = [[NSString alloc] initWithData:(NSData*)value encoding:_stringDataEncoding];
		}
		
		// Get the raw NSAttributedString (with no attributes, or only attachments)
		if (_unarchivingBlock) {
			attributedString = _unarchivingBlock(string);
		}
		else {
			attributedString = [[NSMutableAttributedString alloc] initWithString:string];
		}
		
		// Highlight syntax
		if ([self parser]) {
			[attributedString highlightSyntaxWithParser:self.parser defaultAttributes:self.defaultAttributes attributesBlock:[self attributesBlock]];
		}
		// Or set only default attributes
		else if ([self defaultAttributes]) {
			[attributedString addAttributes:[self defaultAttributes] range:NSMakeRange(0, [attributedString length])];
		}
	}
	return attributedString;
}

- (id)reverseTransformedValue:(id)value
{
	if ([[value class] isSubclassOfClass:[NSAttributedString class]] || [[value class] isSubclassOfClass:[NSString class]]) {

		// Get the NSString
		NSString* string = nil;
		if ([[value class] isSubclassOfClass:[NSString class]]) {
			string = value;
		}
		else if (_archivingBlock) {
			string = _archivingBlock(value);
		}
		else {
			string = [(NSAttributedString*)value string];
		}
		
		// Encode to NSData if necessary
		if (!_useData) {
			return string;
		}
		else {
			return [string dataUsingEncoding:_stringDataEncoding];
		}
	}
	else {
		return value;
	}
}

@end
