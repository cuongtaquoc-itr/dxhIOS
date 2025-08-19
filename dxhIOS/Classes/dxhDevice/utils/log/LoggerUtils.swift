import Foundation

public class LoggerUtils {
    public static func generateLogFileName() -> String{
        let format = DateFormatter()
        format.dateFormat = "yyyy_MM_dd"
        format.timeZone = TimeZone.current
        
        return "log_\(format.string(from: Date().startOfDay)).txt"
    }
    
    
    static func generateLogTag(tag: String, logLevel: Int)-> String {
        do {
            let format = DateFormatter()
            format.dateFormat = "HH:mm:ss"
            format.timeZone = TimeZone.current
            let stringDate = format.string(from: Date())
            return "[DB-[\(stringDate)]-[\(logLevel)]-\(tag)]"
        } catch {

            return "[DB-[\(logLevel)]-\(tag)]"
        }
    }
    
    public static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
