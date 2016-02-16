//
//  main.m
//  SwiftBot
//
//  Created by David Hedbor on 2/12/16.
//  Copyright © 2016 NeoTron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SwiftBotCore/SwiftBotCore-Swift.h>
#import "petopt.h"

static char *configFile = NULL;
static char *importFile = NULL;

/*
 ** Fields are:
 **   Short option character
 **   Type & Flags
 **   Long option name
 **   Variable
 **   Help text
 */
PETOPTS pov[] = {
        { 'h', 0, "help", NULL, "Print help" },
        { 'c', POF_STR, "config", &configFile, "Configuration file (json)." },
        { 'i', POF_STR, "import", &importFile, "Import commands from file (json, yaml)" },
        { -1, 0, NULL, NULL, NULL }
};

static void print_usage(PETOPT *pp)
{
    fprintf(stdout, "Usage: swiftbot -c config.json [optargs]\n");
    petopt_print_usage(pp, stdout);

}

static int parse_option(PETOPT *pp, PETOPTS *pov, const char *arg) {
    switch(pov->s) {
        case 'h':
            print_usage(pp);
            exit(0);

        default:
            return 1;
    }

    return 0;
}

int main(int argc, const char *argv[]) {
    int err, i;
    PETOPT *pop;


    err = petopt_setup(&pop, 0, argc, argv, pov, parse_option, NULL);
    if(err) {
        if(err > 0) {
            fprintf(stderr, "petopt_setup: %s\n", strerror(err));
        }
        exit(1);
    }

    err = petopt_parse(pop, &argc, &argv);
    if(err) {
        if(err > 0) {
            fprintf(stderr, "petopt_parse_all: %s\n", strerror(err));
        }
        exit(1);
    }

    err = petopt_cleanup(pop);
    if(err) {
        if(err > 0) {
            fprintf(stderr, "petopt_cleanup: %s\n", strerror(err));
        }
        exit(1);
    }

    if(configFile == NULL) {
        print_usage(pop);
        exit(1);
    }
    @autoreleasepool {
        // insert code here...

        if(importFile != NULL) {
            CustomCommandImporter *importer = [[CustomCommandImporter alloc] initWithConfigFile:@(configFile)];
            [importer importFromFile:@(importFile)];
        } else {
            SwiftBotMain *botMain = [[SwiftBotMain alloc] initWithConfigFile:@(configFile)];
            __block BOOL shouldKeepRunning = YES;        // global
            [botMain runWithDoneCallback:^{
                shouldKeepRunning = NO;
            }];

            while(shouldKeepRunning && [[NSRunLoop currentRunLoop]
                                                   runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
                [NSThread sleepForTimeInterval:0.001]; // Prevent worse case busy looping with a little sleep.
            }
        }
    }
    return 0;
}
