//
//  LMCompletionEntry.h
//  Paw
//
//  Created by Micha Mazaheri on 3/3/13.
//  Copyright (c) 2013 Lucky Marmot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LMCompletionEntry : NSManagedObject

@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSString * word;
@property (nonatomic, retain) NSString * filter;
@property (nonatomic, retain) NSString * desc;

@end
