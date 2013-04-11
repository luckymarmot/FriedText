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

LMTextView* _sharedFieldEditor = nil;

@implementation LMTextFieldCell

- (NSTextView *)fieldEditorForView:(NSView *)aControlView
{
	if ([[aControlView class] isSubclassOfClass:[LMTextField class]]) {
		if (_sharedFieldEditor == nil) {
			_sharedFieldEditor = [[LMTextView alloc] init];
			[_sharedFieldEditor setFieldEditor:YES];
			if ([(LMTextField*)aControlView parser]) {
				[_sharedFieldEditor setParser:[(LMTextField*)aControlView parser]];
			}
		}
		return _sharedFieldEditor;
	}
	return nil;
}

@end
