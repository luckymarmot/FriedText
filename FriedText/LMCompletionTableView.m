//
//  LMCompletionTableView.m
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import "LMCompletionTableView.h"

#import "LMCompletionView.h"

@implementation LMCompletionTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		NSTableColumn* column = [[NSTableColumn alloc] initWithIdentifier:@"column"];
		[column setWidth:frame.size.width];
		[self addTableColumn:column];
		[self setHeaderView:nil];
		self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		self.focusRingType = NSFocusRingTypeNone;
		self.backgroundColor = [NSColor clearColor];
		self.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
		self.intercellSpacing = NSMakeSize(0.f, 0.f);
		self.rowHeight = 20.f;
    }
    
    return self;
}

- (BOOL)acceptsFirstResponder
{
//	NSLog(@"acceptsFirstResponder");
	return NO;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[super mouseDown:theEvent];
	if (theEvent.clickCount > 1) {
		[self.completionView doubleClicked];
	}
}

@end
