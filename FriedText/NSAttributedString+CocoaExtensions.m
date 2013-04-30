//
//  NSAttributedString+CocoaExtensions.m
//  FriedText
//
//  Created by Micha Mazaheri on 4/30/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "NSAttributedString+CocoaExtensions.h"

@implementation NSAttributedString (CocoaExtensions)

- (NSTextAttachment *)attachmentAtIndex:(NSUInteger)index
{
	if (index >= [self length]) {
		return nil;
	}
	return [self attribute:NSAttachmentAttributeName atIndex:index effectiveRange:NULL];
}

@end
