//
//  NSWindow+FriedText.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/15/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "NSWindow+FriedText.h"
#import <objc/runtime.h>

static char* _LMWindowFieldEditorsAssociationKey = "_LMWindowFieldEditorsAssociationKey";

@implementation NSWindow (FriedText)

- (void)setFieldEditor:(NSTextView *)fieldEditor forKey:(NSString *)key
{
	[[self fieldEditors] setObject:fieldEditor forKey:key];
}

- (NSTextView *)fieldEditorForKey:(NSString *)key
{
	return [[self fieldEditors] objectForKey:key];
}

- (NSMutableDictionary *)fieldEditors
{
	NSMutableDictionary* fieldEditors = objc_getAssociatedObject(self, _LMWindowFieldEditorsAssociationKey);
	if (fieldEditors == nil) {
		fieldEditors = [NSMutableDictionary dictionary];
		[self setFieldEditors:fieldEditors];
	}
	return fieldEditors;
}

- (void)setFieldEditors:(NSMutableDictionary *)fieldEditors
{
	objc_setAssociatedObject(self, _LMWindowFieldEditorsAssociationKey, fieldEditors, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
