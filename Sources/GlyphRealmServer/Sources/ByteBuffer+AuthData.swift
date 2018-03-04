//
//  ByteBuffer+AuthData.swift
//  GlyphRealmServer
//
//  Created by nikita on 25/02/2018.
//

import Foundation
import GlyphCore

// MARK: - Common

extension ByteBuffer {
    func read() -> AuthCommand? {
        guard let raw: AuthCommand.RawValue = read() else { return nil }
        return AuthCommand(rawValue: raw)
    }
    
    func read() -> AccountSecurityKind? {
        guard let raw: AccountSecurityKind.RawValue = read() else { return nil }
        return AccountSecurityKind(rawValue: raw)
    }
}

// MARK: - ClientLogonChallenge

extension ByteBuffer {
    func read() -> ClientLogonChallenge? {
        guard let command: AuthCommand = read(), command == .logonChallenge else { return nil }
        guard let error: UInt8 = read() else { return nil }
        guard let size: UInt16 = read() else { return nil }
        guard let gameName: String = read(size: 4) else { return nil }
        guard let version: [UInt8] = read(count: 3), let build: UInt16 = read() else { return nil }
        guard let platform: String = read(size: 4) else { return nil }
        guard let os: String = read(size: 4) else { return nil }
        guard let locale: String = read(size: 4) else { return nil }
        guard let worldRegionBias: UInt32 = read() else { return nil }
        guard let ip: UInt32 = read() else { return nil }
        guard let accountNameSize: UInt8 = read() else { return nil }
        guard let accountName: String = read(size: Int(accountNameSize)) else { return   nil }
        
        let info = ClientLogonChallenge()
        info.command = command
        info.error = error
        info.size = size
        info.gameName = gameName
        info.clientVersion = ClientLogonChallenge.ClientVersion(major: version[0], minor: version[1], micro: version[2], build: build)
        info.platform = platform
        info.os = os
        info.locale = locale
        info.worldRegionBias = worldRegionBias
        info.ip = "\(ip & 0xFF).\((ip >> 8) & 0xFF).\((ip >> 16) & 0xFF).\((ip >> 24) & 0xFF)"
        info.accountName = accountName
        
        return info
    }
}

// MARK: - ClientLogonProof

extension ByteBuffer {
    func read() -> ClientLogonProof? {
        guard let command: AuthCommand = read(), command == .logonProof else { return nil }
        guard let publicKeyBytes: [UInt8] = read(count: 32) else { return nil }
        guard let proofKeyBytes: [UInt8] = read(count: 20) else { return nil }
        guard let crcHash: [UInt8] = read(count: 20) else { return nil }
        guard let numberOfKeys: UInt8 = read() else { return nil }
        guard let securityKind: AccountSecurityKind = read() else { return nil }
        
        let proof = ClientLogonProof()
        proof.publicKeyBytes = publicKeyBytes
        proof.proofKeyBytes = proofKeyBytes
        proof.crcHash = crcHash
        proof.numberOfKeys = numberOfKeys
        proof.securityKind = securityKind
        
        return proof
    }
}






