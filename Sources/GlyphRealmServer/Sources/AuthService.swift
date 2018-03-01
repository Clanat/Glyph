//
//  AuthService.swift
//  GlyphRealmServer
//
//  Created by nikita on 21/02/2018.
//

import Foundation
import GlyphCore
import GlyphNetworkFramework

class AuthService {
    fileprivate let host: String?
    fileprivate let port: UInt16
    fileprivate let lock = NSLock()
    fileprivate let listenerQueue: DispatchQueue
    fileprivate let processingQueue: DispatchQueue
    
    fileprivate var listener: Listener!
    
    fileprivate lazy var sessions = [Int32: Unmanaged<AuthSession>]()
    
    init(host: String? = nil, port: UInt16) throws {
        self.host = host
        self.port = port
        
        listenerQueue = DispatchQueue(label: "com.glyph.authservice.listener", attributes: .concurrent)
        processingQueue = DispatchQueue(label: "com.glyph.authservice.processing", attributes: .concurrent)
        
        listener = Listener(host: host, port: port)
        listener.on(event: .connectionAccepted(handleConnection))
        listener.on(event: .error(handleListenerError))
    }
    
    func start() {
        listenerQueue.async { self.listener.start() }
        GlyphLog.info("AuthService started. Listening \(self.host ?? "<default host>"):\(self.port)")
    }
    
    func stop() throws {
        // TODO
    }
}

// MARK: - Listener callbacks

extension AuthService {
    fileprivate func handleConnection(with socket: Socket) {
        processingQueue.async { [weak self] in
            self?.startSession(for: socket)
        }
    }
    
    fileprivate func handleListenerError(_ error: Error) {
        fatalError(error.localizedDescription)
    }
}

// MARK: - AuthSessions managing

extension AuthService {
    fileprivate func startSession(for socket: Socket) {
        synchronized(lockable: lock) {
            let unmanagedSession = Unmanaged.passRetained(AuthSession(socket: socket))
            sessions[socket.handle] = unmanagedSession
        }
    }
}













