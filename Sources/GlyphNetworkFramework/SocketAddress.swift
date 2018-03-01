//
//  SocketAddress.swift
//  GlyphRealmServer
//
//  Created by nikita on 23/02/2018.
//

import Foundation

public struct SocketAddress {
    public let family: SocketAddressFamily
    public let port: UInt16
    public let host: String
    
    init?(rawAddress: sockaddr) {
        switch rawAddress.sa_family {
        case UInt8(AF_INET):
            var rawAddress = unsafeBitCast(rawAddress, to: sockaddr_in.self)
            port = CFSwapInt16(UInt16(rawAddress.sin_port))
            var buffer = [Int8](repeating: 0, count: Int(INET_ADDRSTRLEN))
            inet_ntop(AF_INET, &rawAddress.sin_addr, &buffer, socklen_t(buffer.count))
            host = String(cString: buffer)
            family = .ipv4
        case UInt8(AF_INET6):
            var rawAddress = unsafeBitCast(rawAddress, to: sockaddr_in6.self)
            port = CFSwapInt16(UInt16(rawAddress.sin6_port))
            var buffer = [Int8](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            inet_ntop(AF_INET6, &rawAddress.sin6_addr, &buffer, socklen_t(buffer.count))
            host = String(cString: buffer)
            family = .ipv6
        default: return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension SocketAddress: CustomStringConvertible {
    public var description: String {
        return "\(host):\(port)"
    }
}

// MARK: - Utility

extension SocketAddress {
    // TODO: support ipv6?
    
    public static func makeRaw(host: String? = nil, port: UInt16) -> sockaddr_in {
        var address = sockaddr_in()
        address.sin_len = __uint8_t(MemoryLayout.size(ofValue: address))
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(port).bigEndian
        if let host = host {
            address.sin_addr.s_addr = inet_addr(host)
        } else {
            address.sin_addr.s_addr = INADDR_ANY.bigEndian
        }
        
        return address
    }
}

public enum SocketAddressFamily {
    case ipv4
    case ipv6
}











