//
//  main.m
//  SwiftBot
//
//  Created by David Hedbor on 2/12/16.
//  Copyright © 2016 NeoTron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SwiftBotCore/SwiftBotCore-Swift.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        if(argc < 2) {
            NSLog(@"Syntax: %s <configfile.json>", argv[0]);
            exit(1);
        }
        SwiftBotMain *botMain = [[SwiftBotMain alloc] initWithConfigFile:@(argv[1])];
        __block BOOL shouldKeepRunning = YES;        // global
        [botMain runWithDoneCallback:^{
            shouldKeepRunning = NO;
        }];

        while (shouldKeepRunning && [[NSRunLoop currentRunLoop]
                                                runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
            [NSThread sleepForTimeInterval:0.001]; // Prevent worse case busy looping with a little sleep.
        }
    }
    return 0;
}
