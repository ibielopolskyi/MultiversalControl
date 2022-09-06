//
//  BonjourAdvertise.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/6/22.
//

import Foundation
import Network

var server: Server? = nil

func reAdvertise(txtRecord: NWTXTRecord){
    print("re-advertisement")
    if (server != nil) {
        server!.stop()
        server = nil
    }
    do {
        server = try Server(txtRecord: txtRecord)
    } catch {
        print("Could not initialize server")
    }
}

class Server {
    let listener: NWListener

    convenience init(txtRecord: NWTXTRecord) throws {
        try self.init(type: "_kvm._tcp", txtRecord:txtRecord)
    }

    init(type: String = "_kvm._tcp", txtRecord: NWTXTRecord) throws {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2

        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.includePeerToPeer = true
        listener = try NWListener(using: parameters)
        
        listener.service = NWListener.Service(name: "server", type: type, domain: "local", txtRecord: txtRecord)
        listener.stateUpdateHandler = { newState in
            print("listener.stateUpdateHandler \(newState)")
        }
        listener.newConnectionHandler = { newConnection in
            print("listener.newConnectionHandler \(newConnection)")
        }
        listener.start(queue: .main)
    }

    func stop() {
        listener.cancel()
    }
}
