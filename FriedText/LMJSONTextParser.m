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
#define MAX_JSON_SIZE 1048576

@interface LMJSONTextParser () {
	jsmn_parser parser;
	jsmntok_t tokens[NUM_TOKENS];
}

@property (strong, nonatomic) NSData* data;
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

- (NSData *)data
{
	if (![self isStringValid]) {
		_data = [[self string] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	}
	return _data;
}

- (void)parse
{
	jsmn_init(&parser);
	char c[MAX_JSON_SIZE];
	memcpy(c, [[self data] bytes], MIN([[self data] length], MAX_JSON_SIZE));
	jsmnerr_t result = jsmn_parse(&parser, c, tokens, NUM_TOKENS);
	if (result != JSMN_SUCCESS) {
		
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
	
	for (unsigned int i = 0; i < parser.toknext; i++) {
		NSRange range = NSMakeRange(tokens[i].start, tokens[i].end-tokens[i].start);
		if (NSIntersectionRange(characterRange, range).length > 0) {
			if (tokens[i].type == JSMN_PRIMITIVE) {
				const char c = ((char *)[[self data] bytes])[tokens[i].start];
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
