//
//  LogManager.swift
//  GlyphRealmServer
//
//  Created by nikita on 23/02/2018.
//

import Foundation
import SwiftyBeaver

final class LogManager {
    static let log = SwiftyBeaver.self
    static let minLogLevel: SwiftyBeaver.Level = .debug
    
    private init() { }
    
    static func initialize() {
        let console = ConsoleDestination()
        console.minLevel = minLogLevel
        console.format = "$DHH:mm:ss$d GlyphRealm: $M"
        log.addDestination(console)
    }
}

let GlyphLog = LogManager.log

