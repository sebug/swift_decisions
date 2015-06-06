import Foundation

func getDateArgument() -> String? {
    if Process.arguments.count >= 2 {
        let dateFormatter = NSDateFormatter()
        return Process.arguments[1]
    } else {
        return nil
    }    
}

println("Usage: swift_decisions [date]")
let dateArgument : String? = getDateArgument()
println("The date argument is \(dateArgument)")




