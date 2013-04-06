//
//  LMJSONTextParser.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/6/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMJSONTextParser.h"

#import "jsmn.h"

#define NUM_TOKENS 1048576
#define MAX_JSON_SIZE 1048576

@interface LMJSONTextParser () {
	jsmn_parser parser;
	jsmntok_t tokens[NUM_TOKENS];
}

@property (strong, nonatomic) NSData* data;
@property (strong, nonatomic) NSString* string;

@end

@implementation LMJSONTextParser

- (void)parseString:(NSString *)string
{
	jsmn_init(&parser);
	self.string = string;
	self.data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	char c[MAX_JSON_SIZE];
	memcpy(c, [_data bytes], MIN([_data length], MAX_JSON_SIZE));
	jsmnerr_t result = jsmn_parse(&parser, c, tokens, NUM_TOKENS);
	if (result != JSMN_SUCCESS) {
		
	}
}

- (void)applyAttributesInRange:(NSRange)characterRange withBlock:(void (^)(LMTextParserTokenType, NSRange))block
{
	if (block == NULL) {
		return;
	}
	
	for (unsigned int i = 0; i < parser.toknext; i++) {
		NSRange range = NSMakeRange(tokens[i].start, tokens[i].end-tokens[i].start);
		if (NSIntersectionRange(characterRange, range).length > 0) {
			if (tokens[i].type == JSMN_PRIMITIVE) {
				const char c = ((char *)[_data bytes])[tokens[i].start];
				if (c == 't' || c == 'f') {
					block(LMTextParserTokenTypeBoolean, range);
				}
				else if (c == 'n') {
					block(LMTextParserTokenTypeOther, range);
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

- (NSArray *)keyPathForObjectAtCharIndex:(NSUInteger)charIndex correctedRange:(NSRange *)correctedRange
{
	for (unsigned int i = 0; i < parser.toknext; i++) {
		if (tokens[i].type == JSMN_PRIMITIVE || tokens[i].type == JSMN_STRING) {
			if (charIndex >= tokens[i].start && charIndex < tokens[i].end) {
				NSRange range = NSMakeRange(tokens[i].start, tokens[i].end-tokens[i].start);
				
				*correctedRange = range;
				
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
	
	*correctedRange = NSMakeRange(NSNotFound, 0);
	
	return nil;
}

@end
