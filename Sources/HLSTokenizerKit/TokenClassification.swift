//
//  TokenClassification.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-10-23.
//

import Foundation

public enum TokenClassification: CustomStringConvertible {
    case tag(data: Tag)
    case uri(data: URL)
    case comment(data: String)
    case blankLine
    case error(data: Error)
    
    public var description: String {
        switch self {
        case .tag(data: let tag): return "TAG - \(tag)"
        case .uri(data: let uri): return "URI - \(uri)"
        case .comment(data: let data): return "CMT - \(data)"
        case .blankLine: return "BLN"
        case .error(data: let data): return "ERR - \(data)"
        }
    }
}
