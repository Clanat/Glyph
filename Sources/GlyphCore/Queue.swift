//
//  Queue.swift
//  GlyphNetworkFramework
//
//  Created by nikita on 23/02/2018.
//

import Foundation

public class Queue<T> {
    fileprivate var elements = [T?]()
    fileprivate var headElementIndex = 0
    
    public init() { }
    
    public var isEmpty: Bool {
        return count == 0
    }
    
    public var count: Int {
        return elements.count - headElementIndex
    }
    
    public func enqueue(_ element: T) {
        elements.append(element)
    }
    
    @discardableResult
    public func dequeue() -> T? {
        guard headElementIndex < elements.count, let element = elements[headElementIndex] else { return nil }
        
        elements[headElementIndex] = nil
        headElementIndex += 1
        
        let percentage = Float(headElementIndex) / Float(elements.count)
        if elements.count > 50 && percentage > 0.25 {
            elements.removeFirst(headElementIndex)
            headElementIndex = 0
        }
        
        return element
    }
    
    public var front: T? {
        guard !isEmpty else { return nil }
        return elements[headElementIndex]
    }
}
