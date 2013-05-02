//
//  NSObject+TDBindings.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/14/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (TDBindings)

- (void)propagateValue:(id)value forBinding:(NSString*)binding;
- (BOOL)shouldUpdateContinuouslyBinding:(NSString*)binding;

@end
