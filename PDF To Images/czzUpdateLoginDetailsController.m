//
//  czzUpdateLoginDetailsController.m
//  PDF To Images
//
//  Created by Craig on 16/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import "czzUpdateLoginDetailsController.h"

@interface czzUpdateLoginDetailsController ()

@end

@implementation czzUpdateLoginDetailsController
@synthesize usernameInfo = _usernameInfo, serverInfo = _serverInfo, passwordInfo = _passwordInfo; //initialise textfields

-(void)windowDidLoad{
    [super windowDidLoad];
    [self checkSavedLoginDetails];
}

//check previously saved details
-(void)checkSavedLoginDetails{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([prefs stringForKey:@"serverURL"] != nil){
        [self.serverInfo setStringValue:[prefs stringForKey:@"serverURL"]];
    }
    if ([prefs stringForKey:@"username"] != nil){
        [self.usernameInfo setStringValue:[prefs stringForKey:@"username"]];
    }
    if ([prefs stringForKey:@"password"] != nil){
        [self.passwordInfo setStringValue:[prefs stringForKey:@"password"]];
    }
}

//accept new infos, and save them regardless right or wrong
- (IBAction)okButton:(id)sender {
    NSString *newUsername, *newPassword, *newURL;
    newURL = self.serverInfo.stringValue;
    newUsername = self.usernameInfo.stringValue;
    newPassword = self.passwordInfo.stringValue;
    //save the newly modified infos
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if (newURL == nil){
        [self.serverInfo setStringValue:@"Invalid server address!"];
    } else {
        [prefs setValue:newURL forKey:@"serverURL"];
    }
    if (newUsername == nil){
        [self.usernameInfo setStringValue:@"Invalid username!"];
    } else {
        [prefs setValue:newUsername forKey:@"username"];
    }
    if (newPassword == nil){
        [self.passwordInfo setStringValue:@"Invalid password!"];
    } else {
        [prefs setValue:newPassword forKey:@"password"];
    }
    if (newURL && newUsername && newPassword){
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:newURL, @"serverURL", newPassword, @"password", newUsername, @"username", nil];
        [self.delegate loginDetailsDidChanged:dict]; //notify changed infos
        [self close];
        [self.window orderOut:self.window];
        [self checkSavedLoginDetails];
    }

}

- (IBAction)cancelAction:(id)sender {
    [self close];
}
@end
