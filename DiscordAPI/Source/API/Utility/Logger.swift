//
// Created by David Hedbor on 2/12/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation

private func _shouldLogLevel(level: LoggingLevel) -> Bool {
    if !Registry.instance.debugEnabled && level == .Debug {
        return false
    }
    return true
}
private func _logMessage(message: String, withLevel level: LoggingLevel, file: String, function: String, line: Int32) {
    if(!_shouldLogLevel(level)) {
        return
    }
    let nsfile = NSString(string:file)
    NSLog("| \(level.rawValue) \(nsfile.lastPathComponent):\(line) | \(message) (\(function))")
}

public enum LoggingLevel : String{
    case Info = " INFO", Error = "ERROR", Debug = "DEBUG"
}

public func LOG_INFO(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int32 = __LINE__ ) {
    _logMessage(message, withLevel: .Info, file: file, function: function, line: line)
}

public func LOG_ERROR(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int32 = __LINE__ ) {
    _logMessage(message, withLevel: .Error, file: file, function: function, line: line)
}

public func LOG_DEBUG(message: String, file: String = __FILE__, function: String = __FUNCTION__, line: Int32 = __LINE__ ) {
    _logMessage(message, withLevel: .Debug, file: file, function: function, line: line)
}
