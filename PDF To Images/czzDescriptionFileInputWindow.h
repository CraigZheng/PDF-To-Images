//
//  czzDescriptionFileInputWindow.h
//  PDF To Images
//
//  Created by Craig on 5/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol czzDescriptionFileDelegate <NSObject>

-(void)fileReady:(NSString*)file; //notify delegate that the description file is ready

@end

@interface czzDescriptionFileInputWindow : NSWindowController<NSTableViewDataSource, NSTableViewDelegate>
-(void)setupDescriptionFile:(NSArray*)filePaths withTargetPath:(NSString*)path;//this one returns all saved description file

@property (strong) IBOutlet NSTableView *filelistTableView;
@property (nonatomic, retain) id<czzDescriptionFileDelegate> delegate;

- (IBAction)dismissSelf:(id)sender;
- (IBAction)saveDescriptions:(id)sender;

@end
