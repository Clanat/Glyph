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
import BigInt
import Cryptor

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

enum AccountSecurityKind: UInt8 {
    case none           = 1
    case pin            = 2
    case matrix         = 3
    case token          = 4
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
    fileprivate static let testAccountCredentials: (salt: Data, verificationKey: Data) = {
        return createSaltedVerificationKey(username: "test", password: "test", group: srpGroup, algorithm: .sha1)
    }()
    
    typealias ErrorCallback = (_ error: Error) -> Void
    typealias CloseCallback = () -> Void

    enum Phase {
        case logonChallenge
        case logonProof
        case reconnectProof
        case authorized
        case waitingRealmList
        case closed
    }

    let id: Int32
    
    fileprivate static let srpPrime = BigUInt("894B645E89E1535BBDAD5B8B290650530801B18EBFBF5E8FAB3C82872A3E9BB7", radix: 16)!
    fileprivate static let srpPrimeString = String(srpPrime, radix: 16)
    fileprivate static let srpPrimeData = srpPrime.serialize()
    
    fileprivate static let srpGenerator = BigUInt(integerLiteral: 7)
    fileprivate static let srpGeneratorString = String(srpGenerator, radix: 16)
    fileprivate static let srpGeneratorData = srpGenerator.serialize()
    
    fileprivate static let srpGroup = Group(prime: srpPrimeString, generator: srpGeneratorString)!

    fileprivate(set) var phase =  Phase.logonChallenge
    
    fileprivate let socket: Socket
    fileprivate let lock = NSLock()

    fileprivate var closeCallback: CloseCallback?
    fileprivate var errorCallback: ErrorCallback?
    
    fileprivate var logonChallengeInfo: LogonChallengeInfo!
    fileprivate var srp: SRP.Server!
    
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
        case .logonChallenge: return handleLogonChallengeCommand()
        case .logonProof: return handleLogonProofCommand()
        default: return false
        }
    }
}

// MARK: - Logon challenge phase

extension AuthSession {
    fileprivate func handleLogonChallengeCommand() -> Bool {
        guard phase == .logonChallenge else { return false }

        guard let logonChallengeInfo: LogonChallengeInfo = socket.inputBuffer.read() else {
            return false
        }
        
        self.logonChallengeInfo = logonChallengeInfo

        let authResult = getAuthResult()
        guard authResult == .success else {
            didFailLogonChallenge(with: authResult)
            return true
        }

        sendLogonChallengeResponse(accountName: logonChallengeInfo.accountName)
        
        return true
    }

    fileprivate func getAuthResult() -> AuthResult {
        guard let challengeInfo = self.logonChallengeInfo else {
            return .failDisconnected
        }
        
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
    
    fileprivate func sendLogonChallengeResponse(accountName: String) {
        
        let testAccountCredentials = AuthSession.testAccountCredentials
        srp = Server(username: accountName,
                     salt: testAccountCredentials.salt,
                     verificationKey: testAccountCredentials.verificationKey,
                     group: AuthSession.srpGroup,
                     algorithm: .sha1)
        
        let packet = ByteBuffer(capacity: 1024)
        
        packet.write(AuthCommand.logonChallenge.rawValue)
        packet.write(UInt8(0x00))   // unknown
        packet.write(AuthResult.success.rawValue)
        
        // B (SRP public server key)
        let publicKeyData = srp.publicKey
        guard publicKeyData.count == 32 else { fatalError("Invalid SRP public key") }
        packet.write(publicKeyData)
        
        // g (SRP generator)
        let srpGeneratorData = AuthSession.srpGeneratorData
        guard srpGeneratorData.count == 1 else { fatalError("Invalid SRP generator") }
        packet.write(UInt8(srpGeneratorData.count))
        packet.write(srpGeneratorData)
        
        // N (SRP prime)
        let srpPrimeData = AuthSession.srpPrimeData
        guard srpPrimeData.count == 32 else { fatalError("Invalid SRP prime") }
        packet.write(UInt8(srpPrimeData.count))
        packet.write(srpPrimeData)
        
        // s (SRP user's salt)
        let srpSaltData = testAccountCredentials.salt
        packet.write(srpSaltData)
        packet.write([UInt8](repeating: 0, count: 16))
        
        // CRC salt (A salt to be used in AuthLogonProof_Client.crc_hash)
        let crcSalt = BigUInt.randomInteger(withExactWidth: 16 * 8)
        let crcSaltData = crcSalt.serialize()
        guard crcSaltData.count == 16 else { fatalError("Invalid crc salt") }
        packet.write(crcSaltData)
        
        
        // TODO: 2-factor auth
        packet.write(AccountSecurityKind.none.rawValue)
        //        if securityFlag == .pin {
        //
        //        } else if securityFlag == .matrix {
        //
        //        } else if securityFlag == .token {
        //
        //        }
        
        socket.sendAsync(packet)
        phase = .logonProof
    }
}

// MARK: - Logon proof phase

extension AuthSession {
    fileprivate func handleLogonProofCommand() -> Bool {
        guard phase == .logonProof else { return false }
        
        return true
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


