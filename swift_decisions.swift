import Foundation

func getDateArgument() -> NSDate? {
    if Process.arguments.count >= 2 {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return dateFormatter.dateFromString(Process.arguments[1])
    } else {
        return nil
    }
}

func dateOrNow(dateOpt: NSDate?) -> NSDate {
    if let date = dateOpt {
        return date
    } else {
        return NSDate()
    }
}

println("Usage: swift_decisions [date]")
let theDate = dateOrNow(getDateArgument())
println("The date argument is \(theDate)")




