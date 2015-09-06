//
//  czzAppDelegate.m
//  PDF To Images
//
//  Created by Craig on 1/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import "czzAppDelegate.h"
#import "czzMainWindowController.h"

@interface czzAppDelegate()
@property (nonatomic, strong) czzMainWindowController *myWindowController;
@end

@implementation czzAppDelegate

@synthesize myWindowController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    [self.window orderOut:self.window];
    myWindowController = [[czzMainWindowController alloc]initWithWindowNibName:@"czzMainWindowController"];
    [myWindowController.window makeKeyAndOrderFront:self];
}

@end
