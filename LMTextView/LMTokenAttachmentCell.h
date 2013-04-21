//
//  LMTokenAttachmentCell.h
//  LMTextView
//
//  Created by Micha Mazaheri on 4/6/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMTextAttachmentCell.h"

@interface LMTokenAttachmentCell : NSTextAttachmentCell <LMTextAttachmentCell>

+ (NSTextAttachment*)tokenAttachmentWithString:(NSString*)string;

@end
