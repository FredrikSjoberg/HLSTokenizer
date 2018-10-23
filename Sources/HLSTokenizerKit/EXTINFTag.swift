//
//  EXTINFTag.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-10-23.
//

import Foundation

public struct EXTINFTag: Tag {
    public let rawRepresentation: String
    public let type: String
    public let value: String
    public let desc: String?
    
    public init(rawRepresentation: String, type: String, value: String, desc: String? = nil) {
        self.rawRepresentation = rawRepresentation
        self.type = type
        self.value = value
        self.desc = desc
    }
    
    public var description: String {
        return type+":"+value+(desc != nil ? ","+desc! : "")
    }
}
