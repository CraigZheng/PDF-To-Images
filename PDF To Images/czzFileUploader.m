//
//  czzFileUploader.m
//  PDF To Images
//
//  Created by Craig on 13/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

/*
 this class is inspired by apple's sample code
 */

#import "czzFileUploader.h"

@interface czzFileUploader()
@property (nonatomic, retain) NSString *username; //username
@property (nonatomic, retain) NSString *password; //password
@property (nonatomic, retain) NSURL *serverURL; //server url
@end

@implementation czzFileUploader
@synthesize username = _username, password = _password, serverURL = _serverURL;
@synthesize delegate = _delegate;
size_t            bufferLimit;
size_t            bufferOffset;
NSInputStream *fileInputStream; //incoming from local file
NSOutputStream *networkOutputStream; //out going to server
NSInteger kSendBufferSize = 32768;
uint8_t buffer[32768];

NSString *currentlyUploadingFile; //file path to the currently uploading file
NSInteger fileSize; //file size of currently uploading file
NSMutableArray *filesToUpload; //this array holds all necessary files;
NSMutableArray *filesFailedToUpload; //this array holds all failed attempts

//set up user name and password, can be nil
-(void)setUsername:(NSString *)username password:(NSString *)password serverURL:(NSURL *)url{
    self.username = username;
    self.password = password;
    self.serverURL = url;
}

-(void)uploadFiles:(NSArray *)files{
    filesToUpload = [[NSMutableArray alloc]init];
    [filesToUpload addObjectsFromArray:files];
    filesFailedToUpload = [[NSMutableArray alloc]init];
    //pop the last object to uploadFileAtPath method
    if (filesToUpload.count > 0){
        [self popFilesToUpload];
    }
}

-(void)popFilesToUpload{
    if (filesToUpload.count > 0)
    {
        [self uploadFileAtPath:filesToUpload.lastObject];
        [filesToUpload removeLastObject];
    } else {
        if (filesFailedToUpload.count > 0){
            //list the failed files
            NSString *files = @"";
            for (NSString *path in filesFailedToUpload){
                files = [files stringByAppendingString:[NSString stringWithFormat:@"%@\n", [path lastPathComponent]]];
            }
            NSAlert *alert = [[NSAlert alloc]init];
            [alert setMessageText:[NSString stringWithFormat:@"The uploading of the following files has been failed:\n%@", files]];
            [alert addButtonWithTitle:@"Retry"];
            [alert addButtonWithTitle:@"Cancel"];
            //display file upload failed alert
            if ([alert runModal] == NSAlertFirstButtonReturn){//the right most button
                [self.delegate uploadingFeedback:currentlyUploadingFile statusCode:0 status:@"Retrying..."];
                [self uploadFiles:filesFailedToUpload];
            }
        } else {
            //if files and failed failes are both empty, we can assume that the uploads are successed.
            //[self.delegate uploadingFeedback:[NSDictionary dictionaryWithObject:@"All uploads are finished!" forKey:currentlyUploadingFile]];
            [self.delegate uploadingFeedback:@"All uploads" statusCode:0 status:@"Finished!"];
        }
    }
}

//upload one file at path
-(void)uploadFileAtPath:(NSString *)filePath{
    NSLog(@"SERVER ADDRESS = %@", [self serverURL]);
    if (!self.serverURL){
        NSAlert *alert = [[NSAlert alloc]init];
        [alert setMessageText:[NSString stringWithFormat:@"Error: server address not valid."]];
        [alert runModal];
        return;
    }
    @try {
        NSString *fileName = [filePath lastPathComponent];
        currentlyUploadingFile = filePath;
        networkOutputStream = CFBridgingRelease(CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) [self.serverURL URLByAppendingPathComponent:fileName]));
        
        [networkOutputStream setProperty:self.username forKey:(id)kCFStreamPropertyFTPUserName];
        [networkOutputStream setProperty:self.password forKey:(id)kCFStreamPropertyFTPPassword];
        
        fileInputStream = [[NSInputStream alloc]initWithFileAtPath:filePath];
        fileSize = (NSInteger)[[[NSFileManager defaultManager] attributesOfItemAtPath:currentlyUploadingFile error:nil] fileSize];
        //NSLog(@"file to send = %@, size = %lu", filePath, fileSize);
        [fileInputStream open];
        
        networkOutputStream.delegate = self;
        [networkOutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [networkOutputStream open];
    }
    @catch (NSException *exception) {
        NSAlert *alert = [[NSAlert alloc]init];
        [alert setMessageText:[NSString stringWithFormat:@"Error while trying to connect, Please check your setting: \n%@", exception]];
        [alert runModal];
    }
}

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            //[self.delegate uploadingFeedback:[NSDictionary dictionaryWithObject:@"Status: connected to server" forKey:currentlyUploadingFile]];
            [self.delegate uploadingFeedback:currentlyUploadingFile statusCode:0 status:@"connected to server..."];
        } break;
        case NSStreamEventHasSpaceAvailable: {
            //NSLog(@"Sending");
            
            // If we don't have any data buffered, go read the next chunk of data.
            
            if (bufferOffset == bufferLimit) {
                NSInteger   bytesRead;
                
                bytesRead = [fileInputStream read:buffer maxLength:kSendBufferSize];
                
                if (bytesRead == -1) {
                    //[self.delegate uploadingFeedback:[NSDictionary dictionaryWithObject:@"File error: please check the uploading file." forKey:currentlyUploadingFile]];
                    [self.delegate uploadingFeedback:currentlyUploadingFile statusCode:1 status:@"please check the local copy of uploading file"];
                    [filesFailedToUpload addObject:currentlyUploadingFile]; //add the failed attempt to this array
                    [self popFilesToUpload]; //because the currently one is in error, pop next one
                } else if (bytesRead == 0) {
                    NSLog(@"No more byte to send");
                    
                    [fileInputStream close];
                    [networkOutputStream close];
                    //[self.delegate uploadingFeedback:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@ is finished!", [currentlyUploadingFile lastPathComponent]] forKey:currentlyUploadingFile]];
                    [self.delegate uploadingFeedback:currentlyUploadingFile statusCode:0 status:@"Finished!"];
                    [self popFilesToUpload]; //pop next one
                } else {
                    bufferOffset = 0;
                    bufferLimit  = bytesRead;
                    fileSize = fileSize - bytesRead;
                    //[self.delegate uploadingFeedback:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Uploading %@: %lu bytes remains.", [currentlyUploadingFile lastPathComponent], (fileSize / 1000)] forKey:currentlyUploadingFile]];
                    [self.delegate uploadingFeedback:currentlyUploadingFile statusCode:0 status:[NSString stringWithFormat:@"Uploading: %lu KB remain.", (fileSize / 1000)]];
                }
            }
            
            // If we're not out of data completely, send the next chunk.
            
            if (bufferOffset != bufferLimit) {
                NSInteger   bytesWritten;
                bytesWritten = [networkOutputStream write:&buffer[bufferOffset] maxLength:bufferLimit - bufferOffset];

                if (bytesWritten == -1) {
                    //[self.delegate uploadingFeedback:[NSDictionary dictionaryWithObject:@"Connection error: please check your network" forKey:currentlyUploadingFile]];
                    [self.delegate uploadingFeedback:currentlyUploadingFile statusCode:2 status:@"Connection error: please check your network."];
                    [filesFailedToUpload addObject:currentlyUploadingFile]; //add the failed attempt to this array
                    [self popFilesToUpload]; //because the currently one is in error, pop next one
                } else {
                    bufferOffset += bytesWritten;
                }
            }
        } break;
        case NSStreamEventErrorOccurred: {
            //[self.delegate uploadingFeedback:[NSDictionary dictionaryWithObject:@"Connection error: please check your network status, username and password." forKey:currentlyUploadingFile]];
            [self.delegate uploadingFeedback:currentlyUploadingFile statusCode:2 status:@"Connection error: please check your network status, username and password."];
            [filesFailedToUpload addObject:currentlyUploadingFile];
            [self popFilesToUpload];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            NSLog(@"default");
            assert(NO);
        } break;
    }

}


@end
