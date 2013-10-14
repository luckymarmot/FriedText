//
//  LMJSONTextParser.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/6/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMJSONTextParser.h"

#import "jsmn.h"

#warning Parsing will stop when NUM_TOKENS is exceeded

#define NUM_TOKENS 1048576

@interface LMJSONTextParser () {
	jsmn_parser parser;
	jsmntok_t tokens[NUM_TOKENS];
}

@property (strong, nonatomic) NSString* string;

@property (nonatomic, getter = isStringValid) BOOL stringIsValid;

@end

@implementation LMJSONTextParser

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

- (void)parse
{
	jsmn_init(&parser);
	jsmnerr_t result = jsmn_parse(&parser, (__bridge CFStringRef)[self string], tokens, NUM_TOKENS);
	if (result != JSMN_SUCCESS) {
//		Ignore errors
//		parser.toknext = 0;
//		If making the parser more strict, make jsmn strict too
	}
}

- (void)applyAttributesInRange:(NSRange)characterRange withBlock:(void (^)(NSUInteger, NSRange))block
{
	if (block == NULL) {
		return;
	}
	
	if (![self isStringValid]) {
		[self parse];
	}
	
	NSString* string = [self string];
	
	for (unsigned int i = 0; i < parser.toknext; i++) {
		NSRange range = NSMakeRange(tokens[i].start, tokens[i].end-tokens[i].start);
		if (range.location >= characterRange.location &&
			range.location + range.length <= characterRange.location + characterRange.length) {
			if (tokens[i].type == JSMN_PRIMITIVE) {
				unichar c = [string characterAtIndex:tokens[i].start];
				if (c == 't') {
					block(LMTextParserTokenTypeBoolean | LMTextParserTokenJSONTypeTrue, range);
				}
				else if (c == 'f') {
					block(LMTextParserTokenTypeBoolean | LMTextParserTokenJSONTypeFalse, range);
				}
				else if (c == 'n') {
					block(LMTextParserTokenTypeOther | LMTextParserTokenJSONTypeNull, range);
				}
				else {
					block(LMTextParserTokenTypeNumber, range);
				}
			}
			else if (tokens[i].type == JSMN_STRING) {
				block(LMTextParserTokenTypeString, range);
			}
		}
	}
}

- (NSArray *)keyPathForObjectAtRange:(NSRange)range objectRange:(NSRange *)objectRange
{
	if (![self isStringValid]) {
		[self parse];
	}
	
	for (unsigned int i = 0; i < parser.toknext; i++) {
		if (tokens[i].type == JSMN_PRIMITIVE || tokens[i].type == JSMN_STRING) {
			if (range.location >= tokens[i].start && range.location+range.length <= tokens[i].end) {
				NSRange range = NSMakeRange(tokens[i].start, tokens[i].end-tokens[i].start);
				
				*objectRange = range;
				
				NSMutableArray* path = [NSMutableArray array];
				for (unsigned int j = i; tokens[j].parent != (-1); j = tokens[j].parent) {
					
					jsmntype_t parentType = tokens[tokens[j].parent].type;
					
					if (parentType == JSMN_OBJECT) {
						unsigned int previousToken = j-(tokens[j].posinparent%2);
						[path insertObject:[self.string substringWithRange:NSMakeRange(tokens[previousToken].start, tokens[previousToken].end-tokens[previousToken].start)] atIndex:0];
					}
					else if (parentType == JSMN_ARRAY) {
						[path insertObject:@(tokens[j].posinparent) atIndex:0];
					}
				}
				
				return path;
			}
		}
	}
	
	*objectRange = NSMakeRange(NSNotFound, 0);
	
	return nil;
}

@end
