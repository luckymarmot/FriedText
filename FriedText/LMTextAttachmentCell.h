//
//  LMTextAttachmentCell.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/21/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LMTextAttachmentCell <NSTextAttachmentCell>

@optional

+ (id)textAttachmentCellWithTextAttachment:(NSTextAttachment*)textAttachment;

@end
