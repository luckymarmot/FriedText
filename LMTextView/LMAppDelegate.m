//
//  LMAppDelegate.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/5/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMAppDelegate.h"

NSMutableArray* _windowControllers = nil;

@implementation LMAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[NSValueTransformer setValueTransformer:[[LMAttributedTokenStringValueTransformer alloc] init] forName:@"LMAttributedTokenStringValueTransformer"];
}

- (void)newDocument:(id)sender
{
	if (_windowControllers == nil) {
		_windowControllers = [NSMutableArray array];
	}
	
	NSWindowController* windowController = [[NSWindowController alloc] initWithWindowNibName:@"LMTextFieldWindow"];
	[windowController showWindow:[windowController window]];
	[_windowControllers addObject:windowController];
}

@end
