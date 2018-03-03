//
//  TCPServer.swift
//  GlyphNetworkFramework
//
//  Created by nikita on 26/02/2018.
//

import Foundation
import CLibEvent
import GlyphCore

public class Listener {
    public typealias ConnectionCallback = (Socket) -> Void
    public typealias ErrorCallback = (Error) -> Void
    
    public enum Event {
        case connectionAccepted(ConnectionCallback)
        case error(ErrorCallback)
    }
    
    public let host: String?
    public let port: UInt16
    
    fileprivate var connectionCallback: ConnectionCallback?
    fileprivate var errorCallback: ErrorCallback?
    
    fileprivate let eventBasePtr: OpaquePointer = {
        guard let eventBasePtr = event_base_new() else { fatalError("Unable to create event base") }
        return eventBasePtr
    }()
    
    fileprivate let rawAddress: sockaddr_in
    
    fileprivate var listenerPtr: OpaquePointer?
    fileprivate let lock = NSLock()

    public init(host: String? = nil, port: UInt16) {
        self.host = host
        self.port = port

        rawAddress = SocketAddress.makeRaw(host: host, port: port)
    }
    
    deinit {
        if let listener = listenerPtr {
            evconnlistener_free(listener)
        }
    }

    public func start() {
        let acceptConnectionCallback: evconnlistener_cb = { (/* listenerPtr */ _, socketHandle, addressPtr, addressSize, context) in
            guard let context = context else { fatalError("Invalid context") }
            guard let addressPtr = addressPtr else { fatalError("Invalid address") }
            guard let address = SocketAddress(rawAddress: addressPtr.pointee) else { fatalError("Invalid address") }
            
            let theSelf = Unmanaged<Listener>.fromOpaque(context).takeUnretainedValue()
            theSelf.handleAcceptCallback(socketHandle: socketHandle, address: address)
                                         
        }
        
        let context = Unmanaged.passUnretained(self).toOpaque()
        let flags = LEV_OPT_REUSEABLE | LEV_OPT_CLOSE_ON_FREE | LEV_OPT_CLOSE_ON_EXEC | LEV_OPT_REUSEABLE_PORT | LEV_OPT_THREADSAFE
        var listenerAddress = unsafeBitCast(rawAddress, to: sockaddr.self)
        let addressSize = MemoryLayout.size(ofValue: rawAddress)
        let listenerPtr = evconnlistener_new_bind(eventBasePtr,
                                                  acceptConnectionCallback,
                                                  context,
                                                  flags,
                                                  -1,       // backlog (-1 is system default)
                                                  &listenerAddress,
                                                  Int32(addressSize))
        
        evconnlistener_set_error_cb(listenerPtr) { (/* listenerPtr */ _, context) in
            guard let context = context else { fatalError("Invalid context") }
            let theSelf = Unmanaged<Listener>.fromOpaque(context).takeUnretainedValue()
            theSelf.handleErrorCallback()
        }
        
        self.listenerPtr = listenerPtr
        event_base_dispatch(eventBasePtr)
    }
    
    public func on(event: Event) {
        synchronized(lockable: lock) {
            switch event {
            case .connectionAccepted(let callback): connectionCallback = callback
            case .error(let callback): errorCallback = callback
            }
        }
    }
}

// MARK: - Listener callback handlers

extension Listener {
    fileprivate func handleAcceptCallback(socketHandle: Int32, address: SocketAddress) {
        let socket = Socket(handle: socketHandle, address: address, eventBasePtr: eventBasePtr)
        synchronized(lockable: lock) {
            connectionCallback?(socket)
        }
    }
    
    fileprivate func handleErrorCallback() {
        // TODO: more correct error handling
        let message = String(cString: strerror(errno))
        fatalError(message)
    }
}


