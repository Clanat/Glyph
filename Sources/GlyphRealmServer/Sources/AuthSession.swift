//
//  AuthSession.swift
//  GlyphRealmServer
//
//  Created by nikita on 23/02/2018.
//

import Foundation
import GlyphNetworkFramework
import GlyphCore
import SRP

// MARK: - AuthCommands

enum AuthCommand: UInt8 {
    case logonChallenge         = 0x00
    case logonProof             = 0x01
    case reconnectChallenge     = 0x02
    case reconnectProof         = 0x03
    case realmList              = 0x04

    case xferInitiate           = 0x30
    case xferData               = 0x31
    case xferAccept             = 0x32
    case xferResume             = 0x33
    case xferCancel             = 0x34
}

// MARK: - LogonChallengeInfo

struct LogonChallengeInfo {
    struct ClientVersion {
        var major: UInt8 = 0
        var minor: UInt8 = 0
        var micro: UInt8 = 0
        var build: UInt16 = 0
    }

    var command: AuthCommand = .logonChallenge
    var error: UInt8 = 0
    var size: UInt16 = 0                 // length of package minus 4
    var gameName: String = "WoW"        // 'WoW'
    var clientVersion = ClientVersion()
    var platform: String = "x86"        // eg 'x86'     char[4]
    var os: String = "Win"              // eg 'Win'     char[4]
    var locale: String = "enUS"         // eg 'enUS'    char[4]
    var worldRegionBias: UInt32 = 0     // offset in minutes from UTC time, eg. 180 means 180 minutes
    var ip: String = "0.0.0.0"                  // client_ip
    var accountName: String = ""

    init() {

    }
}


// MARK: - AuthSession

class AuthSession {
    typealias ErrorCallback = (_ error: Error) -> Void
    typealias CloseCallback = () -> Void

    enum Status {
        case logonChallenge
        case logonProof
        case reconnectProof
        case authorized
        case waitingRealmList
        case closed
    }

    let id: Int32

    fileprivate(set) var status: Status = .logonChallenge
    fileprivate let socket: Socket
    fileprivate let lock = NSLock()

    fileprivate var closeCallback: CloseCallback?
    fileprivate var errorCallback: ErrorCallback?

    // MARK: - Lifecycle

    init(socket: Socket) {
        self.socket = socket
        
        id = socket.handle
        
        socket.on(event: .data({ [weak self] in
            self?.handleSocketData()
        }))
        
        socket.on(event: .error({ [weak self] (error) in
            self?.handleSocketError(error)
        }))
        
        socket.on(event: .timeout({ [weak self] in
            self?.handleSocketTimeout()
        }))

        GlyphLog.debug("Started new auth session for remote address: \(socket.address)")
    }

    deinit {
        GlyphLog.debug("Closing auth session for remote address: \(socket.address)")
    }

    // MARK: - Control flow

    func close() {
        synchronized(lockable: lock) {
            closeCallback?()
        }
    }
}

// MARK: - Socket callback handlers

extension AuthSession {
    // MARK: - Socket callback handlers

    fileprivate func handleSocketTimeout() {
        close()
    }

    fileprivate func handleSocketError(_ error: Error) {
        close()
    }

    fileprivate func handleSocketData() {
        let data = socket.inputBuffer

        while !data.isEmpty {
            guard let rawCommand: AuthCommand.RawValue = data.peek(), let command = AuthCommand(rawValue: rawCommand) else {
                close()
                return
            }

            guard handleAuthCommand(command) else {
                close()
                return
            }
        }
    }
    
    fileprivate func handleAuthCommand(_ command: AuthCommand) -> Bool {
        switch command {
        case .logonChallenge: return handleLogonChallenge()
        default: return false
        }
    }
}

// MARK: - Logon challenge

extension AuthSession {
    

    fileprivate func handleLogonChallenge() -> Bool {
        guard status == .logonChallenge else { return false }

        let data = socket.inputBuffer
        guard let challengeInfo: LogonChallengeInfo = data.read() else {
            return false
        }

        let authResult = getAuthResult(for: challengeInfo)

        guard authResult == .success else {
            didFailLogonChallenge(with: authResult)
            return true
        }

        return true
    }

    fileprivate func getAuthResult(for challengeInfo: LogonChallengeInfo) -> AuthResult {
        // FIXME: account validation, send error

        guard challengeInfo.accountName.lowercased() == "test" else {
            return .failUnknownAccount
        }

        return .success
    }
    
    fileprivate func didFailLogonChallenge(with authResult: AuthResult) {
        var data: [UInt8] = [
            AuthCommand.logonChallenge.rawValue,
            0x00,
            authResult.rawValue,
        ]
        
        socket.sendAsync(&data)
    }
}

// MARK: - Equatable

extension AuthSession: Equatable {
    static func ==(lhs: AuthSession, rhs: AuthSession) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - EventEmitter

extension AuthSession: EventEmitter {
    enum Event {
        case error(ErrorCallback)
        case close(CloseCallback)
    }
    
    func on(event: Event) {
        synchronized(lockable: lock) {
            switch event {
            case .close(let callback): closeCallback = callback
            case .error(let callback): errorCallback = callback
            }
        }
    }
}

// MARK: - AuthSessionError

enum AuthSessionError: Error {
    case invalidSocketState
}


