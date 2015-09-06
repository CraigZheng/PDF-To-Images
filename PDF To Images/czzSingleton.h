//
//  czzSingleton.h
//  PDF To Images
//
//  Created by Craig on 24/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface czzSingleton : NSObject
@property NSMutableArray *processedFiles;
@property NSMutableArray *selectedPDFFiles;
@property NSMutableArray *selectedPDFInfos;

+(id)sharedInstance;

@end
