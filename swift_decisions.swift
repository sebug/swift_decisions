import Foundation
import Hpple
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

func getFormFilterNode(parser: TFHpple) -> TFHppleElement? {
    let nodes = parser.searchWithXPathQuery("//form[@name='formFilter']")
    if nodes.count >= 1 {
        return (nodes[0] as! TFHppleElement)
    } else {
        return nil
    }
}

func getPublics(baseElement: TFHppleElement) -> [String] {
    let publicsNodes = baseElement.searchWithXPathQuery("//input[@type='checkbox']")
    let thePublics =
        publicsNodes.map({publicNode in
        (publicNode as! TFHppleElement).attributes["value"] as! String
                         })
    return thePublics
}

func formatDateForURL(date: NSDate) -> String {
    let urlDateFormatter = NSDateFormatter()
    urlDateFormatter.dateFormat = "yyyyMMdd"
    return urlDateFormatter.stringFromDate(date)
}

func constructAgendaUrl(date: NSDate, publics: [String]) -> String {
    let dateString = formatDateForURL(date)
    let formEncodedPublics =
        publics.map({p in
        p.stringByReplacingOccurrencesOfString(" ", withString: "+")
                    })
    let publicsKvps =
        formEncodedPublics.map({p in
        "tx_displaycontroller%5Bpublic%5D%5B%5D=" + p
                               })
    let publicParams = publicsKvps.reduce("") {
        $0 + "&" + $1
    }
    
    return "\(agendaURL)?searchLocation=Recherche&tx_displaycontroller%5Blieux%5D=&tx_displaycontroller%5Bthemes%5D=&tx_displaycontroller%5Bgenres%5D=&tx_displaycontroller%5Bpublic%5D%5B%5D=Tout+afficher\(publicParams)&tx_displaycontroller%5BdatePickerStart%5D=\(dateString)&tx_displaycontroller%5BdatePickerEnd%5D=\(dateString)&no_cache=1&Submit=Filtrer"
}

func getSearchPage(session: NSURLSession, pageNumber: Int, date: NSDate, publics: [String], signalCompletion: () -> ()) {
    if let url = NSURL(string: constructAgendaUrl(date, publics)) {
        let searchPageTask = session.dataTaskWithURL(url) {(data, response, error) in
            let parser = TFHpple(data: data, isXML: false)
            let agendaNews = parser.searchWithXPathQuery("//div[@class='content_agenda_news']/ul/li")
            if agendaNews.count >= 1 {

                for item in agendaNews {
                    let title = item.searchWithXPathQuery("//h3/a")
                    if title.count == 1 {
                        let theElement = title[0] as! TFHppleElement
                        println("Title: \(theElement.content)")
                    }
                }
                
                let pages =
                    parser.searchWithXPathQuery("//li[@class='tx-pagebrowse-pages']/ol/li")
                
                if (pages.count > pageNumber) {
                    signalCompletion()
                } else {
                    signalCompletion()
                }
            } else {
                signalCompletion()
            }
        }
        searchPageTask.resume()
    } else {
        signalCompletion()
    }
}

func publicIsForMe(pub: String) -> Bool {
    return pub != "Tout afficher" &&
           pub != "Petite enfance" &&
           pub != "Enfants" &&
           pub != "Adolescents"
}

func constructInitialPageCallbackWithDate(date: NSDate, signalCompletion: () -> ()) -> ((NSData, NSURLSession) -> ()) {
    return {data, session in
        let parser = TFHpple(data: data, isXML: false)
        if let formFilter = getFormFilterNode(parser) {
            let thePublics = getPublics(formFilter)
            let filteredPublics =
                thePublics.filter(publicIsForMe)
            getSearchPage(session, 1, date, filteredPublics, signalCompletion)
        } else {
            signalCompletion()
        }
    }
}

func getInitialPage(cb: (NSData, NSURLSession) -> ()) -> NSURLSessionDataTask? {
    let theSession = NSURLSession.sharedSession()
    if let url = NSURL(string: agendaURL) {
        let fetchTask = theSession.dataTaskWithURL(url) {(data, _, _) in
            cb(data, theSession)
        }
        fetchTask.resume()
        return fetchTask
    }
    return nil
}

let semaphore = dispatch_semaphore_create(0)
let signalCompletion = {
    () -> () in
    dispatch_semaphore_signal(semaphore)
}
let theCallback = constructInitialPageCallbackWithDate(dateOrNow(getDateArgument(Process.arguments)), signalCompletion)
if let getInitialPageTask = getInitialPage(theCallback) {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
}






