//
//  czzWindowController.m
//  PDF To Images
//
//  Created by Craig on 1/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import "czzMainWindowController.h"
#import <Quartz/Quartz.h>
#import <dispatch/dispatch.h>
#import "czzImageProcessor.h"
#import "czzDescriptionFileInputWindow.h"
#import "czzFTPUploadWindowController.h"
#import "czzSingleton.h"

@interface czzMainWindowController ()


//@property (nonatomic, retain) NSMutableArray *selectedPDFInfos;//an array that holds selected pdf info, to be displayed to users
@property (nonatomic, retain) NSString *selectedPDFPath; //a single string that holds path to 1 selected pdf file;
@property (nonatomic, retain) NSString *targetPath; //where converted PDF files are saved
@property (nonatomic, assign) NSFileManager *fileManager; //for file operating
@property (nonatomic, retain) czzImageProcessor *imageprocessor; //the one and only image processor
@property (nonatomic, retain) czzDescriptionFileInputWindow *descriptionfileinputwindow;
@property (nonatomic, retain) czzFTPUploadWindowController *uploaderwindow;
@end

@implementation czzMainWindowController
@synthesize previewImageView;
@synthesize busyingIndicator;
@synthesize convertButton; //the start converting button, disable this when processing
@synthesize openFileButton; //the open file button
@synthesize uploadButton; //upload to server button
@synthesize imageProcessingProgressIndicator; //this would display as an progressIndicator for processing PDFs
@synthesize statusTextField; //this is a small text field that will display processing status
@synthesize autoUploadCheckbox; //two check boxes that controll how the application flows
@synthesize imageFormatRadioButton, imageQualityRadioButton, imageHeightTextField;//options that control the image quality, format and size
@synthesize inputNumberNotValidLabel, clickHereToBeginLabel = _clickHereToBeginLabel; //labels for user notification
@synthesize selectedPDFPath, targetPath, fileManager, imageprocessor, descriptionfileinputwindow;
//@synthesize enterDescriptionCheckbox;
@synthesize uploaderwindow;
@synthesize filelistTableView = _filelistTableView;
@synthesize delegate = _delegate;


NSInteger imageHeight = 1920; //image height for image conversion, default 1920
bool firstTimeRunning = YES;


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        fileManager = [NSFileManager defaultManager];
        //NSLog(@"init with window");
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    //check for previsouly saved user settings
    descriptionfileinputwindow = [[czzDescriptionFileInputWindow alloc]initWithWindowNibName:@"czzDescriptionFileInputWindow"];
    descriptionfileinputwindow.delegate = self;
    [self checkUserDefaults];
}

//check user defaults
-(void)checkUserDefaults{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    firstTimeRunning = [prefs boolForKey:@"FIRST_TIME_RUNNING"];
    if (firstTimeRunning){
        [self.clickHereToBeginLabel setHidden:NO];

    } else {
        [self.clickHereToBeginLabel setHidden:YES];
    }
    //set the flag to no
    [prefs setBool:NO forKey:@"FIRST_TIME_RUNNING"];
    [prefs synchronize];
}

//display  open panel, which allows user to select PDF files for processing.
- (IBAction)openFile:(id)sender {
    NSOpenPanel *openFilePanel = [[NSOpenPanel alloc]init];
    [openFilePanel setTitle:@"Select PDF files"];
    [openFilePanel setCanChooseFiles:YES];
    [openFilePanel setAllowsMultipleSelection:YES];
    [openFilePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"pdf", @"PDF", nil]];
    if ([openFilePanel runModal] == NSOKButton){
        //if more than 20 files, return without doing anything
        if (openFilePanel.filenames.count > 20){ 
            NSAlert *alert = [[NSAlert alloc]init];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:[NSString stringWithFormat:@"Too many files: the maximum amount of files is 20, you selected %ld.", openFilePanel.filenames.count]];
            [alert runModal];
            return;
        }
        [[[czzSingleton sharedInstance] selectedPDFFiles] removeAllObjects];
        [[[czzSingleton sharedInstance] selectedPDFInfos] removeAllObjects];
        
        [[[czzSingleton sharedInstance] selectedPDFFiles] addObjectsFromArray:openFilePanel.filenames];
        //select the first PDF object and generate a preview
        selectedPDFPath = [[[czzSingleton sharedInstance] selectedPDFFiles] objectAtIndex:0];
        [self performSelector:@selector(generatePreview:) withObject:selectedPDFPath];
        //generate comic info base on file paths
        for (NSString* path in [[czzSingleton sharedInstance] selectedPDFFiles]){
            CGPDFDocumentRef tempPdfRef = getCGPDFDocument([path UTF8String]);
            //the last component without extension is use as the comic name
            NSString *comicName = [[path lastPathComponent] stringByDeletingPathExtension];             
            //get total pages
            long numberOfPages = CGPDFDocumentGetNumberOfPages(tempPdfRef); 
            //get file size
            NSNumber *fileSize = ([[fileManager attributesOfItemAtPath:path error:nil] valueForKey:NSFileSize]);
            //convert to Megabytes
            [[[czzSingleton sharedInstance] selectedPDFInfos] addObject:[NSString stringWithFormat:@"%@ - %ldp - %dMB", comicName, numberOfPages,  (int)[fileSize doubleValue] / (1000 * 1000)]];
            //NSLog(@"filename = %@", [[[czzSingleton sharedInstance] selectedPDFInfos] lastObject]);
        }
        [self.filelistTableView reloadData];
    }
}

//generate an image preview for the given filepath
-(void)generatePreview:(NSString*) filePath{
    //spin the wheel
    [self startProgress];
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        @try {
            //NSLog(@"generating preview with filepath: %@", filePath);
            NSImage *previewImage = [[NSImage alloc]initWithContentsOfFile:filePath];//create an image based on given filepath
            if (previewImage == nil) {
                NSAlert *alert = [[NSAlert alloc]init];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert setMessageText:[NSString stringWithFormat:@"Error: can not generate a preview for the specified PDF file.\nIt appears to be broken:\n%@", filePath]];
                [alert runModal];
                [self stopProgress];
                return;
            }
            //manipulating of previewImageView must be done in main thread to avoid potential problem
            [self performSelectorOnMainThread:@selector(updatePreviewWithImage:) withObject:previewImage waitUntilDone:YES];
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
            
        }
        
        [self stopProgress];
    });
}

//update preview ImageView
-(void)updatePreviewWithImage:(NSImage*)image{
    [previewImageView setImage:image];
}

//for all selected PDF paths, convert them in the background
- (IBAction)startConversion:(id)sender {
    //if no file
    if ([[[czzSingleton sharedInstance] selectedPDFFiles] count] <= 0){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"No file has been selected!"];
        [alert runModal];
        return;
    }
    NSOpenPanel *openPanel = [[NSOpenPanel alloc]init];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setTitle:@"Select where to save converted files..."];
    if ([openPanel runModal] == NSOKButton){
        targetPath = openPanel.filename; //user selected target path for processed images to be resided
        //start a background image processor
        [self performSelectorInBackground:@selector(startImageProcessorInBackground:) withObject:targetPath];
    }
}

//corresponding to upload files button, present a file upload window
- (IBAction)uploadFiles:(id)sender {
    //[self performSelectorInBackground:@selector(presentFileUploadWindow) withObject:nil];
    [self presentFileUploadWindow];
}

- (IBAction)enterDescriptionAction:(id)sender {
    if ([[[czzSingleton sharedInstance] selectedPDFFiles] count] <= 0){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"No file has been selected!"];
        [alert runModal];
        return;
    }
    if (self.targetPath == nil){
        NSOpenPanel *openPane = [[NSOpenPanel alloc]init];
        [openPane setCanChooseDirectories:YES];
        [openPane setCanChooseFiles:NO];
        [openPane setTitle:@"Select where to save description files..."];
        if ([openPane runModal] == NSOKButton){
            self.targetPath = openPane.filename;
        } else {
            //else dont go any further
            return;
        }
    }
    [self makeDescriptionFile:targetPath];
}

-(void)presentFileUploadWindow{
    uploaderwindow = [[czzFTPUploadWindowController alloc]initWithWindowNibName:@"czzFTPUploadWindowController"];
    [uploaderwindow.window makeKeyAndOrderFront:nil];
}

//description file generator, parameter is where to save the generated files
//use selectedPDFPaths to generate them
-(void)makeDescriptionFile:(NSString*)targetPath{
    [descriptionfileinputwindow setupDescriptionFile:[[czzSingleton sharedInstance] selectedPDFFiles] withTargetPath:self.targetPath];
    [descriptionfileinputwindow.window makeKeyAndOrderFront:self];
    //NSLog(@"description file window should pop up");
}

//for selectedPDFPaths, do it in the background
-(void)startImageProcessorInBackground:(NSString*)targetPath{
    // make sure we actually have something to process
    if ([[czzSingleton sharedInstance] selectedPDFFiles].count <= 0){//if no comic is selected
        return;
    }
    //make sure the user input image height is ok
    imageHeight = [imageHeightTextField.stringValue integerValue];
    if (imageHeight <= 0){
        [inputNumberNotValidLabel setHidden:NO];
        return;
    } else
        [inputNumberNotValidLabel setHidden:YES];
    
    //change the UI prior to and after the processing of PDF files
    //show the indicator
    [imageProcessingProgressIndicator setHidden:NO];
    //disable the buttons while processing
    [convertButton setEnabled:NO];
    [convertButton setTitle:@"Busying..."];
    [openFileButton setEnabled:NO];
    [openFileButton setTitle:@"Busying..."];
    [uploadButton setEnabled:NO];
    [uploadButton setTitle:@"Busying..."];
    //start the processor
    @try {        
        imageprocessor = nil;
        imageprocessor = [[czzImageProcessor alloc]init];
        imageprocessor.delegate = self; //make self its delegate
        [imageprocessor setPDFPaths:[[czzSingleton sharedInstance] selectedPDFFiles] toPath:self.targetPath];
        //set image quality, format and height
        if ([[imageQualityRadioButton.selectedCell title] hasPrefix:@"High"]){
            [imageprocessor setImageQuality:1];
        } else {
            [imageprocessor setImageQuality:0];
        }
        if ([[imageFormatRadioButton.selectedCell title] hasPrefix:@"P"]){
            [imageprocessor setImageFormat:NSPNGFileType];
        } else {
            [imageprocessor setImageFormat:NSJPEGFileType];
        }
        [imageprocessor setImageHeight:imageHeight];
        //NSLog(@"set imageheight = %lu", imageHeight);
        //start the processing
        [imageprocessor startTheConversion];
    }
    @catch (NSException *exception) {
        NSAlert *alert = [[NSAlert alloc]init];
        [alert setMessageText:[NSString stringWithFormat:@"Error with the conversion:\n%@", [imageprocessor getError]]];
    }
    //change the UI back to normal
    //hide the indicator
    [imageProcessingProgressIndicator setHidden:YES];
    [convertButton setEnabled:YES];
    [openFileButton setEnabled:YES];
    [convertButton setTitle:@"Start conversion"];
    [openFileButton setTitle:@"Open PDF files"];
    [uploadButton setEnabled:YES];
    [uploadButton setTitle:@"Upload files to server"];

}


//two simple methods for starting/stoping progress indicator
-(void)startProgress{
    [busyingIndicator startAnimation:nil];
}

-(void)stopProgress{
    [busyingIndicator stopAnimation:nil];
}

-(void)updateCUrrentlyProcessingInfo:(NSString*)status{
    [self.statusTextField setStringValue:status];
}

//method from czzImageProcessorFileReadyDelegate and czzDescriptionFileDelegate
-(void)fileReady:(NSString *)file{
    //if the given file has not been registrated yet
    if (![[[czzSingleton sharedInstance] processedFiles] containsObject:file]){
        [[[czzSingleton sharedInstance] processedFiles] addObject:file];
    }
}

-(void)conversionProgressFor:(NSString *)file status:(NSString *)status progress:(NSInteger)progress{
    [self.statusTextField setStringValue:[NSString stringWithFormat:@"%@ is %@", file, status]];
    [self.imageProcessingProgressIndicator setDoubleValue:progress];
}

//tableview delegates
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [[czzSingleton sharedInstance] selectedPDFFiles].count; //calculate rows base on how many pdf are selected
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSString *headerCellStringValue = [tableColumn.headerCell stringValue];
    if ([headerCellStringValue hasPrefix:@"Filename"]){
        if (row < [[czzSingleton sharedInstance] selectedPDFInfos].count){
            //NSLog(@"filename row %lu returning %@", row, [[[czzSingleton sharedInstance] selectedPDFInfos] objectAtIndex:row]);
            return [[[czzSingleton sharedInstance] selectedPDFInfos] objectAtIndex:row];//here we display pdf file names
        }
    } else if ([headerCellStringValue hasPrefix:@"Filepath"]){
        if (row < [[czzSingleton sharedInstance] selectedPDFFiles].count){
            //here we store a full path to the file
            //NSLog(@"filepath row %lu returning %@", row, [[[czzSingleton sharedInstance] selectedPDFFiles] objectAtIndex:row]);
            return  [[[czzSingleton sharedInstance] selectedPDFFiles] objectAtIndex:row];
        }
    }
    return nil;
}

//corresponding to user selection, change the preview image view
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)rowIndex {
    //NSLog(@"should select: %lu", rowIndex);
    if (rowIndex < [[czzSingleton sharedInstance] selectedPDFFiles].count){
        //NSLog(@"selected object = %@", [[[czzSingleton sharedInstance] selectedPDFFiles] objectAtIndex:rowIndex]);
        //user selected this row, then change the imageview to this image
        [self performSelector:@selector(generatePreview:) withObject:[[[czzSingleton sharedInstance] selectedPDFFiles] objectAtIndex:rowIndex]];
        selectedPDFPath = [[[czzSingleton sharedInstance] selectedPDFFiles] objectAtIndex:rowIndex]; //change current path to the current row
    }
    return YES;
}


//quit the application when this window is closed
- (void)windowWillClose:(NSNotification *)notification{
    
    [NSApp terminate:self];
}

//copy from apple.com, provides an easy way to create CGPDFDocumentRef, referenced in openFiles method
CGPDFDocumentRef getCGPDFDocument (const char *filename)
{
    CFStringRef path;
    CFURLRef url;
    CGPDFDocumentRef document;
    size_t count;
    
    path = CFStringCreateWithCString (NULL, filename,
                                      kCFStringEncodingUTF8);
    url = CFURLCreateWithFileSystemPath (NULL, path, // 1
                                         kCFURLPOSIXPathStyle, 0);
    CFRelease (path);
    document = CGPDFDocumentCreateWithURL (url);// 2
    CFRelease(url);
    count = CGPDFDocumentGetNumberOfPages (document);// 3
    if (count == 0) {
        printf("`%s' needs at least one page!", filename);
        return NULL;
    }
    return document;
}

@end
