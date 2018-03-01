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
    var ip: UInt32 = 0                  // client_ip
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

        
        
//        socket.on(event: .error(<#T##Socket.ErrorCallback##Socket.ErrorCallback##(Error) -> Void#>))
//
//        socket.on(event: .data(handleSocketData))
//        socket.on(event: .error(handleSocketError))
//        socket.on(event: .timeout(handleSocketTimeout))

        GlyphLog.debug("Started new auth session for remote address: \(socket.address)")
    }

    deinit {
        GlyphLog.debug("Closing auth session for remote address: \(socket.address)")
    }

    func onClose(_ callback: @escaping CloseCallback) {
        synchronized(lockable: lock) {
            closeCallback = callback
        }
    }

    func onError(_ callback: @escaping ErrorCallback) {
        synchronized(lockable: lock) {
            errorCallback = callback
        }
    }

    // MARK: - Control flow

    func close() {
        // TODO
    }
}

// MARK: - Socket callback handlers

extension AuthSession {
    // MARK: - Socket callback handlers

    fileprivate func handleSocketTimeout() {

    }

    fileprivate func handleSocketError(_ error: Error) {

    }

    fileprivate func handleSocketData() {
//        let data = socket.inputBuffer
//
//        while !data.isEmpty {
//            guard let rawCommand: AuthCommand.RawValue = data.peek(), let command = AuthCommand(rawValue: rawCommand) else {
//                close()
//                return
//            }
//
//            guard handleAuthCommand(command) else {
//                close()
//                return
//            }
//        }
    }
}

// MARK: - Auth command handlers

extension AuthSession {
    fileprivate func handleAuthCommand(_ command: AuthCommand) -> Bool {
        switch command {
        case .logonChallenge: return handleLogonChallenge()
        default: return false
        }
    }

    fileprivate func handleLogonChallenge() -> Bool {
//        guard status == .logonChallenge else { return false }
//
//        let data = socket.inputBuffer
//        guard let challengeInfo: LogonChallengeInfo = data.read() else {
//            return false
//        }
//
//        let packet = ByteBuffer(capacity: 1024)
//        packet.write(AuthCommand.logonChallenge.rawValue)
//        packet.write(UInt8(0))
//
//
//        socket.sendAsync(packet)
//
//        let authResult = getAuthResult(for: challengeInfo)
//
//        guard authResult == .success else {
//            packet.write(authResult.rawValue)
//            socket.sendAsync(packet)
//            return true
//        }

        return true
    }

    fileprivate func getAuthResult(for challengeInfo: LogonChallengeInfo) -> AuthResult {
        // FIXME: account validation, send error

        guard challengeInfo.accountName == "test" else {
            return .failNoAccess
        }

        return .success
    }
}

// MARK: - Equatable

extension AuthSession: Equatable {
    static func ==(lhs: AuthSession, rhs: AuthSession) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - AuthSessionError

enum AuthSessionError: Error {
    case invalidSocketState
}


