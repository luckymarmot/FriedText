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

/*
 When the string returned by the block is potentially changed, this method will be called.
 */

- (void)invalidateString
{
	_stringIsValid = NO;
}

/*
 A convenience method to return the string to be parsed, calling the block.
 */
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

/*
 This method is responsible to parse the input, for later consumption.
 */
- (void)parse
{
	// Init the jsmn parser
	jsmn_init(&_parser);
	if (_tokens == NULL) {
		_numTokens = INITIAL_NUM_TOKENS; // an arbitrary size to start with
		_tokens = malloc(sizeof(jsmntok_t) * _numTokens);
	}
	
	// Loop until we have the right amount of tokens
	// jsmn requires that we increase the number of tokens, if case of a large input
	while (_tokens != NULL) {
		
		// Parse
		jsmnerr_t error = jsmn_parse(&_parser, (__bridge CFStringRef)([self string] ?: @""), _tokens, _numTokens);
		
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

/*
 * This will call the block with each range for each token.
 * e.g. We have a JSON as input: {"username":"luckymarmot"}
 * This will call the full range with the (LMTextParserTokenTypeOther | LMTextParserTokenJSONTypeObject) type
 * then the range of username with (LMTextParserTokenTypeString | LMTextParserTokenJSONTypeKey)
 * and finally the range of luckymarmot with LMTextParserTokenTypeString
 * This way, the full range will be grey, and then the key dark grey, and the value blue.
 */
- (void)applyAttributesInRange:(NSRange)characterRange withBlock:(void (^)(NSUInteger, NSRange))block
{
	// If no block set, then we don't have anything to do
	if (block == NULL) {
		return;
	}
	
	// If string is invalid, parse the string
	if (![self isStringValid]) {
		[self parse];
	}
	
	// Loop on all tokens...
	NSString* string = [self string];
	for (unsigned int i = 0; i < _parser.toknext; i++) {
		NSRange range = NSMakeRange(_tokens[i].start, _tokens[i].end-_tokens[i].start);
		if (range.location >= characterRange.location &&
			range.location + range.length <= characterRange.location + characterRange.length) {
			
			// If token is a primitive (true, false, null or a number)
			if (_tokens[i].type == JSMN_PRIMITIVE) {
				unichar c = [string characterAtIndex:_tokens[i].start];
				
				// true
				if (c == 't') {
					block(LMTextParserTokenTypeBoolean | LMTextParserTokenJSONTypeTrue, range);
				}
				
				// false
				else if (c == 'f') {
					block(LMTextParserTokenTypeBoolean | LMTextParserTokenJSONTypeFalse, range);
				}
				
				// null
				else if (c == 'n') {
					block(LMTextParserTokenTypeOther | LMTextParserTokenJSONTypeNull, range);
				}
				
				// Number
				else {
					block(LMTextParserTokenTypeNumber, range);
				}
			}
			
			// A JSON Object
			else if (_tokens[i].type == JSMN_OBJECT) {
				block(LMTextParserTokenTypeOther | LMTextParserTokenJSONTypeObject, range);
			}
			
			// Array
			else if (_tokens[i].type == JSMN_ARRAY) {
				block(LMTextParserTokenTypeOther | LMTextParserTokenJSONTypeArray, range);
			}
			
			// String
			else if (_tokens[i].type == JSMN_STRING) {
				int parent = _tokens[i].parent;
				// If inside an Object and position is even, then it's a Key
				if (parent >= 0 &&
					_tokens[parent].type == JSMN_OBJECT &&
					_tokens[i].posinparent % 2 == 0) {
					block(LMTextParserTokenTypeString | LMTextParserTokenJSONTypeKey, range);
				}
				// Or a string (not a key)
				else {
					block(LMTextParserTokenTypeString, range);
				}
			}
		}
	}
}

#pragma mark - Token Recognition

/*
 * Given a range, it will return the JSON key path to the object and the full range of that object.
 * e.g. The JSON is {"name":"micha"} and range is {12,0} then the path will be @[@"name"] and
 * the objectRange pointer set to {9,5}.
 */
- (NSArray *)keyPathForObjectAtRange:(NSRange)range objectRange:(NSRange *)objectRange
{
	// If string is invalid, parse the string
	if (![self isStringValid]) {
		[self parse];
	}
	
	// For each token...
	for (unsigned int i = 0; i < _parser.toknext; i++) {
		
		// If token is a primitive (True, False or a number) or a string
		if (_tokens[i].type == JSMN_PRIMITIVE || _tokens[i].type == JSMN_STRING) {
			
			// If the range we are currently looking at has some common part with the token...
			if (range.location >= _tokens[i].start && range.location+range.length <= _tokens[i].end) {
				
				NSRange range = NSMakeRange(_tokens[i].start, _tokens[i].end-_tokens[i].start);
				*objectRange = range;
				
				// Now iterating on the token's parent to build the range
				// If we are in the token "paw" in the JSON {"name":{"first":"paw"}}
				// then key path "name.first"
				NSMutableArray* path = [NSMutableArray array];
				for (unsigned int j = i; _tokens[j].parent != (-1); j = _tokens[j].parent) {
					
					jsmntype_t parentType = _tokens[_tokens[j].parent].type;
					
					// If it's an object, set the "key"
					if (parentType == JSMN_OBJECT) {
						unsigned int previousToken = j-(_tokens[j].posinparent%2);
						[path insertObject:[self.string substringWithRange:NSMakeRange(_tokens[previousToken].start, _tokens[previousToken].end-_tokens[previousToken].start)] atIndex:0];
					}
					// If it's an array, set the [index]
					else if (parentType == JSMN_ARRAY) {
						[path insertObject:@(_tokens[j].posinparent) atIndex:0];
					}
				}
				
				// If found, then just return
				return path;
			}
		}
	}
	
	// If nothing found, set the objectRange to not found
	*objectRange = NSMakeRange(NSNotFound, 0);
	
	return nil;
}

@end
