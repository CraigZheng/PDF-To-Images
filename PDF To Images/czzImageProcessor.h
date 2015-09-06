//
//  czzImageProcessor.h
//  PDF To Images
//
//  Created by Craig on 2/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol czzImageProcessorFileReadyDeleate <NSObject> //for each file processed, call this to allow modification of caller of this class
-(void)fileReady:(NSString*)file;
-(void)conversionProgressFor:(NSString*)file status:(NSString*)status progress:(NSInteger)progress;
@end

@interface czzImageProcessor : NSObject

-(void)setPDFPaths:(NSArray*)path toPath:(NSString*)targetPath;
-(void)setImageHeight:(NSInteger)height; //set up height for the comic
-(void)startTheConversion;
-(void)setImageQuality:(NSInteger)qualityCode;
-(void)setImageFormat:(NSInteger)formatCode;
-(NSString*)getStatus; //this will return the current status of this processor
-(NSString*)getError; //return errors
-(NSDictionary*)getCurrentProgress; //this returns the current progress of this processor, value represents in a key - value set: full path - percentage
//-(NSArray*)getProcessedFilePaths; //this will return the paths to zipped files and cover files

@property (nonatomic, retain) id<czzImageProcessorFileReadyDeleate> delegate;
@end
