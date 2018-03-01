//
//  Socket.swift
//  GlyphNetworkFramework
//
//  Created by nikita on 26/02/2018.
//

import Foundation
import CLibEvent
import GlyphCore

public class Socket {
    public typealias DataCallback = () -> Void
    public typealias TimeoutCallback = () -> Void
    public typealias ErrorCallback = (Error) -> Void
    
    public enum Event {
        case data(DataCallback)
        case timeout(TimeoutCallback)
        case error(ErrorCallback)
    }
    
    fileprivate static let readTimeout = 10     // sec
    fileprivate static let writeTimeout = 10    // sec
    
    fileprivate static let readWaterMark = 1...4096
    fileprivate static let writeWaterMark = 1...4096
    
    public let handle: Int32
    public let address: SocketAddress
    
    fileprivate let bufferEventPtr: OpaquePointer
    fileprivate let inputBuffer = ByteBuffer(capacity: Socket.readWaterMark.upperBound)
    
    fileprivate var dataCallback: DataCallback?
    fileprivate var timeoutCallback: TimeoutCallback?
    fileprivate var errorCallback: ErrorCallback?
    
    fileprivate let lock = NSLock()
    
    
    // MARK: - Lifecycle
    
    deinit {
        bufferevent_free(bufferEventPtr)
    }
    
    init(handle: Int32, address: SocketAddress, eventBasePtr: OpaquePointer) {
        self.handle = handle
        self.address = address
        
        let options = BEV_OPT_CLOSE_ON_FREE

        guard let eventPtr = bufferevent_socket_new(eventBasePtr, handle, Int32(options.rawValue)) else {
            fatalError("Unable to create buffer event")
        }
        
        bufferEventPtr = eventPtr
        setupBufferEvent()
    }
    
    fileprivate func setupBufferEvent() {
        let readCallback: bufferevent_data_cb = { eventPtr, context in
            guard let context = context else { fatalError("Invalid context") }
            let theSelf = Unmanaged<Socket>.fromOpaque(context).takeUnretainedValue()
            theSelf.handleInput()
        }
        
        let writeCallback: bufferevent_data_cb = { eventPtr, context in
            guard let context = context else { fatalError("Invalid context") }
            let theSelf = Unmanaged<Socket>.fromOpaque(context).takeUnretainedValue()
            theSelf.handleOutput()
        }
        
        let eventCallback: bufferevent_event_cb = { eventPtr, event, context in
            guard let context = context else { fatalError("Invalid context") }
            let theSelf = Unmanaged<Socket>.fromOpaque(context).takeUnretainedValue()
            theSelf.handleEvent(Int32(event))
        }
        
        let context = Unmanaged.passUnretained(self).toOpaque()
        bufferevent_setcb(bufferEventPtr, readCallback, writeCallback, eventCallback, context)
        
        var readTimeout = timeval(tv_sec: Socket.readTimeout, tv_usec: 0)
        var writeTimeout = timeval(tv_sec: Socket.writeTimeout, tv_usec: 0)
        bufferevent_set_timeouts(bufferEventPtr, &readTimeout, &writeTimeout)
        
        bufferevent_setwatermark(bufferEventPtr, Int16(EV_READ), Socket.readWaterMark.lowerBound, Socket.readWaterMark.upperBound)
        bufferevent_setwatermark(bufferEventPtr, Int16(EV_WRITE), Socket.writeWaterMark.lowerBound, Socket.writeWaterMark.upperBound)
        
        bufferevent_enable(bufferEventPtr, Int16(EV_READ | EV_WRITE | CLibEvent.EV_TIMEOUT))
    }
}

// MARK: - Socket callback bindings

extension Socket {
    public func on(event: Event) {
        synchronized(lockable: lock) {
            switch event {
            case .data(let callback): dataCallback = callback
            case .error(let callback): errorCallback = callback
            case .timeout(let callback): timeoutCallback = callback
            }
        }
    }
    
    
}

// MARK: - Buffer event callback handlers

extension Socket {
    fileprivate func handleInput() {
        guard !inputBuffer.isFull else { return }
        
        guard let bufferEventInput = bufferevent_get_input(bufferEventPtr) else { return }
        
        let writableDataSize = min(inputBuffer.writeAreaSize, evbuffer_get_length(bufferEventInput))
        guard writableDataSize > 0 else { return }
        
        let dataPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: writableDataSize)
        evbuffer_remove(bufferEventInput, dataPtr, writableDataSize)
        guard inputBuffer.moveData(from: dataPtr, count: writableDataSize) else {
            fatalError("Can't move data to buffer")
        }
        
        synchronized(lockable: lock) { dataCallback?() }
    }
    
    fileprivate func handleOutput() {
        
    }
    
    fileprivate func handleEvent(_ event: Int32) {
        // BEV_EVENT_READING: error encountered while reading
        // BEV_EVENT_WRITING: error encountered while writing
        // BEV_EVENT_EOF: eof file reached
        // BEV_EVENT_ERROR: unrecoverable error encountered
        // BEV_EVENT_TIMEOUT: user-specified timeout reached
        // BEV_EVENT_CONNECTED: connect operation finished

        if event & BEV_EVENT_TIMEOUT > 0 {
            handleTimeout()
        }
        
        if event & BEV_EVENT_READING > 0 {
            handleError(.readingFailed)
        }
        
        if event & BEV_EVENT_WRITING > 0 {
            handleError(.writingFailed)
        }
        
        if event & BEV_EVENT_ERROR > 0 {
            handleError(.unknown)
        }
    }
    
    fileprivate func handleTimeout() {
        synchronized(lockable: lock) { timeoutCallback?() }
    }
    
    fileprivate func handleError(_ error: SocketError) {
        synchronized(lockable: lock) { errorCallback?(error) }
    }
}

// MARK: - SocketError

public enum SocketError: Error {
    case readingFailed
    case writingFailed
    case unknown
}


