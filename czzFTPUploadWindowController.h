//
//  czzFTPUploadWindowController.h
//  PDF To Images
//
//  Created by Craig on 24/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "czzUpdateLoginDetailsController.h"
#import "czzFileUploader.h"

@interface czzFTPUploadWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource, czzUpdateLoginDetailsDelegate, czzFTPUploaderDelegate, NSWindowDelegate>
@property (strong) IBOutlet NSTextField *statusLabel;
@property (strong) IBOutlet NSTableView *filelistTableView;
- (IBAction)uploadAction:(id)sender;
- (IBAction)deleteAction:(id)sender;
- (IBAction)updateLoginAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)addMoreAction:(id)sender;


@end
