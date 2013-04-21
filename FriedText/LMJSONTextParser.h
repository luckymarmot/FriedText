//
//  LMJSONTextParser.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/6/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LMTextParser.h"

typedef enum {
	LMTextParserTokenJSONTypeTrue		= 0x0010,
	LMTextParserTokenJSONTypeFalse		= 0x0020,
	LMTextParserTokenJSONTypeNull		= 0x0030,
} LMTextParserTokenJSONType;

@interface LMJSONTextParser : NSObject <LMTextParser>

@end
