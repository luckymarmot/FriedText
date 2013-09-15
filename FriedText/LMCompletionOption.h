//
//  LMCompletionOption.h
//  FriedText
//
//  Created by Micha Mazaheri on 2013-09-06.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LMCompletionOption <NSObject>

- (NSString*)stringValue;

@optional

- (NSString*)comment;
- (NSAttributedString*)attributedStringValue;

@end

@interface LMCompletionOption : NSObject <LMCompletionOption>

@property (strong, nonatomic) NSString* stringValue;
@property (strong, nonatomic) NSString* comment;

@end
