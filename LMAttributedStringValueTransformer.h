//
//  LMAttributedStringValueTransformer.h
//  FriedText
//
//  Created by Micha Mazaheri on 4/23/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LMTextParser.h"

@interface LMAttributedStringValueTransformer : NSValueTransformer

- (id)initWithTextParser:(id<LMTextParser>)parser attributesBlock:(NSDictionary *(^)(NSUInteger, NSRange))attributesBlock;

@property (strong, nonatomic) id <LMTextParser> parser;
@property (strong, nonatomic) NSDictionary * (^attributesBlock)(NSUInteger, NSRange);

@end
