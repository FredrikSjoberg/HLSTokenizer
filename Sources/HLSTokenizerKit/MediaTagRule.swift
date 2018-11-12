//
//  MediaTagRule.swift
//  HLSTokenizerKit
//
//  Created by Fredrik Sjöberg on 2018-11-11.
//

import Foundation

public class MediaTagRule: PlaylistTagRule {
    
    
    public var onError: (Error, Int, Tag) -> Void = { _,_,_ in }
    public enum Error {
        case missingList
        case unsupportedType
        case missing(attribute: String)
        case unexpected(attribute: String)
        case unexpected(value: String, forAttribute: String)
        case nonunique(value: String, forAttribute: String)
    }
    
    public var onWarning: (Warning, Int, Tag) -> Void = { _,_,_ in }
    public enum Warning {
        case missing(attribute: String)
    }
    
    fileprivate var processedTags: [EXTTag] = []
    public func process(tokenClassification: TokenClassification, atIndex index: Int) {
        guard case let TokenClassification.tag(data: rawTag) = tokenClassification, let tag = rawTag as? EXTTag else { return }
        
        guard tag.type == "EXT-X-MEDIA" else {
            return
        }
        
        guard let attributes = tag.attributes else {
            onError(.missingList, index, tag)
            return
        }
        
        /// TYPE
        ///
        /// The value is an enumerated-string; valid strings are AUDIO, VIDEO, SUBTITLES and CLOSED-CAPTIONS.  This attribute is REQUIRED.
        guard let type = attributes["TYPE"] else {
            onError(.missing(attribute: "TYPE"), index, tag)
            return
        }
        
        
        verifyBasics(tag: tag, type: type, attributes: attributes, atIndex: index)
        
        /// DEFAULT
        ///
        /// The value is an enumerated-string; valid strings are YES and NO.
        ///
        /// If the value is YES, then the client SHOULD play this Rendition of the content in the absence of information from the user indicating a different choice.
        ///
        /// This attribute is OPTIONAL.
        if let `default` = attributes["DEFAULT"] {
            if !["YES", "NO"].contains(`default`) {
                onError(.unexpected(value: `default`, forAttribute: "DEFAULT"), index, tag)
            }
            else {
                /// AUTOSELECT
                ///
                /// If the AUTOSELECT attribute is present, its value MUST be YES if the value of the DEFAULT attribute is YES.
                if let autoselect = attributes["AUTOSELECT"], `default` == "YES", autoselect != "YES" {
                    onError(.unexpected(value: autoselect, forAttribute: "AUTOSELECT"), index, tag)
                }
            }
        }
        
        
        
        
        
        
        
        
        
        /*
         
         
         TODO:!!!
         
         
        Each EXT-X-MEDIA tag with an AUTOSELECT=YES attribute SHOULD have
        a combination of LANGUAGE [RFC5646], ASSOC-LANGUAGE, FORCED, and
        
        
        
        Pantos & May            Expires November 23, 2017              [Page 27]
        
        Internet-Draft             HTTP Live Streaming                  May 2017
        
        
        CHARACTERISTICS attributes that is distinct from those of other
        AUTOSELECT=YES members of its Group.
        
        A Playlist MAY contain multiple Groups of the same TYPE in order to
        provide multiple encodings of that media type.  If it does so, each
        Group of the same TYPE MUST have the same set of members, and each
        corresponding member MUST have identical attributes with the
        exception of the URI and CHANNELS attributes.
        
        Each member in a Group of Renditions MAY have a different sample
        format.  For example, an English rendition can be encoded with AC-3
        5.1 while a Spanish rendition is encoded with AAC stereo.  However,
        any EXT-X-STREAM-INF (Section 4.3.4.2) tag or EXT-X-I-FRAME-STREAM-
        INF (Section 4.3.4.3) tag which references such a Group MUST have a
        CODECS attribute that lists every sample format present in any
        Rendition in the Group, or client playback failures can occur.  In
        the example above, the CODECS attribute would include
        "ac-3,mp4a.40.2".
        */
        
        
        
        
        
        
        
        
        
        switch type {
        case "AUDIO": process(audio: tag, attributes: attributes, atIndex: index)
        case "VIDEO": process(video: tag, attributes: attributes, atIndex: index)
        case "SUBTITLES": process(subtitles: tag, attributes: attributes, atIndex: index)
        case "CLOSED-CAPTIONS": process(closedCaptions: tag, attributes: attributes, atIndex: index)
        default: onError(.unsupportedType, index, tag)
        }
        
        processedTags.append(tag)
    }
}


extension MediaTagRule {
    fileprivate func verifyBasics(tag: EXTTag, type: String, attributes: [String: String], atIndex index: Int) {
        
        /// GROUP-ID
        ///
        /// The value is a quoted-string which specifies the group to which the Rendition belongs. This attribute is REQUIRED.
        if attributes["GROUP-ID"] == nil {
            onError(.missing(attribute: "GROUP-ID"), index, tag)
        }
        
        /// A set of one or more EXT-X-MEDIA tags with the same GROUP-ID value and the same TYPE value defines a Group of Renditions
        let renditionGroup = processedTags.filter {
            if let ot = $0.attributes?["TYPE"], let ogid = $0.attributes?["GROUP-ID"], let groupId = attributes["GROUP-ID"] {
                return ot == type && ogid == groupId
            }
            return false
        }
        
        /// NAME
        ///
        /// The value is a quoted-string containing a human-readable description of the Rendition. This attribute is REQUIRED.
        if let name = attributes["NAME"] {
            /// All EXT-X-MEDIA tags in the same Group MUST have different NAME attributes.
            let hasUniqueName = renditionGroup.filter{
                if let on = $0.attributes?["NAME"] {
                    return on == name
                }
                return false
            }.isEmpty
            if !hasUniqueName {
                onError(.nonunique(value: name, forAttribute: "NAME"), index, tag)
            }
            
            /// A Group MUST NOT have more than one member with a DEFAULT attribute of YES
            if let isDefault = attributes["DEFAULT"], isDefault == "YES" {
                let hasActiveDefault = renditionGroup.filter {
                    if let on = $0.attributes?["DEFAULT"] {
                        return on == "YES"
                    }
                    return false
                }.isEmpty
                if hasActiveDefault {
                    onError(.nonunique(value: isDefault, forAttribute: "DEFAULT"), index, tag)
                }
            }
        }
        else {
            onError(.missing(attribute: "NAME"), index, tag)
        }
    }
    
}

extension MediaTagRule {
    fileprivate func process(audio tag: EXTTag, attributes: [String: String], atIndex index: Int) {
        /// FORCED
        ///
        /// The value is an enumerated-string; valid strings are YES and NO. The FORCED attribute MUST NOT be present unless the TYPE is SUBTITLES.
        if attributes["FORCED"] != nil {
            onError(.unexpected(attribute: "FORCED"), index, tag)
        }
        
        /// INSTREAM-ID
        ///
        /// This attribute is REQUIRED if the TYPE attribute is CLOSED-CAPTIONS, for all other TYPE values, the INSTREAM-ID MUST NOT be specified.
        if attributes["INSTREAM-ID"] != nil {
            onError(.unexpected(attribute: "INSTREAM-ID"), index, tag)
        }
        
        /// CHANNELS
        ///
        /// All audio EXT-X-MEDIA tags SHOULD have a CHANNELS attribute.
        ///
        /// If a Master Playlist contains two renditions encoded with the same codec but a different number of channels, then the CHANNELS attribute is REQUIRED; otherwise it is OPTIONAL.
        if attributes["CHANNELS"] == nil {
            onWarning(.missing(attribute: "CHANNELS"), index, tag)
        }
        else {
            
        }
    }
    
    fileprivate func process(video tag: EXTTag, attributes: [String: String], atIndex index: Int) {
        /// FORCED
        ///
        /// The value is an enumerated-string; valid strings are YES and NO. The FORCED attribute MUST NOT be present unless the TYPE is SUBTITLES.
        if attributes["FORCED"] != nil {
            onError(.unexpected(attribute: "FORCED"), index, tag)
        }
        
        /// INSTREAM-ID
        ///
        /// This attribute is REQUIRED if the TYPE attribute is CLOSED-CAPTIONS, for all other TYPE values, the INSTREAM-ID MUST NOT be specified.
        if attributes["INSTREAM-ID"] != nil {
            onError(.unexpected(attribute: "INSTREAM-ID"), index, tag)
        }
    }
    
    fileprivate func process(subtitles tag: EXTTag, attributes: [String: String], atIndex index: Int) {
        /// The URI attribute of the EXT-X-MEDIA tag is REQUIRED if the media type is SUBTITLES
        if attributes["URI"] == nil {
            onError(.missing(attribute: "URI"), index, tag)
        }
        
        /// INSTREAM-ID
        ///
        /// This attribute is REQUIRED if the TYPE attribute is CLOSED-CAPTIONS, for all other TYPE values, the INSTREAM-ID MUST NOT be specified.
        if attributes["INSTREAM-ID"] != nil {
            onError(.unexpected(attribute: "INSTREAM-ID"), index, tag)
        }
    }
    
    fileprivate func process(closedCaptions tag: EXTTag, attributes: [String: String], atIndex index: Int) {
        /// The URI attribute of the EXT-X-MEDIA tag MUST NOT be included if the media type is CLOSED-CAPTIONS.
        if attributes["URI"] != nil {
            onError(.unexpected(attribute: "URI"), index, tag)
        }
        
        /// FORCED
        ///
        /// The value is an enumerated-string; valid strings are YES and NO. The FORCED attribute MUST NOT be present unless the TYPE is SUBTITLES.
        if attributes["FORCED"] != nil {
            onError(.unexpected(attribute: "FORCED"), index, tag)
        }
        
        /// INSTREAM-ID
        ///
        /// The value is a quoted-string that specifies a Rendition within the segments in the Media Playlist.  This attribute is REQUIRED if the TYPE attribute is CLOSED-CAPTIONS, in which case it MUST have one of the values: "CC1", "CC2", "CC3", "CC4", or "SERVICEn" where n MUST be an integer between 1 and 63 (e.g."SERVICE3" or "SERVICE42").
        ///
        /// The values "CC1", "CC2", "CC3", and "CC4" identify a Line 21 Data Services channel [CEA608].  The "SERVICE" values identify a Digital Television Closed Captioning [CEA708] service block number.
        ///
        /// For all other TYPE values, the INSTREAM-ID MUST NOT be specified.
        if let instream = attributes["INSTREAM-ID"] {
            let valid = ["CC1", "CC2", "CC3", "CC4", "SERVICE"].reduce(false){ $0 || instream.hasPrefix($1) }
            if !valid {
                onError(.unexpected(value: instream, forAttribute: "INSTREAM-ID"), index, tag)
        }
        else {
            onError(.missing(attribute: "INSTREAM-ID"), index, tag)
        }
        }
    }
}
