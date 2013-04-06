//
//  LMTextParser.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/6/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	LMTextParserTokenTypeOther			= 0x0,
	LMTextParserTokenTypeBoolean		= 0x1,
	LMTextParserTokenTypeNumber			= 0x2,
	LMTextParserTokenTypeString			= 0x3,
} LMTextParserTokenType;
#define LMTextParserTokenTypeMask		0x000f
#define LMTextParserTokenCustomTypeMask 0xfff0

@protocol LMTextParser <NSObject>

- (void)parseString:(NSString*)string;

- (void)applyAttributesInRange:(NSRange)range withBlock:(void(^)(NSUInteger tokenTypeMask, NSRange range))block;

- (NSArray *)keyPathForObjectAtCharIndex:(NSUInteger)charIndex correctedRange:(NSRange *)correctedRange;

@end
