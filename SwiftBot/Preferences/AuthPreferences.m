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
@property (weak) IBOutlet NSSecureTextField *password;

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
    if(account.email.length) {
        _password.stringValue = account.password;
        _email.stringValue = account.email;

    }
}


- (IBAction)validateCredentials:(id)sender {
    NSString *password = _password.stringValue;
    NSString *email = _email.stringValue;
    AuthenticationManager *manager = [AuthenticationManager instance];
    [manager validateCredentialsWithEmail:email password:password callback:^(NSString *token, NSError *error) {
        if(token) {
            [manager updateCredentialsWithEmail:email password: password token: token];
        }
    }];
}

@end
