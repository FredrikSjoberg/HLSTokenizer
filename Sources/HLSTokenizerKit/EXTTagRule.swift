//
//  EXTTagRule.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-10-23.
//

import Foundation

public struct EXTTagRule: TagRule {
    public let debugPrint: Bool
    public init(debugPrint: Bool = false) {
        self.debugPrint = debugPrint
    }
    
    internal enum TraceType {
        case generic
        case quotedString
    }
    
    internal enum State {
        case value
        case list
        case extinf
    }
    
    public static let prefix = "#EXT"
    public static let prefixETXINF = "#EXTINF"
    
    public func canResolve(token: String) -> Bool {
        guard token.count >= 4 else { return false }
        return token.hasPrefix(EXTTagRule.prefix)
    }
    
    public func resolve(token: String) throws -> Tag {
        let parts = token.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
        guard let rawType = parts.first else {
            throw TokenizerError.missingTagType(token: token).nsError()
        }
        
        let type = String(rawType)
        if parts.count == 1 {
            guard !type.hasPrefix(EXTTagRule.prefixETXINF) else {
                throw TokenizerError.missingValueInEXTINF(token: token).nsError()
            }
            return EXTTag(rawRepresentation: token, type: type)
        }
        else if type.hasPrefix(EXTTagRule.prefixETXINF) {
            var possibleValue: String?
            var desc: String?
            try extract(values: String(parts[1]), inToken: token, isEXTINF: true, onValue: {
                possibleValue = $0
            }, onKey: {
                desc = $0
            })
            guard let value = possibleValue else {
                /// A value is required for EXTINF
                throw TokenizerError.missingValueInEXTINF(token: token).nsError()
            }
            return EXTINFTag(rawRepresentation: token, type: type, value: value, desc: desc)
        }
        else {
            var values: [String] = []
            var keys: [String] = []
            try extract(values: String(parts[1]), inToken: token, onValue: {
                values.append($0)
            }, onKey: {
                keys.append($0)
            })
            if keys.isEmpty {
                /// We are expecting 1 value
                guard let value = values.first, values.count == 1 else {
                    /// Unexpected number of values
                    throw TokenizerError.unexpectedValueCountInEXT(token: token, count: values.count).nsError()
                }
                return EXTTag(rawRepresentation: token, type: type, value: value)
            }
            else {
                guard values.count == keys.count else {
                    /// Mismatch between keys and values
                    throw TokenizerError.keyValueMismatchInEXT(token: token, keys: keys, values: values).nsError()
                }
                
                return EXTTag(rawRepresentation: token, type: type, attributes: Dictionary(uniqueKeysWithValues: zip(keys, values)))
            }
        }
    }
    
    
    internal func extract(values: String, inToken token: String, isEXTINF: Bool = false, onValue: (String) -> Void, onKey: (String) -> Void) throws {
        var traceType: TraceType = .generic
        var state: State = .value
        
        var traceStart: String.Index = values.startIndex
        
        var currentIndex = values.startIndex
        while currentIndex != values.endIndex {
            let current = values[currentIndex]
            
            switch traceType {
            case .quotedString:
                if current == "\"" {
                    /// Marks the end of a Quoted-String
                    traceType = .generic
                    let part = values[(traceStart...currentIndex)]
                    traceStart = currentIndex
                    if debugPrint { print(current,"#<-- QUOTED STRING",state,part) }
                    onValue(String(part))
                }
                else {
                    /// Still in the Quoted-String, keep filling
                    
                    //                    let previousIndex = values.index(before: currentIndex)
                    //                    let previousCharacter = values[previousIndex]
                    //                    if previousCharacter == "\"" {
                    //                        traceStart = currentIndex
                    //                    }
                    if debugPrint { print(current,"#--> VALUE QS",state) }
                }
            case .generic:
                if current == "=" {
                    /// Marks the end of a key and the start of the related value
                    state = .list
                    
                    guard currentIndex != values.startIndex else {
                        throw TokenizerError.unexpected(character: "=", at: currentIndex, inToken: token).nsError()
                    }
                    
                    /// --> Store the Key range
                    let part = values[(traceStart..<currentIndex)]
                    traceStart = currentIndex
                    if debugPrint { print(current,"#--> ASSOCIATOR",state,part) }
                    onKey(String(part))
                }
                else if current == "," {
                    switch state {
                    case .value, .extinf:
                        state = .extinf
                        guard isEXTINF else {
                            throw TokenizerError.invalidPatternInNonEXTINF(token: token).nsError()
                        }
                    case .list: state = .list
                    }
                    
                    guard currentIndex != values.startIndex else {
                        throw  TokenizerError.unexpected(character: ",", at: currentIndex, inToken: token).nsError()
                    }
                    
                    let part = values[(traceStart..<currentIndex)]
                    traceStart = currentIndex
                    if debugPrint { print(current,"#--> SEPARATOR",state,part) }
                    switch state {
                    case .extinf: onValue(String(part))
                    case .list:
                        let previousIndex = values.index(before: currentIndex)
                        let previousCharacter = values[previousIndex]
                        if previousCharacter != "\"" {
                            onValue(String(part))
                        }
                    default: if debugPrint { print("WILL NOT TRIGGER k/v") }
                    }
                }
                else if current == "\"" {
                    guard currentIndex != values.startIndex else {
                        throw  TokenizerError.unexpected(character: "\"", at: currentIndex, inToken: token).nsError()
                    }
                    let previousIndex = values.index(before: currentIndex)
                    let previousCharacter = values[previousIndex]
                    if previousCharacter == "=" {
                        /// Marks the start of a Quoted-String
                        traceType = .quotedString
                        traceStart = currentIndex
                        if debugPrint { print(current,"#--> QUOTED STRING",state) }
                    }
                    else {
                        /// Double-quotes should only occur after an associator
                        throw  TokenizerError.unexpected(character: "\"", at: currentIndex, inToken: token).nsError()
                    }
                }
                else {
                    /// Data for the current key or value. Keep filling the range
                    if currentIndex > values.startIndex {
                        let previousIndex = values.index(before: currentIndex)
                        let previousCharacter = values[previousIndex]
                        if previousCharacter == "=" || previousCharacter == "," {
                            traceStart = currentIndex
                        }
                    }
                    if debugPrint { print(current,"K/V",state) }
                }
            }
            
            currentIndex = values.index(after: currentIndex)
        }
        guard currentIndex != values.startIndex else {
            /// No token
            return
        }
        let previousIndex = values.index(before: currentIndex)
        let lastCharacter = values[previousIndex]
        if lastCharacter == "=" {
            throw  TokenizerError.unexpected(character: "=", at: previousIndex, inToken: token).nsError()
        }
        if lastCharacter == "," {
            if state != .extinf {
                throw  TokenizerError.unexpected(character: ",", at: previousIndex, inToken: token).nsError()
            }
            else {
                if debugPrint { print("#--> IGNORING AT END",state,lastCharacter) }
            }
        }
        else if lastCharacter == "\"" {
            // Will be caught above if "\"" is not preceeded by "=".
            // If "\"" is the terminating character in a list which ends with a .quotedString, it is valid but we can ignore it.
            if debugPrint { print("#--> IGNORING AT END",state,lastCharacter) }
        }
        else {
            let part = values[(traceStart..<currentIndex)]
            if debugPrint { print("#--> ENDED",state,part) }
            onValue(String(part))
        }
    }
}
