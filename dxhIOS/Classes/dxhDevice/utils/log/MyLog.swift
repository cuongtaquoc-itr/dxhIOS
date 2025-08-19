import Foundation
public struct MyLog {
    /*
     Log level 1 highest priority
     
     07: Internet bridge whole packet
     
     09: TIO log
     10: Bytes of packet
     */
    //Select what priority log level to be log, the higher the log level the more log get printed
    //When using logAndWriteFile, log always get printed
    private static let  CUSTOM_LOG_LEVEL = 5
    private static var  LOG_FILE: URL?
    
    
    public static func log(tag: String, message: String) {
        log(tag: tag, message: message, logPriority: 5)
    }
    
    public static func log(tag: String, message: String, logPriority: Int) {
        printLog(tag: tag, message: message, logPriority: logPriority)
    }
    
    public static func logAndWriteFile(tag: String, message: String) {
        printLog(tag: tag, message: message, logPriority: 5)
        writeFile(message: "[\(tag)] \(message)")
    }
    
    private static func writeFile(message: String) {
        guard let logFile = LOG_FILE else{
            return
        }
        
        let format = DateFormatter()
        format.dateFormat = "HH:mm:ss"
        format.timeZone = TimeZone.current
        let stringDate = format.string(from: Date())
        let data = "[\(stringDate)] \(message)\n"
        guard let data = data.data(using: String.Encoding.utf8) else { return }

        if FileManager.default.fileExists(atPath: logFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: logFile, options: .atomicWrite)
        }
    }
    
    private static func printLog(tag: String, message: String, logPriority: Int) {
        if (CUSTOM_LOG_LEVEL < logPriority) {
            return
        }
        let logTag = LoggerUtils.generateLogTag(tag: tag, logLevel: logPriority)
        let logMessage = message.chunked(500)
        
        logMessage.forEach { it in
            print("\(logTag) \(it)")
        }
    }
    
    public static func setupLogger() {
        let logFilenName = LoggerUtils.generateLogFileName()
        let logFile = LoggerUtils.getDocumentsDirectory().appendingPathComponent(logFilenName)
        LOG_FILE = logFile
    }
    public static func deleteAllLog() {
        let fileManager = FileManager.default
        let logFile = LoggerUtils.getDocumentsDirectory()
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: logFile, includingPropertiesForKeys: [.nameKey])
            try fileURLs.forEach {
                try fileManager.removeItem(atPath: $0.path)
            }
        } catch {
            print("Error while enumerating files")
        }
    }
    public static func getAllLog() -> [URL] {
        do {
            let fileManager = FileManager.default
            let logFile = LoggerUtils.getDocumentsDirectory()
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: logFile, includingPropertiesForKeys: [.nameKey])
                print("fileURLs \(fileURLs)")
                return fileURLs.filter{ $0.pathExtension == "txt" }
            } catch {
                print("Error while enumerating files")
                return []
            }
            return []
        } catch {
            print(error)
            return []
        }
    }
    
    public static func getLogFile(logName: String) -> URL? {
        do {
            let fileManager = FileManager.default
            let logFile = LoggerUtils.getDocumentsDirectory()
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: logFile, includingPropertiesForKeys: [.nameKey])
                print("fileURLs \(fileURLs)")
                return fileURLs.filter{ $0.pathExtension == "txt" }.first{ $0.absoluteString.contains(logName)}
            } catch {
                print("Error while enumerating files")
                return nil
            }
            return nil
        } catch {
            print(error)
            return nil
        }
    }
    
    public static func deleteLogFile(logName: String) {
        do {
            let fileManager = FileManager.default
            let logFile = LoggerUtils.getDocumentsDirectory()
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: logFile, includingPropertiesForKeys: [.nameKey])
                print("fileURLs \(fileURLs)")
                if let url = fileURLs.filter{ $0.pathExtension == "txt" }.first{ $0.absoluteString.contains(logName)} {
                    try fileManager.removeItem(atPath: url.path)
                }
            } catch {
                print("Error while enumerating files")
            }
        } catch {
            print(error)
        }
    }
}
