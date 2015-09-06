//
//  czzFileUploader.h
//  PDF To Images
//
//  Created by Craig on 13/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol czzFTPUploaderDelegate <NSObject>
-(void)uploadingFeedback:(NSString*)file statusCode:(NSInteger)code status:(NSString*)status;

@end

@interface czzFileUploader : NSObject<NSStreamDelegate>
-(void)setUsername:(NSString*)username password:(NSString*)password serverURL:(NSURL*)url; //set up user name, pw and url at one go
-(void)uploadFiles:(NSArray*)files; //upload these files

@property (nonatomic, retain) id<czzFTPUploaderDelegate> delegate;
@end
