//
//  BonjourBroadcast.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/5/22.
//

import Foundation
import Network

let browser = Browser(type:"_kvm._tcp", domain:"local")

class Browser {

    let browser: NWBrowser

    init(type: String, domain: String) {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjourWithTXTRecord(type: type, domain: domain), using: parameters)
    }

    func start() {
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
                    @unknown default:
                    print("No metadata")

                    }
                }
            }
        }
        browser.start(queue: .main)
    }
}
