//
//  ByteBuffer.swift
//  GlyphNetworkFramework
//
//  Created by nikita on 24/02/2018.
//

import Foundation

public class ByteBuffer {
    typealias UnsafeWriteHandler = (_ dataPtr: UnsafeMutableRawPointer) -> Void
    
    fileprivate let capacity: Int
    fileprivate let dataPtr: UnsafeMutablePointer<UInt8>
    
    fileprivate var readIndex = 0
    fileprivate var writeIndex = 0
    
    public var readAreaSize: Int { return writeIndex - readIndex }
    public var writeAreaSize: Int { return capacity - readAreaSize }
    
    public var isEmpty: Bool { return readAreaSize == 0 }
    public var isFull: Bool { return writeAreaSize == 0 }
    
    public var isBigEndian: Bool {
        return 32 == 32.bigEndian
    }
    
    public init(capacity: Int) {
        self.capacity = capacity
        dataPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
    }
    
    deinit {
        dataPtr.deallocate(capacity: capacity)
    }
    
    public func reset() {
        readIndex = 0
        writeIndex = 0
    }
    
    @discardableResult
    public func drain(_ count: Int) -> Bool {
        guard count <= readAreaSize else { return false }
        readIndex += count
        return true
    }
}

// MARK: - Reading

extension ByteBuffer {
    public func read<T: Numeric>() -> T? {
        return readUnsafe()
    }
    
    public func read(size: Int) -> String? {
        guard var bytes: [UInt8] = read(count: size) else { return nil }
        return String(cString: &bytes)
    }
    
    public func read<T: Numeric>(count: Int) -> [T]? {
        return readUnsafe(count: count)
    }
    
    public func read() -> Bool? {
        return readUnsafe()
    }
    
    public func read(count: Int) -> [Bool]? {
        return readUnsafe(count: count)
    }
    
    fileprivate func readUnsafe<T>() -> T? {
        let size = MemoryLayout<T>.size
        guard size <= readAreaSize else { return nil }
        defer { readIndex += size }
        return (dataPtr + readIndex).withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
    }
    
    fileprivate func readUnsafe<T>(count: Int) -> [T]? {
        let size = MemoryLayout<T>.size * count
        guard size <= readAreaSize else { return nil }
        defer { readIndex += size }
        let startPtr = (dataPtr + readIndex).withMemoryRebound(to: T.self, capacity: count) { $0 }
        return [T](UnsafeBufferPointer(start: startPtr, count: count))
    }
}

// MARK: - Writing

extension ByteBuffer {
    @discardableResult
    public func write<T: Numeric>(_ value: T) -> Bool {
        return writeUnsafe(value)
    }
    
    @discardableResult
    public func write<T: Numeric>(_ values: [T]) -> Bool {
        return writeUnsafe(values)
    }
    
    @discardableResult
    public func write(_ value: Bool) -> Bool {
        return writeUnsafe(value)
    }
    
    @discardableResult
    fileprivate func writeUnsafe<T>(_ values: [T]) -> Bool {
        let size = MemoryLayout<T>.size * values.count
        guard size <= writeAreaSize else { return false }
        var values = values
        guard memcpy(dataPtr + writeIndex, &values, size) != nil else { return false }
        writeIndex += size
        return true
    }
    
    @discardableResult
    fileprivate func writeUnsafe<T>(_ value: T) -> Bool {
        let size = MemoryLayout<T>.size
        guard size <= writeAreaSize else { return false }
        
        var value = value
        memcpy(dataPtr + writeIndex, &value, size)
        writeIndex += size
        return true
    }
}

// MARK: - Peek

extension ByteBuffer {
    public func peek<T: Numeric>() -> T? {
        return peekUnsafe()
    }
    
    public func peek<T: Numeric>(count: Int) -> [T]? {
        return peekUnsafe(count: count)
    }
    
    public func peek() -> Bool? {
        return peekUnsafe()
    }
    
    public func peek(count: Int) -> [Bool]? {
        return peekUnsafe(count: count)
    }
    
    fileprivate func peekUnsafe<T>() -> T? {
        let size = MemoryLayout<T>.size
        guard size <= readAreaSize else { return nil }
        return UnsafeRawPointer(dataPtr).load(fromByteOffset: readIndex, as: T.self)
    }
    
    fileprivate func peekUnsafe<T>(count: Int) -> [T]? {
        let size = MemoryLayout<T>.size * count
        guard size <= readAreaSize else { return nil }
        let startPtr = UnsafeRawPointer(dataPtr + readIndex).bindMemory(to: T.self, capacity: count)
        return [T](UnsafeBufferPointer(start: startPtr, count: count))
    }
}

// MARK: - Fast I/O

extension ByteBuffer {
    @discardableResult
    public func fastRead(size: Int) -> UnsafeMutablePointer<UInt8>? {
        guard size <= readAreaSize else { return nil }
        defer { readIndex += size }
        return dataPtr + readIndex
    }
    
    @discardableResult
    public func fastWrite(source: UnsafeRawPointer, size: Int) -> Bool {
        guard size <= writeAreaSize else { return false }
        guard memmove(dataPtr + writeIndex, source, size) != nil else { return false }
        writeIndex += size
        return true
    }
}










