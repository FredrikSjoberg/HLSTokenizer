//
//  Tag.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-10-23.
//

import Foundation

public protocol Tag: CustomStringConvertible {
    var rawRepresentation: String { get }
    var type: String { get }
}
