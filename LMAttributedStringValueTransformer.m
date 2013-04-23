//
//  LMAttributedStringValueTransformer.m
//  FriedText
//
//  Created by Micha Mazaheri on 4/23/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMAttributedStringValueTransformer.h"

@implementation LMAttributedStringValueTransformer

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

+ (Class)transformedValueClass
{
	return [NSString class];
}

- (id)transformedValue:(id)value
{
	return value;
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
