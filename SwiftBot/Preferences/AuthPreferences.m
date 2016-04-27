//
//  GeneralPreferences.m
//  SwiftBot
//
//  Created by David Hedbor on 2/20/16.
//  Copyright © 2016 NeoTron. All rights reserved.
//

#import "AuthPreferences.h"
#import "SwiftBot-Swift.h"

@interface AuthPreferences ()
@property (weak) IBOutlet NSTextField *email;

@end

@implementation AuthPreferences


- (NSString *)identifier
{
    return @"AuthPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameUserAccounts];
}

- (NSString *)toolbarItemLabel
{
    return @"Authentication";
}

- (void)viewWillAppear
{
    DiscordAccount *account = [[DiscordAccount alloc] init];
    _email.stringValue = account.token;
}


- (IBAction)validateCredentials:(id)sender {
    NSString *token = _email.stringValue;
    AuthenticationManager *manager = [AuthenticationManager instance];
    if(token.length) {
        [manager updateCredentialsWithToken: token];
    }
}

@end
