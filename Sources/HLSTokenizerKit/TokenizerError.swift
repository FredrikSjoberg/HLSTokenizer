//
//  TokenizerError.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-10-23.
//

import Foundation

public enum TokenizerError {
    public static let errorDomain = "HLSTokenizerKitErrorDomain"
    public static let errorTokenKey = "HLSTokenizerKitErrorTokenKey"
    public static let errorInvalidCharacterKey = "HLSTokenizerKitErrorInvalidCharacterKey"
    public static let errorCharacterIndexKey = "HLSTokenizerKitErrorCharacterIndexKey"
    
    case missingTagType(token: String)
    case invalidURI(token: String)
    case unexpected(character: String, at: String.Index, inToken: String)
    case missingValueInEXTINF(token: String)
    case unexpectedValueCountInEXT(token: String, count: Int)
    case keyValueMismatchInEXT(token: String, keys: [String], values: [String])
    case invalidPatternInNonEXTINF(token: String)
    
    public var code: Int {
        switch self {
        case .missingTagType: return 1001
        case .invalidURI: return 1002
        case .unexpected(character: _, at: _, inToken: _): return 1003
        case .missingValueInEXTINF(token: _): return 1004
        case .unexpectedValueCountInEXT(token: _, count: _): return 1005
        case .keyValueMismatchInEXT(token: _, keys: _, values: _): return 1006
        case .invalidPatternInNonEXTINF(token: _): return 1007
        }
    }
    
    internal func nsError(customUserInfo: [String: Any]? = nil) -> NSError {
        var info = userInfo
        customUserInfo?.forEach{
            info[$0.key] = $0.value
        }
        return NSError(domain: TokenizerError.errorDomain, code: self.code, userInfo: info)
    }
    
    internal var userInfo: [String: Any] {
        switch self {
        case .missingTagType(token: let token): return [TokenizerError.errorTokenKey: token]
        case .invalidURI(token: let token): return [TokenizerError.errorTokenKey: token]
        case .unexpected(character: let character, at: let index, inToken: let token):
            return [
                TokenizerError.errorTokenKey: token,
                TokenizerError.errorInvalidCharacterKey: character,
                TokenizerError.errorCharacterIndexKey: index.encodedOffset
            ]
        case .missingValueInEXTINF(token: let token): return [TokenizerError.errorTokenKey: token]
        case .unexpectedValueCountInEXT(token: let token, count: let count):
            return [
                TokenizerError.errorTokenKey: token,
            ]
        case .keyValueMismatchInEXT(token: let token, keys: let keys, values: let values):
            return [
                TokenizerError.errorTokenKey: token,
            ]
        case .invalidPatternInNonEXTINF(token: let token): return [TokenizerError.errorTokenKey: token]
        }
    }
}
