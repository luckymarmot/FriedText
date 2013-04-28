//
//  LMXMLTextParser.m
//  FriedText
//
//  Created by Micha Mazaheri on 4/28/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMXMLTextParser.h"

@interface LMXMLTextParser () <NSXMLParserDelegate> {
	BOOL _applyAttributes;
	NSRange _range;
	void (^_block)(NSUInteger, NSRange);
	NSUInteger _lengthBeforeLine;
	NSUInteger _currentLineNumber;
}

@property (strong, nonatomic) NSData* data;
@property (strong, nonatomic) NSString* string;

@property (strong, nonatomic) NSXMLParser* xmlParser;

@property (nonatomic, getter = isStringValid) BOOL stringIsValid;

@end

@implementation LMXMLTextParser

@synthesize stringBlock = _stringBlock;

- (void)invalidateString
{
	_stringIsValid = NO;
}

- (NSString *)string
{
	if (![self isStringValid]) {
		if ([self stringBlock]) {
			_string = [self stringBlock]();
		}
		_stringIsValid = YES;
	}
	return _string;
}

- (NSData *)data
{
	if (![self isStringValid]) {
		_data = [[self string] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	}
	return _data;
}

- (void)parse
{
	self.xmlParser = [[NSXMLParser alloc] initWithData:self.data];
	[self.xmlParser setDelegate:self];
	[self.xmlParser setShouldProcessNamespaces:NO];
	[self.xmlParser setShouldReportNamespacePrefixes:NO];
	[self.xmlParser setShouldResolveExternalEntities:NO];
	[self.xmlParser parse];
}

- (void)applyAttributesInRange:(NSRange)range withBlock:(void (^)(NSUInteger, NSRange))block
{
	if (block == NULL) {
		return;
	}
	
	_applyAttributes = YES;
	_range = range;
	_block = block;
	_lengthBeforeLine = 0;
	_currentLineNumber = 1;
	
	[self parse];
	
	_applyAttributes = NO;
	_range = NSMakeRange(NSNotFound, 0);
	_block = NULL;
	_lengthBeforeLine = 0;
	_currentLineNumber = 0;
}

- (NSArray *)keyPathForObjectAtRange:(NSRange)range objectRange:(NSRange *)correctedRange
{
	return nil;
}

- (void)_updatePosition
{
	NSUInteger lineNumber = [_xmlParser lineNumber];
	
	while (lineNumber > _currentLineNumber) {
		const char * bytes = [_data bytes];
		while (bytes[_lengthBeforeLine] != '\n') {
			++_lengthBeforeLine;
		}
		++_lengthBeforeLine;
		
		++_currentLineNumber;
	}
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	[self _updatePosition];
	
//	NSLog(@"Line: %ld, Column: %ld, Position: %ld: elementName: %@", [_xmlParser lineNumber], [_xmlParser columnNumber], _lengthBeforeLine, elementName);
	
	NSLog(@"media:thumbnail start: %ld %@", [_xmlParser columnNumber], [[NSString alloc] initWithBytes:([_data bytes]+_lengthBeforeLine) length:[_xmlParser columnNumber] encoding:NSUTF8StringEncoding]);
	
	NSRange range = NSMakeRange(_lengthBeforeLine + [_xmlParser columnNumber] - [elementName length] - 1, [elementName length]);
	
	_block(LMTextParserTokenTypeString, range);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	[self _updatePosition];
	
	if ([elementName isEqualToString:@"media:thumbnail"]) {
		NSLog(@"media:thumbnail end: %ld", [_xmlParser columnNumber]);
	}
	
	NSRange range = NSMakeRange(_lengthBeforeLine + [_xmlParser columnNumber] - [elementName length] - 2, [elementName length]);
	
	_block(LMTextParserTokenTypeString, range);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[self _updatePosition];
	
//	NSLog(@"Characters: %@", string);
}

- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString
{
	[self _updatePosition];
	
//	NSLog(@"Whitespaces: %ld", [whitespaceString length]);
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	
}

@end
