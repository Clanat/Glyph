//
//  ByteBuffer+AuthData.swift
//  GlyphRealmServer
//
//  Created by nikita on 25/02/2018.
//

import Foundation
import GlyphCore

extension ByteBuffer {
    func read() -> LogonChallengeInfo? {
        guard let rawCommand: AuthCommand.RawValue = read(), let command = AuthCommand(rawValue: rawCommand) else { return nil }
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
        guard let accountName: String = read(size: Int(accountNameSize)) else { return nil }
        
        var info = LogonChallengeInfo()
        info.command = command
        info.error = error
        info.size = size
        info.gameName = gameName
        info.clientVersion = LogonChallengeInfo.ClientVersion(major: version[0], minor: version[1], micro: version[2], build: build)
        info.platform = platform
        info.os = os
        info.locale = locale
        info.worldRegionBias = worldRegionBias
        info.ip = "\(ip & 0xFF).\((ip >> 8) & 0xFF).\((ip >> 16) & 0xFF).\((ip >> 24) & 0xFF)"
        info.accountName = accountName
        
        return info
    }
}

