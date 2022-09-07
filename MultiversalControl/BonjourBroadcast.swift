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
                            let model = MDNSModel(fromDict:record.dictionary)
                            print(record.dictionary)
                            model.save(remote: true)
                        case .none:
                            print("No metadata")
                            reBrowse()
                        @unknown default:
                            reBrowse()
                        }
                    }
                }
            }
        browser.start(queue: .main)
    }
}
