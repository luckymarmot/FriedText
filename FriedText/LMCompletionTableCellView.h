//
//  LMCompletionTableCellView.h
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LMCompletionOption.h"

@interface LMCompletionTableCellView : NSTableCellView

@property (strong) id<LMCompletionOption>completionOption;

@end
