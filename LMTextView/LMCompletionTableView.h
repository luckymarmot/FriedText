//
//  LMCompletionTableView.h
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LMCompletionView;

@interface LMCompletionTableView : NSTableView

@property (weak, nonatomic) LMCompletionView* completionView;

@end
