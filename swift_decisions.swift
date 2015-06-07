import Foundation
import Hpple
let villeGeneveURL = "http://www.ville-geneve.ch"
let agendaURL = villeGeneveURL + "/agenda/"

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

struct AgendaOverviewItem {
    let title: String
    let tag: String
    let description: String?
}

func getNextPageLink(parser: TFHpple) -> NSURL? {
    let suivante = parser.searchWithXPathQuery("//li[@class='tx-pagebrowse-next']")
    if suivante.count >= 1 {
        let aElements = suivante[0].searchWithXPathQuery("//a")
        if (aElements.count > 0) {
            let absolutePath =
                (aElements[0] as! TFHppleElement).attributes["href"] as! String
            return NSURL(string: villeGeneveURL + absolutePath)
        } else {
            return nil
        }
    }
    return nil
}

func getContentString(item: TFHppleElement, query: String) -> String? {
    if let contentQuery = item.searchWithXPathQuery(query) {
        if contentQuery.count >= 1 {
            return (contentQuery[0] as! TFHppleElement).content as String
        }
    }
    return nil    
}

func getTitle(item: TFHppleElement) -> String? {
    return getContentString(item, "//h3/a")
}

func getTag(item: TFHppleElement) -> String? {
    return getContentString(item, "//p[@class='tagNews']")
}

func getDescription(item: TFHppleElement) -> String? {
    return getContentString(item, "//p[preceding::p[@class='tagNews']]")
}

func getAgendaNews(parser: TFHpple) -> [AgendaOverviewItem] {
    let agendaNews = parser.searchWithXPathQuery("//div[@class='content_agenda_news']/ul/li")
    if agendaNews.count >= 1 {
        let agendaItems = agendaNews.map {
            (item) -> AgendaOverviewItem?
            in
            let strongItem = item as! TFHppleElement
            if let title = getTitle(strongItem) {
                if let tag = getTag(strongItem) {
                    return AgendaOverviewItem(title: title, tag: tag, description: getDescription(strongItem))
                }
            }
            return nil
        }
        return agendaItems.filter({ $0 != nil }).map({ $0! })
    } else {
        return []
    }
}

func nextStep(session: NSURLSession, parser: TFHpple, items: [AgendaOverviewItem], signalCompletion: ([AgendaOverviewItem]) -> ()) {
    if let url = getNextPageLink(parser) {
        getPageFromLink(session, url, items, signalCompletion)
    } else {
        signalCompletion(items)
    }
}

func getPageFromLink(session: NSURLSession, url: NSURL, items: [AgendaOverviewItem], signalCompletion: ([AgendaOverviewItem]) -> ()) {
    let fetchPageTask = session.dataTaskWithURL(url) { (data, response, error) in
        let parser = TFHpple(data: data, isXML: false)
        let furtherAgendaItems = getAgendaNews(parser)
        nextStep(session, parser, items + furtherAgendaItems, signalCompletion)
    }
    fetchPageTask.resume()
}

func getSearchPage(session: NSURLSession, date: NSDate, publics: [String], signalCompletion: ([AgendaOverviewItem]) -> ()) {
    if let url = NSURL(string: constructAgendaUrl(date, publics)) {
        let searchPageTask = session.dataTaskWithURL(url) {(data, response, error) in
            let parser = TFHpple(data: data, isXML: false)
            let items = getAgendaNews(parser)
            nextStep(session, parser, items, signalCompletion)
        }
        searchPageTask.resume()
    } else {
        signalCompletion([])
    }
}

func publicIsForMe(pub: String) -> Bool {
    return pub != "Tout afficher" &&
           pub != "Petite enfance" &&
           pub != "Enfants" &&
           pub != "Adolescents" &&
           pub != "Seniors"
}

func constructInitialPageCallbackWithDate(date: NSDate, signalCompletion: ([AgendaOverviewItem]) -> ()) -> ((NSData, NSURLSession) -> ()) {
    return {data, session in
        let parser = TFHpple(data: data, isXML: false)
        if let formFilter = getFormFilterNode(parser) {
            let thePublics = getPublics(formFilter)
            let filteredPublics =
                thePublics.filter(publicIsForMe)
            getSearchPage(session, date, filteredPublics, signalCompletion)
        } else {
            signalCompletion([])
        }
    }
}

func getInitialPage(url: NSURL, cb: (NSData, NSURLSession) -> ()) -> NSURLSessionDataTask? {
    let theSession = NSURLSession.sharedSession()
    let fetchTask = theSession.dataTaskWithURL(url) {(data, _, _) in
        cb(data, theSession)
    }
    fetchTask.resume()
    return fetchTask
}

func displayAgendaItems(items: [AgendaOverviewItem]) {
    for agendaItem in items {
        println("* \(agendaItem.title)")
        println("  \(agendaItem.tag)")
        if let description = agendaItem.description {
            println(description)
        }
        println("")
    }
}

if let baseAgendaURL = NSURL(string: agendaURL) {
    let semaphore = dispatch_semaphore_create(0)

    getInitialPage(
               baseAgendaURL,
               constructInitialPageCallbackWithDate(
                   dateOrNow(getDateArgument(Process.arguments)),
                   {
                       (agendaItems: [AgendaOverviewItem]) -> () in
                   
                       displayAgendaItems(agendaItems)
    
                       dispatch_semaphore_signal(semaphore)
                   }))
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
}





