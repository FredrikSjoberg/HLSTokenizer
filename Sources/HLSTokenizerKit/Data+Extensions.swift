//
//  Data+Extensions.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-10-21.
//  Copyright (c) 2018 Fredrik Sjöberg. All rights reserved.
//  License - MIT, see LICENSE
//

import Foundation

public protocol Playlist {
    var tokens: [TokenClassification] { get }
}

public struct MasterPlaylist {
    
}

public struct MediaPlaylist {
    public let tokens: [TokenClassification]
}

public class PlaylistClassifier {
//    public var on
//    public func process() {
//        let nextToken
//    }
}

public protocol PlaylistTagRule {
    func process(tokenClassification: TokenClassification, atIndex index: Int)
}


/**
 Basic Tags
 EXTM3U
 EXT-X-VERSION
 
 Media or Master Playlist Tags
 EXT-X-INDEPENDENT-SEGMENTS
 EXT-X-START
 
 Master Playlist Tags
 EXT-X-MEDIA
 EXT-X-STREAM-INF
 EXT-X-I-FRAME-STREAM-INF
 EXT-X-SESSION-DATA
 EXT-X-SESSION-KEY
 
 
 
 
 
 Media Segment Tags
 EXTINF
 EXT-X-BYTERANGE
 EXT-X-DISCONTINUITY
 EXT-X-KEY
 EXT-X-MAP
 EXT-X-PROGRAM-DATE-TIME
 EXT-X-DATERANGE
 
 Media Playlist Tags
 EXT-X-TARGETDURATION
 EXT-X-MEDIA-SEQUENCE
 EXT-X-DISCONTINUITY-SEQUENCE
 EXT-X-ENDLIST
 EXT-X-PLAYLIST-TYPE
 EXT-X-I-FRAMES-ONLY
 
 
 
 
 
 */







/// TODO: Break `Data` into overlapping, indexed chuncks
///
/// This will allow async parsing




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
