// gcc -Wall -arch i386 -arch ppc -mmacosx-version-min=10.4 -Os -framework AppKit -o relaunch relaunch.m

#import <AppKit/AppKit.h>

@interface TerminationListener : NSObject

- (void) relaunch;

@end

@implementation TerminationListener
{
@private
    const char *executablePath;
    pid_t parentProcessId;
}

- (id) initWithExecutablePath:(const char *)execPath parentProcessId:(pid_t)ppid
{
    self = [super init];
    if (self != nil) {
        executablePath = execPath;
        parentProcessId = ppid;
        
        // This adds the input source required by the run loop
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationDidTerminate:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
        if (getppid() == 1) {
            // ppid is launchd (1) => parent terminated already
            [self relaunch];
        }
    }
    return self;
}

- (void) applicationDidTerminate:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    if (parentProcessId == [userInfo[@"NSApplicationProcessIdentifier"] intValue]) {
        // parent just terminated
        int terminationCode = [userInfo[@"NSWorkspaceExitStatusKey"] intValue];
        if(terminationCode != 0) {
            NSLog(@"Terminated with non-zero exit code: %d", terminationCode);
            [self relaunch];
        }
    }
}

- (void) relaunch
{
    NSString *path = [NSString stringWithUTF8String:executablePath];
    NSLog(@"Attempting to relaunch app: %@", path);
    [[NSWorkspace sharedWorkspace] launchApplication:path];
    exit(0);
}
-(void)doNotWarn
{

}

@end

int main (int argc, const char * argv[])
{
    if (argc != 3) return EXIT_FAILURE;
    
    
    TerminationListener* listener = [[TerminationListener alloc] initWithExecutablePath:argv[1] parentProcessId:atoi(argv[2])];
    [listener doNotWarn];
    [[NSApplication sharedApplication] run];

    
    return EXIT_SUCCESS;
}
