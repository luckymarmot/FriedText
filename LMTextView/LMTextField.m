//
//  LMTextField.m
//  LMTextView
//
//  Created by Micha Mazaheri on 4/11/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import "LMTextField.h"
#import "LMTextFieldCell.h"

@implementation LMTextField

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self) {
	}
	return self;
}

+ (Class)cellClass
{
	return [LMTextFieldCell class];
}

@end
