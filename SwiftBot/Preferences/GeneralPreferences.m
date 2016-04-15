//
//  GeneralPreferences.m
//  SwiftBot
//
//  Created by David Hedbor on 2/20/16.
//  Copyright © 2016 NeoTron. All rights reserved.
//

#import "GeneralPreferences.h"
#import "SwiftBot-Swift.h"

@interface GeneralPreferences() <NSOutlineViewDataSource, NSOutlineViewDelegate>
@property (weak) IBOutlet NSTextFieldCell *commandPrefix;
@property (weak) IBOutlet NSTextField *databaseDirectory;
@property (weak) IBOutlet NSTextField *ownerIds;

@end

@implementation GeneralPreferences
{
@private
    NSMutableDictionary *configItems;
}

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return @"General";
}

- (instancetype)init
{
    if((self = [super init])) {
    }

    return self;
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    _commandPrefix.stringValue = [Config commandPrefix];
    _databaseDirectory.stringValue = [Config databaseDirectory]?:@"";
    NSSet *owners = [Config ownerIds];
    if([owners count]) {
        _ownerIds.stringValue = [[owners allObjects] componentsJoinedByString:@","];
    }
}

- (void)viewWillDisappear
{
    [Config setCommandPrefix:[_commandPrefix.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    [Config setDatabaseDirectory:_databaseDirectory.stringValue];
    NSArray *owners = [[_ownerIds.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
            componentsSeparatedByString:@","];
    [Config setOwnerIds:[NSSet setWithArray:owners]];
    [super viewWillDisappear];
}

@end

