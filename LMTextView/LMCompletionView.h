//
//  LMCompletionView.h
//  TextFieldAutocompletion
//
//  Created by Micha Mazaheri on 12/6/12.
//  Copyright (c) 2012 Lucky Marmot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* LMCompletionEntryWordKey;
extern NSString* LMCompletionEntryDescriptionKey;

@class LMCompletionView;

@protocol LMCompletionViewDelegate <NSObject>

- (void)didSelectCompletingString:(NSString*)completingString;

@end

@class LMCompletionTableView;

@interface LMCompletionView : NSView

@property (strong, nonatomic) LMCompletionTableView* tableView;

@property (strong, nonatomic) NSArray* completions;

@property (strong, nonatomic) id <LMCompletionViewDelegate> delegate;

@property (nonatomic, readonly) CGFloat textFieldHeight;
@property (nonatomic, readonly) CGSize completionInset;

- (void)selectNextCompletion;
- (void)selectPreviousCompletion;

- (NSString*)completingString;
- (NSString*)completingDescription;

- (void)doubleClicked;

@end
