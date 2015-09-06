//
//  czzSingleton.m
//  PDF To Images
//
//  Created by Craig on 24/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import "czzSingleton.h"

@implementation czzSingleton
@synthesize processedFiles;
@synthesize selectedPDFFiles;
@synthesize selectedPDFInfos;
+ (id)sharedInstance
{
    // structure used to test whether the block has completed or not
    static dispatch_once_t p = 0;
    
    // initialize sharedObject as nil (first call only)
    __strong static id _sharedObject = nil;
    
    // executes a block object once and only once for the lifetime of an application
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    // returns the same object each time
    return _sharedObject;
}

-(id)init{
    self = [super init];
    if (self){
        processedFiles = [[NSMutableArray alloc]init];
        selectedPDFFiles = [[NSMutableArray alloc]init];
        selectedPDFInfos = [[NSMutableArray alloc]init];
    }
    return self;
}
@end
