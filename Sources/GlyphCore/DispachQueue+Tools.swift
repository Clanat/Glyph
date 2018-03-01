//
//  DispachQueue+Tools.swift
//  GlyphNetworkFramework
//
//  Created by nikita on 23/02/2018.
//

import Foundation

public extension DispatchQueue {
    public static var current: DispatchQueue {
        return DispatchQueue(label: String(cString: __dispatch_queue_get_label(nil)))
    }
}
