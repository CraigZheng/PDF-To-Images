//
//  czzDescriptionFileInputWindow.m
//  PDF To Images
//
//  Created by Craig on 5/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import "czzDescriptionFileInputWindow.h"



@interface czzDescriptionFileInputWindow ()

@end

@implementation czzDescriptionFileInputWindow
@synthesize filelistTableView;
NSArray *filePaths; //array that holds full paths
NSMutableArray *fileNames; //arry that holds file names
NSMutableArray *descriptions; //array that holds content of description file
NSMutableArray *processedTXTFiles; //here holds a list of processed description files
NSString *targetPath; //where to save processed description contents

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

}

//initialise members here in order to provide a seemingly fresh instance of this class
-(void)setupDescriptionFile:(NSArray *)pathArrays withTargetPath:(NSString *)path{
    //create 2 new arrays so this window looks like brand new again
    fileNames = [[NSMutableArray alloc]init];
    descriptions = [[NSMutableArray alloc]init];
    processedTXTFiles = [[NSMutableArray alloc]init];
    filePaths = [[NSArray alloc]initWithArray:pathArrays];
    targetPath = path;
    for (NSString* path in filePaths){
        NSString *filename = [path lastPathComponent];
        [fileNames addObject:filename];
    }
    [filelistTableView reloadData];
    //fill descriptions array with NSNull to avoid insertObject: cause out of bound error
    for (id temp in filePaths){
        [descriptions addObject:[NSNull null]];
    }
}

//delegates
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return fileNames.count;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString *headerCellStringValue = [tableColumn.headerCell stringValue];
    if ([headerCellStringValue hasPrefix:@"Filename"]){
        if (row < fileNames.count){
            return [fileNames objectAtIndex:row];//here we display pdf file names
        }
    } else if ([headerCellStringValue hasPrefix:@"Filepath"]){
        if (row < filePaths.count){
            //here we store a full path to the file
            return  [filePaths objectAtIndex:row];
        }
    } else if ([headerCellStringValue hasPrefix:@"Description"]){
        if (row < descriptions.count){
            id description = [descriptions objectAtIndex:row];
            if (description != [NSNull null])
                return (NSString*)description;
            else
                return nil;
        }
    }
    return nil;
}

//here we set string value for each description file 
-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    //since description column is the only column thats editable, we do not need to check for anything other than a valid string
    if (object != nil && [((NSString*)object) length] > 0){
        [descriptions replaceObjectAtIndex:row withObject:object];
    }
}

//dismiss window
- (IBAction)dismissSelf:(id)sender {
    [self.window orderOut:self.window];
    //[self.window close];
}

//save all valid descriptions
- (IBAction)saveDescriptions:(id)sender {
    NSError *error;
    for (id description in descriptions){
        if (description != [NSNull null]){
            error = nil;
            NSInteger positionInArray = [descriptions indexOfObject:description];
            NSString *txtFilePath = [targetPath stringByAppendingPathComponent:[[[fileNames objectAtIndex:positionInArray] stringByDeletingPathExtension] stringByAppendingPathExtension:@"txt"]];
            [((NSString*)description) writeToFile:txtFilePath atomically:YES encoding: NSUTF8StringEncoding error: &error];
            if (error == nil){
                [processedTXTFiles addObject:txtFilePath];
            }
        }
        
    }
    if (error != nil) {
        //tell user that there is an error while saving files
        NSAlert *alert = [[NSAlert alloc]init];
        [alert setMessageText:[NSString stringWithFormat:@"Error while saving description files: %@", [error description]]];
        [alert runModal];
    } else if (processedTXTFiles.count > 0) {
        //tell user that everything is ok
        NSString *message = @"Description files saved as the following files: ";
        for (NSString *file in processedTXTFiles){
            NSString *tempFname = [file lastPathComponent];
            message = [message stringByAppendingString:[NSString stringWithFormat:@"\n%@", tempFname]];
            [self.delegate fileReady:file]; //notify the delegate that the file is ready
        }
        NSAlert *alert = [[NSAlert alloc]init];
        [alert setMessageText:[NSString stringWithFormat:@"%@", message]];
        [alert runModal];
        [self.window close];
    } else { //if processedTXTFiles is equal or smaller than 0, means shit
        NSAlert *alert = [[NSAlert alloc]init];
        [alert setMessageText:@"Nothing to save!"];
        [alert runModal];
    }
}

@end
