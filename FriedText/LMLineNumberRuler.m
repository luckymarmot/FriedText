//
//  LMLineNumberRuler.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/10/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMLineNumberRuler.h"

@interface LMLineNumberRuler () {
	NSUInteger * _lineStartCharacterIndexes;
	size_t _lineStartCharacterIndexesCount;
}

@property (getter=isLineInformationValid) BOOL lineInformationValid;

- (NSDictionary *)textAttributes;

@end

@implementation LMLineNumberRuler

- (id)initWithTextView:(NSTextView *)textView
{
    self = [self initWithScrollView:[textView enclosingScrollView] orientation:NSVerticalRuler];
    if (self) {
        self.font = [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]];
        self.textColor = [NSColor darkGrayColor];
        self.backgroundColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
		[self setClientView:textView];
		
		_lineStartCharacterIndexes = NULL;
		_lineStartCharacterIndexesCount = 0;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundsDidChange:) name:NSViewBoundsDidChangeNotification object:textView.enclosingScrollView.contentView];
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)boundsDidChange:(NSNotification*)notification
{
	// When the text view is using non-contiguous layout, it is necessary to redraw the whole NSRulerView to prevent some pixels to be drawn incorrectly, this decrease performance, but disabling non-contiguous layout performance drop is much much worse
	if ([[(NSTextView*)self.clientView layoutManager] hasNonContiguousLayout]) {
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)setClientView:(NSView *)clientView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTextStorageDidProcessEditingNotification object:nil];
    
    [super setClientView:clientView];
    
    if ([clientView isKindOfClass:[NSTextView self]]) {
        NSTextStorage *textStorage = [(NSTextView *)clientView textStorage];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientTextStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:textStorage];
    }
}

- (void)clientTextStorageDidProcessEditing:(NSNotification *)notification
{
    self.lineInformationValid = NO;
    
    [self setNeedsDisplay:YES];
}

- (NSTextStorage *)currentTextStorage
{
    NSView *clientView = [self clientView];
    return [clientView isKindOfClass:[NSTextView self]] ? [(NSTextView *)clientView textStorage] : nil;
}

- (void)updateLineInformation
{
    NSMutableIndexSet *mutableLineStartCharacterIndexes = [NSMutableIndexSet indexSet];
    
    NSString *clientString = [[self currentTextStorage] string];
	
	NSLog(@"Client String: {%@}", clientString);
    
    [clientString enumerateSubstringsInRange:NSMakeRange(0, [clientString length]) options:NSStringEnumerationByLines|NSStringEnumerationSubstringNotRequired usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        [mutableLineStartCharacterIndexes addIndex:substringRange.location];
    }];
	if ([clientString length] > 0 && [[NSCharacterSet newlineCharacterSet] characterIsMember:[clientString characterAtIndex:([clientString length] - 1)]]) {
		 [mutableLineStartCharacterIndexes addIndex:([clientString length] - 1)];
	}
	
	NSLog(@"mutableLineStartCharacterIndexes:");
	[mutableLineStartCharacterIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		NSLog(@"> %ld", idx);
	}];
    
    const NSUInteger numberOfLines = [mutableLineStartCharacterIndexes count];
    const NSUInteger newLineStartCharacterIndexesSize = numberOfLines * sizeof(NSUInteger);
	
	// If there is more lines, we may need to re-allocate
    if (numberOfLines > _lineStartCharacterIndexesCount || _lineStartCharacterIndexes == NULL) {
		// If already existing, re-allocate
        if (_lineStartCharacterIndexes != NULL) {
            void * newIndexes = NSReallocateCollectable(_lineStartCharacterIndexes, newLineStartCharacterIndexesSize, 0);
			// If re-allocation failed, return
            if (!newIndexes) {
                return;
            }
            _lineStartCharacterIndexes = newIndexes;
        }
		// If not existing, allocate
        else {
            _lineStartCharacterIndexes = NSAllocateCollectable(newLineStartCharacterIndexesSize, 0);
			// If allocation failed, return
            if (!_lineStartCharacterIndexes) {
				return;
			}
        }
    }
	
	// Set new number of lines
	_lineStartCharacterIndexesCount = numberOfLines;
    
	// Get indexes from the mutable set
    if (_lineStartCharacterIndexes) {
        [mutableLineStartCharacterIndexes getIndexes:_lineStartCharacterIndexes maxCount:_lineStartCharacterIndexesCount inIndexRange:NULL];
    }
	
	NSLog(@"_lineStartCharacterIndexes:");
	for (int i = 0; i < _lineStartCharacterIndexesCount; i++) {
		NSLog(@"> %ld", _lineStartCharacterIndexes[i]);
	}
    
    self.lineInformationValid = YES;
    
    // update the thickness
    const double numberOfDigits = numberOfLines > 0 ? ceil(log10(numberOfLines)) : 1;
    
    // get the size of a digit to use
    const NSSize digitSize = [@"0" sizeWithAttributes:[self textAttributes]];
    const CGFloat newRuleThickness = MAX(ceil(digitSize.width * numberOfDigits + 8.0), 10.0);
    
    [self setRuleThickness:newRuleThickness];
}

- (void)viewWillDraw
{
    [super viewWillDraw];
	
    if (!self.lineInformationValid) {
        [self updateLineInformation];
    }
}

- (NSUInteger)lineIndexForCharacterIndex:(NSUInteger)characterIndex
{
    if (!_lineStartCharacterIndexes) {
        return NSNotFound;
    }
    
    NSUInteger *foundIndex = bsearch_b(&characterIndex, _lineStartCharacterIndexes, _lineStartCharacterIndexesCount, sizeof(NSUInteger), ^(const void *arg1, const void *arg2) {
        const NSUInteger int1 = *(NSUInteger *)arg1;
        const NSUInteger int2 = *(NSUInteger *)arg2;
        if (int1 < int2) {
            return -1;
        }
        else if (int1 > int2) {
            return 1;
        }
        else {
            return 0;
        }
    });
    
    return foundIndex ? (foundIndex-_lineStartCharacterIndexes) : NSNotFound;
}

- (NSDictionary *)textAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:self.font, NSFontAttributeName, self.textColor, NSForegroundColorAttributeName, nil];
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)dirtyRect
{
    const NSRect bounds = [self bounds];
    
    [_backgroundColor set];
    NSRectFill(dirtyRect);
    
    NSRect borderLineRect = NSMakeRect(NSMaxX(bounds)-1.0, 0, 1.0, NSHeight(bounds));
    
    if ([self needsToDrawRect:borderLineRect]) {
        [[_backgroundColor shadowWithLevel:0.4] set];
        NSRectFill(borderLineRect);
    }
    
    NSView *clientView = [self clientView];
    if (![clientView isKindOfClass:[NSTextView self]]) {
        return;
    }
    
    NSTextView *textView = (NSTextView *)clientView;
    NSLayoutManager *layoutManager = [textView layoutManager];
    NSTextContainer *textContainer = [textView textContainer];
    NSTextStorage *textStorage = [textView textStorage];
    NSString *textString = [textStorage string];
    const NSRect visibleRect = self.scrollView.contentView.visibleRect;
    const NSSize textContainerInset = [textView textContainerInset];
    const CGFloat rightMostDrawableLocation = NSMinX(borderLineRect);
	const CGRect dirtyRectForTextView = [self convertRect:dirtyRect toView:textView];
	const CGRect glyphRect = NSMakeRect(textView.bounds.origin.x, dirtyRectForTextView.origin.y-20, textView.bounds.size.width, dirtyRectForTextView.size.height+40);
    
    const NSRange visibleGlyphRange = [layoutManager glyphRangeForBoundingRect:glyphRect inTextContainer:textContainer];
    const NSRange visibleCharacterRange = [layoutManager characterRangeForGlyphRange:visibleGlyphRange actualGlyphRange:NULL];
    
    NSDictionary *textAttributes = [self textAttributes];
	
    CGFloat lastLinePositionY = -1.0;
	
//	NSLog(@"Visible: {%@}(%ld)", [[textView string] substringWithRange:visibleCharacterRange], visibleCharacterRange.length);
	
	NSUInteger characterIndex;
	
    for (NSUInteger lineNumber = [self lineIndexForCharacterIndex:visibleCharacterRange.location]; ; ) {
		
		if (lineNumber >= _lineStartCharacterIndexesCount ||
			(characterIndex = _lineStartCharacterIndexes[lineNumber]) >= visibleCharacterRange.location + visibleCharacterRange.length) {
			NSLog(@"Last line: %ld", lineNumber);
			break;
		}
		
		
//		NSLog(@"lineNumber: %ld characterIndex: %ld", lineNumber, characterIndex);
        if (lineNumber == NSNotFound) {
            break;
        }
        
        NSUInteger layoutRectCount;
        NSRectArray layoutRects = [layoutManager rectArrayForCharacterRange:NSMakeRange(characterIndex, 0) withinSelectedCharacterRange:NSMakeRange(NSNotFound, 0) inTextContainer:textContainer rectCount:&layoutRectCount];
        if (layoutRectCount == 0) {
            break;
        }
		
		NSLog(@"> Line: %ld | %@", lineNumber, [textString substringWithRange:NSMakeRange(characterIndex, MIN([textString length]-characterIndex, 1))]);
		for (NSUInteger k=0; k<layoutRectCount;k++) {
			NSLog(@"  > %ld: %@", k, NSStringFromRect(layoutRects[k]));
		}
        
        NSString *lineString = [NSString stringWithFormat:@"%lu", (NSUInteger)lineNumber+1];
        const NSSize lineStringSize = [lineString sizeWithAttributes:textAttributes];
        const NSRect lineStringRect = NSMakeRect(floor(rightMostDrawableLocation - lineStringSize.width - 2.0),
												 floor(NSMinY(layoutRects[0]) + textContainerInset.height - NSMinY(visibleRect) + (NSHeight(layoutRects[0]) - lineStringSize.height) / 2.0),
												 ceil(lineStringSize.width),
												 ceil(lineStringSize.height));
        
		if ([self needsToDrawRect:NSInsetRect(lineStringRect, -4.0, -4.0)] && (NSMinY(lineStringRect) != lastLinePositionY)) {
			[lineString drawWithRect:lineStringRect options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttributes];
		}
		
        lastLinePositionY = NSMinY(lineStringRect);
		
//		if (characterIndex == visibleCharacterRange.location + visibleCharacterRange.length) {
//			break;
//		}
		
//		NSLog(@"1:characterIndex %ld", characterIndex);
//        [textString getLineStart:NULL end:&characterIndex contentsEnd:NULL forRange:NSMakeRange(characterIndex, 0)];
//		NSRange newLineRange = [textString rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:kNilOptions range:NSMakeRange(characterIndex, [textString length] - characterIndex)];
//		if (newLineRange.location == NSNotFound) {
//			break;
//		}
//		else {
//			characterIndex = newLineRange;
//		}
//		NSLog(@"2:characterIndex %ld", characterIndex);
		
		
		
		lineNumber++;
    }
	
//	NSLog(@"LAST characterIndex: %ld", characterIndex);
}

@end
