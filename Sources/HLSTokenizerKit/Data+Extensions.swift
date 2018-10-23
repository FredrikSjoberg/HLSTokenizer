//
//  Data+Extensions.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-10-21.
//  Copyright (c) 2018 Fredrik Sjöberg. All rights reserved.
//  License - MIT, see LICENSE
//

import Foundation


/// TODO: Break `Data` into overlapping, indexed chuncks
///
/// This will allow async parsing

public struct MasterPlaylist {
    
}

public struct MediaPlaylist {
    
}












public extension Data {
    func parseLines(onLine: (String?) -> Void) {
        let delimiter = "\n".data(using: .utf8)!
        let options: Data.SearchOptions = []
        var currentIndex = startIndex
        while let slice = nextSlice(in: (currentIndex..<endIndex), delimiter: delimiter, options: options) {
            currentIndex = slice.1
            let line = String(bytes: slice.0, encoding: .utf8)
            onLine(line)
        }
        
        /// If there is no terminating line break, currentIndex will never reach endIndex. If so, we correct by extracting the last line
        if currentIndex != endIndex {
            let lastString = String(bytes: self[(currentIndex..<endIndex)], encoding: .utf8)
            onLine(lastString)
        }
    }
    
    func nextSlice(in searchRange: Range<Index>, delimiter: Data, options: Data.SearchOptions) -> (Data, Index)? {
        guard let index = range(of: delimiter, options: options, in: searchRange) else { return nil }
        return (self[searchRange.lowerBound..<index.lowerBound], index.upperBound)
    }
}
