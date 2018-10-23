//
//  EXTTag.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-10-23.
//

import Foundation

public struct EXTTag: Tag {
    public let rawRepresentation: String
    public let type: String
    public let value: String?
    public let attributes: [String: String]?
    
    public init(rawRepresentation: String, type: String, value: String? = nil, attributes: [String: String]? = nil) {
        self.rawRepresentation = rawRepresentation
        self.type = type
        self.value = value
        self.attributes = attributes
    }
    
    public var description: String {
        if let value = value {
            return type+":"+value
        }
        else if let attributes = attributes {
            let attribs = attributes.map{ $0.key+"="+$0.value }.joined(separator: ",")
            return type+":"+attribs
        }
        else {
            return type
        }
    }
}
