//
//  czzUpdateLoginDetailsController.h
//  PDF To Images
//
//  Created by Craig on 16/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@protocol czzUpdateLoginDetailsDelegate <NSObject> //this delegate allows notification of changed login details
-(void)loginDetailsDidChanged:(NSDictionary*)newInfo;
@end

@interface czzUpdateLoginDetailsController : NSWindowController 
@property (strong) IBOutlet NSTextField *serverInfo;
@property (strong) IBOutlet NSTextField *usernameInfo;
@property (strong) IBOutlet NSSecureTextField *passwordInfo;

@property (nonatomic, retain) id<czzUpdateLoginDetailsDelegate> delegate;

- (IBAction)okButton:(id)sender;
- (IBAction)cancelAction:(id)sender;
@end
