//
//  SLLog.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-04.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Fabric
import Crashlytics
import CocoaLumberjack

class SLLog {
  
  // MARK: - Constants
  struct Constants {
    #if DEBUG
    fileprivate static let StdoutMinSeverity = DDLogLevel.verbose
    fileprivate static let RotatingMinSeverity = DDLogLevel.debug
    fileprivate static let OsLogMinSeverity = DDLogLevel.debug
    fileprivate static let CrashlyticsLogMinSeverity = DDLogLevel.debug
    #else
    fileprivate static let StdoutMinSeverity = DDLogLevel.debug
    fileprivate static let RotatingMinSeverity = DDLogLevel.debug
    fileprivate static let OsLogMinSeverity = DDLogLevel.info
    fileprivate static let CrashlyticsLogMinSeverity = DDLogLevel.debug  // Lower to .info for AppStore release maybe?
    #endif
  }
  
  
  // MARK: - Public Static Functions
  static func initializeLogging() {
    
//    DDTTYLogger.sharedInstance.logFormatter = XcodeLogFormatter()
//    DDLog.add(DDTTYLogger.sharedInstance, with: Constants.StdoutMinSeverity)  // TTY = Xcode console
//    DDOSLogger.sharedInstance.logFormatter = ParsableLogFormatter(delimiter: " | ", omitTime: true)
//    DDLog.add(DDOSLogger.sharedInstance, with: Constants.OsLogMinSeverity)  // OSL = Apple OS Logs
    
    #if DEBUG
    // Unfortunately, OSLog is also writing to TTYLogger... So give up OSLog in Debug
    DDTTYLogger.sharedInstance.logFormatter = XcodeLogFormatter()
    DDLog.add(DDTTYLogger.sharedInstance, with: Constants.StdoutMinSeverity)

    #else
    // For Release, we'll assume that we only care about the OS Log
    DDOSLogger.sharedInstance.logFormatter = ParsableLogFormatter(delimiter: " | ", omitTime: true)
    DDLog.add(DDOSLogger.sharedInstance, with: Constants.OsLogMinSeverity)
    #endif
    
    // Crashlytics Logger
    CrashlyticsLogger.sharedInstance.logFormatter = ParsableLogFormatter(delimiter: " | ")
    DDLog.add(CrashlyticsLogger.sharedInstance, with: Constants.CrashlyticsLogMinSeverity)
    
    // File Logger, under Application Support/Cache/Log
    let fileLogger: DDFileLogger = DDFileLogger() // File Logger
    fileLogger.rollingFrequency = TimeInterval(60*60*24)  // 24 hours
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7
    fileLogger.logFormatter = ParsableLogFormatter(delimiter: " | ")
    DDLog.add(fileLogger, with: Constants.RotatingMinSeverity)
  }
  
  static func initializeReporting() {
    Fabric.with([Crashlytics.self])
    let uuidString = UIDevice.current.identifierForVendor!.uuidString
    Crashlytics.sharedInstance().setUserIdentifier(uuidString)
    info("Device UUID - \(uuidString)")
  }
  
  
  // TODO: - Consider User Information & Key Value Information on Crash
  
  static func verbose(_ description: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
    DDLogVerbose(description, file: file, function: function, line: line)
  }
  
  static func debug(_ description: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
    DDLogDebug(description, file: file, function: function, line: line)
  }
  
  static func info(_ description: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
    DDLogInfo(description, file: file, function: function, line: line)
  }
  
  static func warning(_ description: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
    DDLogWarn(description, file: file, function: function, line: line)
  }
  
  // Assertion will halt (crash) on development. Behavior similar to warning on release
  static func assert(_ description: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) {
    DDLogError(description, file: file, function: function, line: line)
    #if DEBUG  // TODO: -  Crash in current thread after sleep if Xcode is connected
    sleep(1)  // This just merely prevents this thread from proceeding, but also relinquish processor resources to other threads
    Crashlytics.sharedInstance().crash()  // Wait for logging to flush before Crashing
    #endif
  }
  
  // This is Fatal and will never return, Development or Production
  static func fatal(_ description: String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line) -> Never {
    DDLogError(description, file: file, function: function, line: line)
    sleep(1) // Sleep this thread and wait for logging to flush before going Fatal
    Crashlytics.sharedInstance().crash()  // TODO: -  Crash in current thread after sleep if Xcode is connected
    fatalError("\(description), \(file), \(function), \(line)")  // This won't actually get called
  }
}


// MARK: - Defining Custom Log Recorder for Crashlytics Log & Error Reporting
class CrashlyticsLogger: DDAbstractLogger
{
  static let sharedInstance = CrashlyticsLogger()
  
  private var internalFormatter: DDLogFormatter?
  
  override internal var logFormatter: DDLogFormatter? {
    set {
      super.logFormatter = newValue
      internalFormatter = newValue
    }
    get {
      return super.logFormatter
    }
  }
  
  override func log(message logMessage: DDLogMessage) {
    var messageText = logMessage.message
    
    if let formatter = internalFormatter,
      let formatedText = formatter.format(message: logMessage) {
      messageText = formatedText
    }
    
    CLSLogv("%@", getVaList([messageText])) // As suggested at the bottom of https://stackoverflow.com/questions/28054329/how-to-use-crashlytics-logging-in-swift
  }
}


// MARK: - Defining Custom Log Formatter to augment XcodeLogFormatter and ParsableLogFormatter
fileprivate class XcodeLogFormatter: NSObject, DDLogFormatter {
  let omitTime: Bool
  
  init(omitTime: Bool = false) {
    self.omitTime = omitTime
  }
  
  func format(message logMessage: DDLogMessage) -> String? {
    let delimiter = "\t"
    var formattedText = ""
    
    if !omitTime {
      // Timestamp - GMT
      let dateFormatter = DateFormatter()
      dateFormatter.locale = Locale(identifier: "en_US_POSIX")
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
      dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
      
      formattedText += dateFormatter.string(from: logMessage.timestamp)
      formattedText += delimiter
    }
    
    // Log Severity symbol
    if logMessage.flag.contains(.verbose) {
      formattedText += "▫️"
    } else if logMessage.flag.contains(.debug) {
      formattedText += "▪️"
    } else if logMessage.flag.contains(.info) {
      formattedText += "🔷"
    } else if logMessage.flag.contains(.warning) {
      formattedText += "🔶"
    } else if logMessage.flag.contains(.error) {
      formattedText += "❌"
    } else {
      formattedText += "🚫"
    }
    
    formattedText += delimiter
    
    // Log Message Payload
    formattedText += logMessage.message
    formattedText += delimiter + "@ "
    
    // Call Site - Filename, line, function
    formattedText += logMessage.fileName + ":\(logMessage.line)"
    
    if let function = logMessage.function {
      formattedText += " - " + function
    }
    
    return formattedText
  }
}


fileprivate class ParsableLogFormatter: NSObject, DDLogFormatter {
  let delimiter: String
  let omitTime: Bool
  
  init(delimiter: String, omitTime: Bool = false) {
    self.delimiter = delimiter
    self.omitTime = omitTime
  }
  
  func format(message logMessage: DDLogMessage) -> String? {
    var formattedText = ""
   
    if !omitTime {
      // Timestamp - GMT
      let dateFormatter = DateFormatter()
      dateFormatter.locale = Locale(identifier: "en_US_POSIX")
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
      dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
      
      formattedText += dateFormatter.string(from: logMessage.timestamp)
    }
    
    // Either way, seperate from OS timestamp, or our own timestamp
    formattedText += delimiter
    
    // Log Severity symbol
    if logMessage.flag.contains(.verbose) {
      formattedText += "1"
    } else if logMessage.flag.contains(.debug) {
      formattedText += "2"
    } else if logMessage.flag.contains(.info) {
      formattedText += "3"
    } else if logMessage.flag.contains(.warning) {
      formattedText += "4"
    } else if logMessage.flag.contains(.error) {
      formattedText += "5"
    } else {
      formattedText += "0"
    }
    formattedText += delimiter
    
    // Thread ID is always the same for some reason, pretty useless
//    formattedText += logMessage.threadID
//    formattedText += delimiter
    
    // Log Call Site - Filename, linefunction
    formattedText += logMessage.fileName + ":\(logMessage.line)"
    formattedText += delimiter
    
    // Log Function
    if let function = logMessage.function {
      formattedText += function
      formattedText += delimiter
    }
    
    // Log Message Payload
    formattedText += logMessage.message
    
    return formattedText
  }
}
