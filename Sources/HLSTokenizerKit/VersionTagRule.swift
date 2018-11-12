//
//  VersionTagRule.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-11-11.
//

import Foundation


public class VersionTagRule: PlaylistTagRule {
    public var onError: (Error, Int, Tag) -> Void = { _,_,_ in }
    public enum Error {
        case malformatedVersionTag
        case multipleVersions
        case incompatibleTag(requiredVersion: Int, reportedVersion: Int?)
        case deprecatedTag(inVersion: Int, reportedVersion: Int?)
    }
    
    fileprivate var registeredVersion: Int?
    fileprivate var iFramesOnly = false
    
    public enum TagType: String {
        case version = "#EXT-X-VERSION"
        case key = "EXT-X-KEY"
        case extInf = "EXTINF"
        case byeRange = "EXT-X-BYTERANGE"
        case iFramesOnly = "EXT-X-I-FRAMES-ONLY"
        case map = "EXT-X-MAP"
        case media = "EXT-X-MEDIA"
        case allowCache = "EXT-X-ALLOW-CACHE"
        case streamInf = "EXT-X-STREAM-INF"
        case iFrameStreamInf = "EXT-X-I-FRAME-STREAM-INF"
    }
    
    public func process(tokenClassification: TokenClassification, atIndex index: Int) {
        guard case let TokenClassification.tag(data: tag) = tokenClassification else { return }
        
        switch tag.type {
        case TagType.version.rawValue: process(version: tag, atIndex: index)
        case TagType.key.rawValue: process(key: tag, atIndex: index)
        case TagType.extInf.rawValue: process(extInf: tag, atIndex: index)
        case TagType.byeRange.rawValue: process(byteRange: tag, atIndex: index)
        case TagType.iFramesOnly.rawValue: process(iFramesOnly: tag, atIndex: index)
        case TagType.map.rawValue: process(map: tag, atIndex: index)
        case TagType.media.rawValue: process(media: tag, atIndex: index)
        case TagType.allowCache.rawValue: process(allowCache: tag, atIndex: index)
        case TagType.streamInf.rawValue: process(iFrameStreamInf: tag, atIndex: index)
        case TagType.iFrameStreamInf.rawValue: process(iFrameStreamInf: tag, atIndex: index)
        default: return
        }
    }
}

extension VersionTagRule {
    fileprivate func evaluateTag(requierdVersion: Int) -> Error? {
        guard let version = registeredVersion else {
            return .incompatibleTag(requiredVersion: requierdVersion, reportedVersion: nil)
        }
        guard version >= 5 else {
            return .incompatibleTag(requiredVersion: requierdVersion, reportedVersion: version)
        }
        return nil
    }
    
    
    fileprivate func evaluateTag(deprecatedVersion: Int) -> Error? {
        guard let version = registeredVersion else {
            return .deprecatedTag(inVersion: deprecatedVersion, reportedVersion: nil)
        }
        guard version < 5 else {
            return .deprecatedTag(inVersion: deprecatedVersion, reportedVersion: version)
        }
        return nil
    }
    
}

extension VersionTagRule {
    /// A Playlist file MUST NOT contain more than one EXT-X-VERSION tag.
    fileprivate func process(version: Tag, atIndex index: Int) {
        guard let tag = version as? EXTTag else { return }
        guard let versionString = tag.value, let ver = Int(versionString) else {
            onError(.malformatedVersionTag, index, tag)
            return
        }
        
        guard registeredVersion == nil else {
            onError(.multipleVersions, index, tag)
            return
        }
        registeredVersion = ver
    }
    
    /// A Media Playlist MUST indicate a EXT-X-VERSION of 2 or higher if it ccontains:
    ///
    /// o  The IV attribute of the EXT-X-KEY tag.
    ///
    /// A Media Playlist MUST indicate a EXT-X-VERSION of 5 or higher if it contains:
    ///
    /// o  The KEYFORMAT and KEYFORMATVERSIONS attributes of the EXT-X-KEY tag.
    fileprivate func process(key: Tag, atIndex index: Int) {
        guard let tag = key as? EXTTag else { return }
        if tag.attributes?["KEYFORMAT"] != nil && tag.attributes?["KEYFORMATVERSIONS"] != nil  {
            if let error = evaluateTag(requierdVersion: 5) {
                onError(error, index, tag)
            }
        }
        else if tag.attributes?["IV"] != nil {
            if let error = evaluateTag(requierdVersion: 2) {
                onError(error, index, tag)
            }
        }
        
    }
    
    /// A Media Playlist MUST indicate a EXT-X-VERSION of 3 or higher if it contains:
    ///
    /// o  Floating-point EXTINF duration values.
    fileprivate func process(extInf: Tag, atIndex index: Int) {
        guard let tag = extInf as? EXTINFTag, Float(tag.value) != nil else { return }
        if let error = evaluateTag(requierdVersion: 3) {
            onError(error, index, tag)
        }
    }
    
    /// A Media Playlist MUST indicate a EXT-X-VERSION of 4 or higher if it contains:
    ///
    /// o  The EXT-X-BYTERANGE tag.
    fileprivate func process(byteRange: Tag, atIndex index: Int) {
        if let error = evaluateTag(requierdVersion: 4) {
            onError(error, index, byteRange)
        }
    }
    
    /// A Media Playlist MUST indicate a EXT-X-VERSION of 4 or higher if it contains:
    ///
    /// o  The EXT-X-I-FRAMES-ONLY tag.
    fileprivate func process(iFramesOnly: Tag, atIndex index: Int) {
        self.iFramesOnly = true
        if let error = evaluateTag(requierdVersion: 4) {
            onError(error, index, iFramesOnly)
        }
    }
    
    /// A Media Playlist MUST indicate a EXT-X-VERSION of 5 or higher if it contains:
    ///
    /// o  The EXT-X-MAP tag.
    ///
    /// A Media Playlist MUST indicate a EXT-X-VERSION of 6 or higher if it contains:
    ///
    /// o  The EXT-X-MAP tag in a Media Playlist that does not contain EXT-X-I-FRAMES-ONLY.
    fileprivate func process(map: Tag, atIndex index: Int) {
        if !iFramesOnly {
            if let error = evaluateTag(requierdVersion: 6) {
                onError(error, index, map)
            }
        }
        else {
            if let error = evaluateTag(requierdVersion: 5) {
                onError(error, index, map)
            }
        }
    }
    
    /// A Master Playlist MUST indicate a EXT-X-VERSION of 7 or higher if it contains:
    ///
    /// o  "SERVICE" values for the INSTREAM-ID attribute of the EXT-X-MEDIA tag.
    fileprivate func process(media: Tag, atIndex index: Int) {
        guard let tag = media as? EXTTag else { return }
        if let inStream = tag.attributes?["INSTREAM-ID"], inStream.contains("SERVICE") {
            if let error = evaluateTag(requierdVersion: 7) {
                onError(error, index, tag)
            }
        }
    }
    
    /// The PROGRAM-ID attribute of the EXT-X-STREAM-INF and the EXT-X-I-FRAME-STREAM-INF tags was removed in protocol version 6.
    fileprivate func process(streamInf: Tag, atIndex index: Int) {
        guard let tag = streamInf as? EXTTag else { return }
        if tag.attributes?["PROGRAM-ID"] != nil {
            if let error = evaluateTag(deprecatedVersion: 6) {
                onError(error, index, tag)
            }
        }
    }
    
    /// The PROGRAM-ID attribute of the EXT-X-STREAM-INF and the EXT-X-I-FRAME-STREAM-INF tags was removed in protocol version 6.
    fileprivate func process(iFrameStreamInf: Tag, atIndex index: Int) {
        guard let tag = iFrameStreamInf as? EXTTag else { return }
        if tag.attributes?["PROGRAM-ID"] != nil {
            if let error = evaluateTag(deprecatedVersion: 6) {
                onError(error, index, tag)
            }
        }
    }
    
    /// The EXT-X-ALLOW-CACHE tag was removed in protocol version 7.
    fileprivate func process(allowCache: Tag, atIndex index: Int) {
        if let error = evaluateTag(deprecatedVersion: 7) {
            onError(error, index, allowCache)
        }
    }
}
