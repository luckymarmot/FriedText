//
//  LMCompletionView.h
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "LMCompletionOption.h"

@class LMCompletionView;

@protocol LMCompletionViewDelegate <NSObject>

- (void)didSelectCompletionOption:(id<LMCompletionOption>)completionOption;

@end

@class LMCompletionTableView;

@interface LMCompletionView : NSView

@property (strong, nonatomic) LMCompletionTableView* tableView;

@property (strong, nonatomic) NSArray* completions;
- (void)setCompletions:(NSArray *)completions reload:(BOOL)reload;

@property (strong, nonatomic) id <LMCompletionViewDelegate> delegate;

@property (nonatomic, readonly) CGFloat textFieldHeight;
@property (nonatomic, readonly) CGSize completionInset;

- (id<LMCompletionOption>)currentCompletionOption;

- (void)selectNextCompletion;
- (void)selectPreviousCompletion;
- (void)selectFirstCompletion;
- (void)selectLastCompletion;

- (NSString*)currentCompletionString;
- (NSString*)currentCompletionComment;

- (void)doubleClicked;

@end
