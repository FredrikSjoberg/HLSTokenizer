//
//  TagRule.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-10-23.
//

import Foundation

public protocol TagRule {
    func canResolve(token: String) -> Bool
    func resolve(token: String) throws -> Tag
}
