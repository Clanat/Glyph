//
//  EventEmitter.swift
//  GlyphCore
//
//  Created by nikita on 03/03/2018.
//

import Foundation

public protocol EventEmitter {
    associatedtype Event
    
    func on(event: Event)
}
