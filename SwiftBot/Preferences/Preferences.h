//
//  Preferences.h
//  SwiftBot
//
//  Created by David Hedbor on 2/20/16.
//  Copyright © 2016 NeoTron. All rights reserved.
//

@import Foundation;
@import AppKit;

@interface Preferences : NSObject
@property (nonatomic,strong) NSWindowController *preferencesWindowController;

- (void)openPreferences:(id __unused)sender;
@end
