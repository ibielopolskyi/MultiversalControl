//
//  BonjourAdvertise.swift
//  MultiversalControl
//
//  Created by Igor Bielopolskyi on 9/6/22.
//

import Foundation
import Network

var servers: [Monitor: Server] = [:]

func reAdvertise(monitor: Monitor) {
    var server = servers[monitor]
    if (server != nil) {
        server!.stop()
        server = nil
    }
    if (monitor.local) {
        do {
            server = try Server(monitor: monitor)
        } catch {
            print("Could not initialize server")
        }
        servers[monitor] = server
    }
}

class Server {
    let listener: NWListener

    convenience init(monitor: Monitor) throws {
        try self.init(type: "_kvm._tcp", monitor: monitor)
    }

    init(type: String = "_kvm._tcp", monitor: Monitor) throws {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 2

        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.includePeerToPeer = true
        listener = try NWListener(using: parameters)
        
        listener.service = NWListener.Service(name: monitor.name!, type: type, domain: "local", txtRecord: try monitor.to_dns())
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
