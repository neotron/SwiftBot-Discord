//
//  Preferences.m
//  SwiftBot
//
//  Created by David Hedbor on 2/20/16.
//  Copyright © 2016 NeoTron. All rights reserved.
//

#import "Preferences.h"
#import "GeneralPreferences.h"
#import "AuthPreferences.h"
#import <MASPreferences/MASPreferencesWindowController.h>

@implementation Preferences
#pragma mark - Public accessors

- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        NSArray *controllers = @[ [[GeneralPreferences alloc] init],
                                  [[AuthPreferences alloc] init]];
        _preferencesWindowController = [[MASPreferencesWindowController alloc]
                                                                        initWithViewControllers:controllers
                                                                                          title:@"Preferences"];
    }
    return _preferencesWindowController;
}

#pragma mark - Actions

- (void)openPreferences:(id __unused)sender
{
    [self.preferencesWindowController showWindow:nil];
}
@end
