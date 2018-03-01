//
//  AuthCodes.swift
//  GlyphRealmServer
//
//  Created by nikita on 25/02/2018.
//

import Foundation

enum AuthResult: UInt8 {
    case success                                = 0x00
    case failBanned                             = 0x03
    case failUnknownAccount                     = 0x04
    case failIncorrectPassword                  = 0x05
    case failAlreadyOnline                      = 0x06
    case failNoToTime                           = 0x07
    case failDBBusy                             = 0x08
    case failInvalidVersion                     = 0x09
    case failVersionUpdate                      = 0x0A
    case failInvalidServer                      = 0x0B
    case failSuspended                          = 0x0C
    case failNoAccess                           = 0x0D
    case successSurvey                          = 0x0E
    case failParentControl                      = 0x0F
    case failLockedEnforsed                     = 0x10
    case failTrialEnded                         = 0x11
    case failUseBattleNet                       = 0x12
    case failAntiIndulgence                     = 0x13
    case failExpired                            = 0x14
    case failNoGameAccount                      = 0x15
    case failChargeBack                         = 0x16
    case failInternetGameRoomWithoutBNet        = 0x17
    case failGameAccountLocked                  = 0x18
    case failInlockableLock                     = 0x19
    case failConversionRequired                 = 0x20
    case failDisconnected                       = 0xFF
}

enum LoginResult: UInt8
{
    case ok                                     = 0x00
    case failed                                 = 0x01
    case failed2                                = 0x02
    case banned                                 = 0x03
    case unknownAccount                         = 0x04
    case unknownAccount3                        = 0x05
    case alreadyOnline                          = 0x06
    case noTime                                 = 0x07
    case dbBusy                                 = 0x08
    case badVersion                             = 0x09
    case downloadFile                           = 0x0A
    case failed3                                = 0x0B
    case suspended                              = 0x0C
    case failed4                                = 0x0D
    case connected                              = 0x0E
    case parentalControl                        = 0x0F
    case lockedEnforced                         = 0x10
};
