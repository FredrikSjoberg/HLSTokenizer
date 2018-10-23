//
//  Tokenizer.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-10-23.
//

import Foundation

public class Tokenizer {
    public enum Details {
        case validOnly
        case includeBlankLines
        case complete
    }
    
    public init(tagRules: [TagRule] = [EXTTagRule()]) {
        self.tagRules = tagRules
    }
    
    public func process(data: Data, details: Details = .complete, callback: (TokenClassification) -> Void) {
        data.parseLines{
            if let line = $0 {
                if let token = self.classify(token: line, details: details) {
                    callback(token)
                }
            }
        }
    }
    
    public let tagRules: [TagRule]
    public func classify(token: String, details: Details) -> TokenClassification? {
        let token = classify(token: token)
        switch details {
        case .validOnly:
            switch token {
            case .blankLine, .error(data: _): return nil
            case .comment(data: _), .tag(data: _), .uri(data: _): return token
            }
        case .includeBlankLines:
            switch token {
            case .error(data: _): return nil
            case .comment(data: _), .tag(data: _), .uri(data: _), .blankLine: return token
            }
        case .complete:
            return token
        }
    }
    
    public func classify(token: String) -> TokenClassification {
        guard let character = token.first else {
            // Blank line
            return .blankLine
        }
        
        if character == "#" {
            // Tag or Comment
            let possibleRule = tagRules.first{ $0.canResolve(token: token) }
            guard let rule = possibleRule else {
                // Comment
                return .comment(data: token)
            }
            // Tag
            do {
                let tag = try rule.resolve(token: token)
                return .tag(data: tag)
            }
            catch {
                return .error(data: error)
            }
        }
        else {
            // URI
            guard let uri = URL(string: token) else {
                let error = TokenizerError.invalidURI(token: token).nsError()
                return .error(data: error)
            }
            return .uri(data: uri)
        }
    }
}
