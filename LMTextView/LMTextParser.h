//
//  LMTextParser.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/6/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	LMTextParserTokenTypeOther = 0,
	LMTextParserTokenTypeBoolean,
	LMTextParserTokenTypeNumber,
	LMTextParserTokenTypeString,
} LMTextParserTokenType;

@protocol LMTextParser <NSObject>

- (void)parseString:(NSString*)string;

- (void)applyAttributesInRange:(NSRange)range withBlock:(void(^)(LMTextParserTokenType tokenType, NSRange range))block;

- (NSArray *)keyPathForObjectAtCharIndex:(NSUInteger)charIndex correctedRange:(NSRange *)correctedRange;

@end
