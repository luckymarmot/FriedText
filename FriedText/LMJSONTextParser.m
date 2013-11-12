//
//  LMJSONTextParser.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/6/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMJSONTextParser.h"

#import "jsmn.h"

#define INITIAL_NUM_TOKENS 65536

@interface LMJSONTextParser () {
	jsmn_parser _parser;
	jsmntok_t *_tokens;
	unsigned int _numTokens;
}

@property (strong, nonatomic) NSString* string;

@property (nonatomic, getter = isStringValid) BOOL stringIsValid;

@end

@implementation LMJSONTextParser

@synthesize stringBlock = _stringBlock;

- (id)init
{
	self = [super init];
	if (self) {
		_tokens = NULL;
		_numTokens = 0;
	}
	return self;
}

- (void)dealloc
{
	if (_tokens != NULL) {
		free(_tokens);
	}
}

#pragma mark - LMTextParser Basics

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
	jsmn_init(&_parser);
	if (_tokens == NULL) {
		_numTokens = INITIAL_NUM_TOKENS; // an arbitrary size to start with
		_tokens = malloc(sizeof(jsmntok_t) * _numTokens);
	}
	while (_tokens != NULL) {
		jsmnerr_t error = jsmn_parse(&_parser, (__bridge CFStringRef)[self string], _tokens, _numTokens);
		
		// If no error, break
		if (error == JSMN_SUCCESS) {
			break;
		}
		// If not enough memory, realloc twice bigger
		else if (error == JSMN_ERROR_NOMEM) {
			_numTokens *= 2;
			_tokens = realloc(_tokens, sizeof(jsmntok_t) * _numTokens);
		}
		// In any error, ignore and just color as much text as we can
		else {
			break;
		}
		
	}
}

#pragma mark - Syntax Highlight

- (void)applyAttributesInRange:(NSRange)characterRange withBlock:(void (^)(NSUInteger, NSRange))block
{
	if (block == NULL) {
		return;
	}
	
	if (![self isStringValid]) {
		[self parse];
	}
	
	NSString* string = [self string];
	
	NSUInteger k = 0;
	
	for (unsigned int i = 0; i < _parser.toknext; i++) {
		NSRange range = NSMakeRange(_tokens[i].start, _tokens[i].end-_tokens[i].start);
		if (range.location >= characterRange.location &&
			range.location + range.length <= characterRange.location + characterRange.length) {
			if (_tokens[i].type == JSMN_PRIMITIVE) {
				unichar c = [string characterAtIndex:_tokens[i].start];
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
				k++;
			}
			else if (_tokens[i].type == JSMN_OBJECT) {
				block(LMTextParserTokenTypeOther | LMTextParserTokenJSONTypeObject, range);
				k = 0;
			}
			else if (_tokens[i].type == JSMN_ARRAY) {
				block(LMTextParserTokenTypeOther | LMTextParserTokenJSONTypeArray, range);
				k = 0;
			}
			else if (_tokens[i].type == JSMN_STRING) {
				if (k % 2 == 0) {
					block(LMTextParserTokenTypeString | LMTextParserTokenJSONTypeKey, range);
				}
				else {
					block(LMTextParserTokenTypeString, range);
				}
				k++;
			}
		}
	}
}

#pragma mark - Token Recognition

- (NSArray *)keyPathForObjectAtRange:(NSRange)range objectRange:(NSRange *)objectRange
{
	if (![self isStringValid]) {
		[self parse];
	}
	
	for (unsigned int i = 0; i < _parser.toknext; i++) {
		if (_tokens[i].type == JSMN_PRIMITIVE || _tokens[i].type == JSMN_STRING) {
			if (range.location >= _tokens[i].start && range.location+range.length <= _tokens[i].end) {
				NSRange range = NSMakeRange(_tokens[i].start, _tokens[i].end-_tokens[i].start);
				
				*objectRange = range;
				
				NSMutableArray* path = [NSMutableArray array];
				for (unsigned int j = i; _tokens[j].parent != (-1); j = _tokens[j].parent) {
					
					jsmntype_t parentType = _tokens[_tokens[j].parent].type;
					
					if (parentType == JSMN_OBJECT) {
						unsigned int previousToken = j-(_tokens[j].posinparent%2);
						[path insertObject:[self.string substringWithRange:NSMakeRange(_tokens[previousToken].start, _tokens[previousToken].end-_tokens[previousToken].start)] atIndex:0];
					}
					else if (parentType == JSMN_ARRAY) {
						[path insertObject:@(_tokens[j].posinparent) atIndex:0];
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
