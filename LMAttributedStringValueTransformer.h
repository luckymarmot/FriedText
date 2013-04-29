//
//  LMAttributedStringValueTransformer.h
//  FriedText
//
//  Created by Micha Mazaheri on 4/23/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LMTextParser.h"

typedef NSString* (^LMAttributedStringStringArchiving)(NSAttributedString* attribtuedString);
typedef NSMutableAttributedString* (^LMAttributedStringStringUnarchiving)(NSString* string);

@class LMTextField, LMTextView;

@interface LMAttributedStringValueTransformer : NSValueTransformer

+ (id)attributedStringValueTransformerForTextField:(LMTextField*)textField;

+ (id)attributedStringValueTransformerForTextView:(LMTextView *)textView;

- (id)initWithTextParser:(id<LMTextParser>)parser defaultAttributes:(NSDictionary*)defaultAttributes attributesBlock:(NSDictionary *(^)(NSUInteger, NSRange))attributesBlock;

@property (strong, nonatomic) NSDictionary* defaultAttributes;

@property (strong, nonatomic) id <LMTextParser> parser;
@property (strong, nonatomic) NSDictionary * (^attributesBlock)(NSUInteger, NSRange);

@property (nonatomic) BOOL useData;
@property (nonatomic) NSStringEncoding stringDataEncoding;

@property (strong, nonatomic) LMAttributedStringStringArchiving archivingBlock;
@property (strong, nonatomic) LMAttributedStringStringUnarchiving unarchivingBlock;

@end
