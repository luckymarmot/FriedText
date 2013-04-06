//
//  NSArray+KeyPath.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/6/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "NSArray+KeyPath.h"

@implementation NSArray (KeyPath)

- (NSString *)keyPathDescription
{
	NSMutableString* string = [NSMutableString string];
	for (id object in self) {
		if ([[object class] isSubclassOfClass:[NSString class]]) {
			if ([string length] > 0) {
				[string appendFormat:@".%@", object];
			}
			else {
				[string appendString:object];
			}
		}
		else if ([[object class] isSubclassOfClass:[NSNumber class]]) {
			[string appendFormat:@"[%@]", object];
		}
		else {
			[NSException raise:NSInternalInconsistencyException format:@"Key Path contains non string and non number objects"];
		}
	}
	return string;
}

@end
