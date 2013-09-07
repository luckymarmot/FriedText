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
#import "NSWindow+FriedText.h"

@interface LMTextFieldCell ()

@end

@implementation LMTextFieldCell

#pragma mark - NSCell Overrides

- (BOOL)allowsEditingTextAttributes
{
	// Forcing this value allows us to keep tokens
	return YES;
}

- (NSTextView *)fieldEditorForView:(NSView *)aControlView
{
	if ([[aControlView class] isSubclassOfClass:[LMTextField class]]) {
		// Always keep the same field editors for all LMTextFields within the same NSWindow
		NSTextView* fieldEditor = [[aControlView window] fieldEditorForKey:NSStringFromClass([LMTextFieldCell class])];
		if (fieldEditor == nil) {
			fieldEditor = [[LMTextView alloc] init];
			[fieldEditor setFieldEditor:YES];
			[[aControlView window] setFieldEditor:fieldEditor forKey:NSStringFromClass([LMTextFieldCell class])];
		}
		return fieldEditor;
	}
	return nil; // If control is not a LMTextField, use standard field editor
}

@end
