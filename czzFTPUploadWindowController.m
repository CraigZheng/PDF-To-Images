//
//  czzFTPUploadWindowController.m
//  PDF To Images
//
//  Created by Craig on 24/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import "czzFTPUploadWindowController.h"
#import "czzSingleton.h"
#import "czzUpdateLoginDetailsController.h"
#import "czzFileUploader.h"

@interface czzFTPUploadWindowController ()
@property czzUpdateLoginDetailsController *updateDetailsWindow;
@property (strong) NSString *username, *password, *serverURL;
@property (strong) czzFileUploader *uploader;
@end

@implementation czzFTPUploadWindowController
@synthesize filelistTableView;
@synthesize statusLabel;
@synthesize updateDetailsWindow;
@synthesize uploader;
@synthesize username, password, serverURL;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        updateDetailsWindow = [[czzUpdateLoginDetailsController alloc]initWithWindowNibName:@"czzUpdateLoginDetailsController"];
        updateDetailsWindow.delegate = self;
        self.username = @"inceptio";
        self.serverURL = @"ftp://203.170.87.113/public_html/data/";
        self.password = @"Vbn4mxDC";
        //if user had modifiy login detailss...
        [self checkSavedLoginDetails];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

//delegates from tableview
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    //NSLog(@"number of rows : %lu", [[[czzSingleton sharedInstance] processedFiles] count]);
    return [[[czzSingleton sharedInstance] processedFiles] count];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString *headerCellString = [tableColumn.headerCell stringValue];
    if ([headerCellString hasPrefix:@"Filename"]){
        
        return [[[[czzSingleton sharedInstance] processedFiles] objectAtIndex:row] lastPathComponent];
    } else {
        return [[[czzSingleton sharedInstance] processedFiles] objectAtIndex:row];
    }
    return nil;
}

//delegate methond from czzUpdateLoginDetailsDelegate
//modify self's username, password and server URL please 
-(void)loginDetailsDidChanged:(NSDictionary *)newInfo{
    //TODO : change my login details
    if ([newInfo valueForKey:@"serverURL"]){
        self.serverURL = [newInfo valueForKey:@"serverURL"];
    }
    if ([newInfo valueForKey:@"username"]){
        self.username = [newInfo valueForKey:@"username"];
    }
    if ([newInfo valueForKey:@"password"]){
        self.password = [newInfo valueForKey:@"password"];
    }
}

//delegate method from czzFTPUploaderDelegate
-(void)uploadingFeedback:(NSDictionary *)result{
    NSArray *keys = result.allKeys;
    for (NSString *key in keys){
        NSLog(@"%@", [result valueForKey:key]);
        [self.statusLabel setStringValue:[result valueForKey:key]];
    }
}

-(void)uploadingFeedback:(NSString *)file statusCode:(NSInteger)code status:(NSString *)status{
    
    [self.statusLabel setStringValue:[NSString stringWithFormat:@"%@ is %@", [file lastPathComponent], status]];
    if (code != 0){//if uploading is not normal
        [self.statusLabel setStringValue:status ];
    }
}

//button actions
- (IBAction)uploadAction:(id)sender {
    uploader = [[czzFileUploader alloc]init];
    [uploader setUsername:self.username password:self.password serverURL:[NSURL URLWithString:self.serverURL]];
    uploader.delegate = self;
    [uploader uploadFiles:[[czzSingleton sharedInstance] processedFiles]];
}

- (IBAction)deleteAction:(id)sender {
    if ([self.filelistTableView selectedRow] < [[[czzSingleton sharedInstance] processedFiles] count]){
        [[[czzSingleton sharedInstance] processedFiles] removeObjectAtIndex:self.filelistTableView.selectedRow];
        [self.filelistTableView reloadData];
    }
}

- (IBAction)updateLoginAction:(id)sender {
    [updateDetailsWindow.window makeKeyAndOrderFront:self];
}

- (IBAction)cancelAction:(id)sender {
    [self.window orderOut:self];
}
//allow user to add more to processed files
- (IBAction)addMoreAction:(id)sender {
    NSOpenPanel *openPane = [[NSOpenPanel alloc]init];
    [openPane setTitle:@"Select files to upload..."];
    [openPane setAllowsMultipleSelection:YES];
    if ([openPane runModal] == NSOKButton){
        [[[czzSingleton sharedInstance] processedFiles] addObjectsFromArray:openPane.filenames];
        [self.filelistTableView reloadData];
    }
}

//check previously saved details
-(void)checkSavedLoginDetails{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([prefs stringForKey:@"serverURL"] != nil){
        self.serverURL = [prefs stringForKey:@"serverURL"];
    }
    if ([prefs stringForKey:@"username"] != nil){
        self.username = [prefs stringForKey:@"username"];
    }
    if ([prefs stringForKey:@"password"] != nil){
        self.password = [prefs stringForKey:@"password"];
    }
}

-(void)windowDidBecomeKey:(NSNotification *)notification{
    //NSLog(@"load singletong");
    [self.filelistTableView reloadData];
}
@end
