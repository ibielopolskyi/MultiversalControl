//
//  BonjourBrowser.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/5/22.
//

import Foundation
import Network
import CoreData

var _browser: Browser? = nil

public func reBrowse(context: NSManagedObjectContext){
    if _browser != nil {
        _browser!.browser.cancel()
        _browser = nil
    }
    _browser = Browser(type:"_kvm._tcp", domain:"local", context: context)
}

class Browser {
    let context: NSManagedObjectContext

    let browser: NWBrowser

    init(type: String, domain: String, context: NSManagedObjectContext) {
        self.context = context
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjourWithTXTRecord(type: type, domain: domain), using: parameters)
        browser.browseResultsChangedHandler = { results, changes in
            for result in results {
                if case NWEndpoint.service = result.endpoint {
                    switch result.metadata {
                        case .bonjour(let record):
                            let monitor = Monitor.byName(context: self.context, name: record.dictionary["m"]!)
                            if (!monitor.local) {
                                monitor.onDiscovery(data: record.dictionary)
                                do {
                                    try self.context.save()
                                } catch {
                                    print("External display broadcast update has failed")
                                    print(error)
                                }
                            }
                        case .none:
                            return
                        @unknown default:
                            return
                    }
                }
            }
        }
        browser.start(queue: .main)
    }
}
