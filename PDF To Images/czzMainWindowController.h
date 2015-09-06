//
//  czzWindowController.h
//  PDF To Images
//
//  Created by Craig on 1/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "czzImageProcessor.h"
#import "czzFileUploader.h"
#import "czzDescriptionFileInputWindow.h"

@protocol czzMainWindowControllerProtocol <NSObject>

-(void)fileReady:(NSString*)newFile;

@end

@interface czzMainWindowController : NSWindowController<NSTableViewDataSource, NSTableViewDelegate, czzImageProcessorFileReadyDeleate, czzDescriptionFileDelegate>
@property (strong) IBOutlet NSImageView *previewImageView;
//@property (strong) IBOutlet NSTableView *filelistTableView;
@property (strong) IBOutlet NSProgressIndicator *busyingIndicator;
@property (strong) IBOutlet NSProgressIndicator *imageProcessingProgressIndicator;
@property (strong) IBOutlet NSTableView *filelistTableView;

- (IBAction)openFile:(id)sender;
- (IBAction)startConversion:(id)sender;
- (IBAction)uploadFiles:(id)sender;
- (IBAction)enterDescriptionAction:(id)sender;

@property (strong) IBOutlet NSButton *convertButton;
@property (strong) IBOutlet NSButton *openFileButton;
@property (strong) IBOutlet NSButton *uploadButton;
@property (strong) IBOutlet NSTextField *statusTextField;
@property (strong) IBOutlet NSButton *autoUploadCheckbox;
@property (strong) IBOutlet NSMatrix *imageQualityRadioButton;
@property (strong) IBOutlet NSMatrix *imageFormatRadioButton;
@property (strong) IBOutlet NSTextField *imageHeightTextField;
@property (strong) IBOutlet NSTextField *inputNumberNotValidLabel;
@property (strong) IBOutlet NSTextField *clickHereToBeginLabel;

@property (strong, retain) id<czzMainWindowControllerProtocol> delegate;
@end
