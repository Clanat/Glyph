import Dispatch
import Foundation
import SwiftyBeaver
import GlyphNetworkFramework

let host = "192.168.0.122"
let port: UInt16 = 3724

LogManager.initialize()

let service = try AuthService(host: host, port: port)
service.start()


RunLoop.main.run()
