//
//  BonjourBroadcast.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/5/22.
//

import Foundation
import Network

var _browser:Browser? = nil

func reBrowse(){
    if _browser != nil {
        _browser!.browser.cancel()
        _browser = nil
    }
    _browser = Browser(type:"_kvm._tcp", domain:"local")
}

class Browser {
    let context = PersistenceController.shared.container.newBackgroundContext()
    let browser: NWBrowser

    init(type: String, domain: String) {
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
