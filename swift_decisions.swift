import Foundation
let agendaURL = "http://www.ville-geneve.ch/agenda/"

func getDateArgument(args: [String]) -> NSDate? {
    if args.count >= 2 {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        return dateFormatter.dateFromString(args[1])
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

func formatDateForURL(date: NSDate) -> String {
    let urlDateFormatter = NSDateFormatter()
    urlDateFormatter.dateFormat = "yyyyMMdd"
    return urlDateFormatter.stringFromDate(date)
}

func getInitialPage(signalCompletion: () -> ()) -> NSURLSessionDataTask? {
    if let url = NSURL(string: agendaURL) {
        let fetchTask = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, _, _) in
            if let body = NSString(data: data, encoding: NSUTF8StringEncoding) {
                let htmlStart = body.rangeOfString("<html")
                if let htmlData = body.substringWithRange(NSMakeRange(htmlStart.location,body.length - htmlStart.location)).dataUsingEncoding(NSUTF8StringEncoding) {
                    let htmlParser = NSXMLParser(data: htmlData)
                    let success = htmlParser.parse()
                    println("Success? \(htmlParser.lineNumber)")
                }
            }
            
            signalCompletion()
        }
        fetchTask.resume()
        return fetchTask
    }
    return nil
}

println("Usage: swift_decisions [date]")
let dateString = formatDateForURL(dateOrNow(getDateArgument(Process.arguments)))
println("\(agendaURL)?tx_displaycontroller%5BdatePickerStart%5D=\(dateString)&tx_displaycontroller%5BdatePickerEnd%5D=\(dateString)")
let semaphore = dispatch_semaphore_create(0)
let signalCompletion = {
    () -> () in
    dispatch_semaphore_signal(semaphore)
}
if let getInitialPageTask = getInitialPage(signalCompletion) {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
}






