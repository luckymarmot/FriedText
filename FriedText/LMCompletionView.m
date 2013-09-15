//
//  LMCompletionView.m
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import "LMCompletionView.h"

#import "LMCompletionTableView.h"
#import "LMCompletionTableCellView.h"

#import "NSView+CocoaExtensions.h"

@interface LMCompletionView () <NSTableViewDataSource, NSTableViewDelegate> {
	id<LMCompletionOption> _lastCompletionOption;
}

@end

@implementation LMCompletionView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		_textFieldHeight = 40.f;
		_completionInset = CGSizeMake(10.f, 10.f);
		_lastCompletionOption = nil;
		
		NSRect scrollViewFrame = NSMakeRect(_completionInset.width,
											_textFieldHeight + _completionInset.height,
											frame.size.width - _completionInset.width * 2,
											frame.size.height - _textFieldHeight - _completionInset.height * 2);
		NSScrollView* enclosingScrollView = [[NSScrollView alloc] initWithFrame:scrollViewFrame];
		enclosingScrollView.focusRingType = NSFocusRingTypeNone;
		enclosingScrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		enclosingScrollView.backgroundColor = [NSColor clearColor];
		enclosingScrollView.drawsBackground = NO;
		self.tableView = [[LMCompletionTableView alloc] initWithFrame:enclosingScrollView.bounds];
		
		self.tableView.dataSource = self;
		self.tableView.delegate = self;
		[self.tableView reloadData];
		[enclosingScrollView setDocumentView:self.tableView];
		[enclosingScrollView setHasVerticalScroller:YES];
		[self addSubview:enclosingScrollView];
		
		self.tableView.completionView = self;
		
		self.autoresizesSubviews = YES;
		self.focusRingType = NSFocusRingTypeNone;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	//// Color Declarations
	NSColor* strokeColor = [NSColor colorWithCalibratedWhite:0.3f alpha:.5f];
	NSColor* bgColor = [NSColor colorWithCalibratedWhite:0.97f alpha:1.0f];
	
	//// Frames
	NSRect frame = NSInsetRect(self.bounds, _completionInset.width, _completionInset.height);
	NSRect rectangleFrame = NSInsetRect(frame, 0.5f, 0.5f);
	
	//// Rectangle Drawing
	CGFloat radius = 0.f;
	NSBezierPath* rectanglePath = [NSBezierPath bezierPathWithRoundedRect:rectangleFrame xRadius:radius yRadius:radius];
	NSShadow* rectangleShadow = [[NSShadow alloc] init];
	[rectangleShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0f alpha:0.6f]];
	[rectangleShadow setShadowOffset:NSMakeSize(0.1, -2.1)];
	[rectangleShadow setShadowBlurRadius:4.f];

	[NSGraphicsContext saveGraphicsState];
	[rectangleShadow set];
	[bgColor setFill];
	[rectanglePath fill];
	[NSGraphicsContext restoreGraphicsState];
	[strokeColor setStroke];
	[rectanglePath setLineWidth: 1];
	[rectanglePath stroke];
	
	NSBezierPath* linePath = [NSBezierPath bezierPathWithRect:NSMakeRect(frame.origin.x, frame.origin.y + _textFieldHeight - 1.f, frame.size.width, 1.f)];
	NSGradient* lineGradient = [[NSGradient alloc] initWithColorsAndLocations:
								[NSColor colorWithCalibratedWhite:0.f alpha:0.f], 0.0f,
								[NSColor colorWithCalibratedWhite:0.f alpha:0.3f], 0.5f,
								[NSColor colorWithCalibratedWhite:0.f alpha:0.f], 1.0f,
								nil];
	NSShadow* lineShadow = [[NSShadow alloc] init];
	[lineShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0f alpha:0.6f]];
	[lineShadow setShadowOffset:NSMakeSize(0.1, 1.1)];
	[lineShadow setShadowBlurRadius:2.f];
	
	[NSGraphicsContext saveGraphicsState];
	[lineShadow set];
	CGContextBeginTransparencyLayer(context, NULL);
	[lineGradient drawInBezierPath:linePath angle:0.f];
	CGContextEndTransparencyLayer(context);
	[NSGraphicsContext restoreGraphicsState];
	
	//// Text
	NSColor* textColor = [NSColor blackColor];
	
	NSMutableParagraphStyle* textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
	[textStyle setAlignment: NSLeftTextAlignment];
	
	NSFont* font = [NSFont systemFontOfSize:10.f];
	NSString* completingDescription = [self currentCompletionComment];
	if ([completingDescription length] == 0) {
		font = [[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Helvetica" size:10.f] toHaveTrait:NSItalicFontMask];
		completingDescription = @"No description";
	}
	NSMutableDictionary* textFontAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											   font, NSFontAttributeName,
											   textColor, NSForegroundColorAttributeName,
											   textStyle, NSParagraphStyleAttributeName, nil];
	
	CGRect textRect = CGRectMake(10.f + _completionInset.width,
								 7.f + _completionInset.height,
								 frame.size.width - 20.f,
								 _textFieldHeight - 14.f);
	
	if (completingDescription) {
		[completingDescription drawWithRect:textRect options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin attributes:textFontAttributes];
	}
}

- (void)setCompletions:(NSArray *)completions
{
	[self setCompletions:completions reload:YES];
}

- (void)setCompletions:(NSArray *)completions reload:(BOOL)reload
{
	_completions = completions;
	
	if (reload) {
		[self.tableView reloadData];
	}
	
	NSInteger row = [completions indexOfObject:_lastCompletionOption];
	[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(row == NSNotFound ? 0 : row)] byExtendingSelection:NO];
}

- (void)selectNextCompletion
{
	[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:MIN(self.tableView.numberOfRows - 1, self.tableView.selectedRow + 1)] byExtendingSelection:NO];
	[self.tableView scrollRowToVisible:self.tableView.selectedRow];
}

- (void)selectPreviousCompletion
{
	[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:MAX(0, self.tableView.selectedRow - 1)] byExtendingSelection:NO];
	[self.tableView scrollRowToVisible:self.tableView.selectedRow];
}

- (void)selectFirstCompletion
{
	[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[self.tableView scrollRowToVisible:self.tableView.selectedRow];
}

- (void)selectLastCompletion
{
	[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.tableView.numberOfRows - 1] byExtendingSelection:NO];
	[self.tableView scrollRowToVisible:self.tableView.selectedRow];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [_completions count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	LMCompletionTableCellView* view = [[LMCompletionTableCellView alloc] init];
	view.completionOption = [_completions objectAtIndex:row];
	return view;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self willChangeValueForKey:@"currentCompletionOption"];
	[self didChangeValueForKey:@"currentCompletionOption"];
	_lastCompletionOption = [self currentCompletionOption];
	[self setWantsLayer:NO];
	[self setNeedsDisplay:YES];
}

- (id<LMCompletionOption>)currentCompletionOption
{
	if (self.tableView.selectedRow >= 0) {
		return [_completions objectAtIndex:self.tableView.selectedRow];
	}
	else {
		return nil;
	}
}

- (NSString *)currentCompletionString
{
	if (self.tableView.selectedRow >= 0) {
		id<LMCompletionOption> completionEntry = [_completions objectAtIndex:self.tableView.selectedRow];
		return [completionEntry stringValue];
	}
	else {
		return nil;
	}
}

- (NSString *)currentCompletionComment
{
	if (self.tableView.selectedRow >= 0) {
		id<LMCompletionOption> completionEntry = [_completions objectAtIndex:self.tableView.selectedRow];
		if ([completionEntry respondsToSelector:@selector(comment)]) {
			return [completionEntry comment];
		}
		else {
			return nil;
		}
	}
	else {
		return nil;
	}
}

- (void)doubleClicked
{
	[self.delegate didSelectCompletionOption:[self currentCompletionOption]];
}

- (NSSize)intrinsicContentSize
{
	CGFloat completionWidth = 300.f;
	CGFloat completionHeight =	self.tableView.rowHeight * MIN([self.completions count], 10) +
								self.textFieldHeight +
								self.completionInset.height * 2;
	return NSMakeSize(completionWidth, completionHeight);
}

@end
