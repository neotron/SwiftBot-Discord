import Foundation
import Dispatch
guard CommandLine.arguments.count == 2 else {
    LOG_ERROR("Expected argument: \(CommandLine.arguments.first!) <config file>")
    exit(2)
}

Config.loadConfigFrom(file: CommandLine.arguments[1])

let main = SwiftBotMain()
main.runWithDoneCallback() {
    LOG_INFO("Run complete, exiting.")
    exit(0)
}


dispatchMain()
