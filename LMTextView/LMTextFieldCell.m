//
//  LMTextFieldCell.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/11/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMTextFieldCell.h"
#import "LMTextView.h"
#import "LMTextField.h"

#warning Won't Work with Multiple Windows
LMTextView* _sharedFieldEditor = nil;

@interface LMTextFieldCell ()

@end

@implementation LMTextFieldCell

#pragma mark - Initializers

- (id)init
{
	self = [super init];
	if (self) {
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
	}
	return self;
}

#pragma mark - Accessors

- (BOOL)allowsEditingTextAttributes
{
	// Forcing this value allows us to keep tokens
	return YES;
}

- (NSTextView *)fieldEditorForView:(NSView *)aControlView
{
	if ([[aControlView class] isSubclassOfClass:[LMTextField class]]) {
		if (_sharedFieldEditor == nil) {
			_sharedFieldEditor = [[LMTextView alloc] init];
			[_sharedFieldEditor setFieldEditor:YES];
			if ([(LMTextField*)aControlView parser]) {
				[_sharedFieldEditor setParser:[(LMTextField*)aControlView parser]];
			}
			else {
				[_sharedFieldEditor setParser:nil];
			}
		}
		return _sharedFieldEditor;
	}
	return nil;
}

@end
