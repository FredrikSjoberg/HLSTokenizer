//
//  hlstokenizer
//
//  Created by Fredrik Sjöberg on 2018-10-21.
//  Copyright (c) 2018 Fredrik Sjöberg. All rights reserved.
//  License - MIT, see LICENSE
//

import Foundation
import HLSTokenizerKit

let rawString = """
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-ERROR:"Test"
#EXT-X-ERROR:=ABC
#EXT-X-ERROR:ABC=
#EXT-X-ERROR:,CDE
#EXT-X-ERROR:CDE,
#EXT-X-ERROR:CDE=FGH,
#EXT-X-ERROR:VER"http"

# AUDIO groups
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-aacl-96",NAME="English",LANGUAGE="en",AUTOSELECT=YES,DEFAULT=YES,CHANNELS="2",URI="test-audio101_eng=96000.m3u8?vbegin=1538555580"

# variants
#EXT-X-STREAM-INF:BANDWIDTH=401000,AVERAGE-BANDWIDTH=365000,CODECS="mp4a.40.2,avc1.4D400D",RESOLUTION=384x216,AUDIO="audio-aacl-96",CLOSED-CAPTIONS=NONE
test-video=252000.m3u8?vbegin=1538555580
#EXT-X-STREAM-INF:BANDWIDTH=616000,AVERAGE-BANDWIDTH=560000,CODECS="mp4a.40.2,avc1.4D4015",RESOLUTION=512x288,AUDIO="audio-aacl-96",CLOSED-CAPTIONS=NONE
test-video=436000.m3u8?vbegin=1538555580
#EXT-X-STREAM-INF:BANDWIDTH=1040000,AVERAGE-BANDWIDTH=945000,CODECS="mp4a.40.2,avc1.4D401E",RESOLUTION=640x360,AUDIO="audio-aacl-96",CLOSED-CAPTIONS=NONE
test-video=800000.m3u8?vbegin=1538555580
#EXT-X-STREAM-INF:BANDWIDTH=1740000,AVERAGE-BANDWIDTH=1581000,CODECS="mp4a.40.2,avc1.4D401E",RESOLUTION=768x432,AUDIO="audio-aacl-96",CLOSED-CAPTIONS=NONE
test-video=1400000.m3u8?vbegin=1538555580
#EXT-X-STREAM-INF:BANDWIDTH=2906000,AVERAGE-BANDWIDTH=2641000,CODECS="mp4a.40.2,avc1.4D401F",RESOLUTION=1024x576,AUDIO="audio-aacl-96",CLOSED-CAPTIONS=NONE
test-video=2400000.m3u8?vbegin=1538555580
#EXT-X-STREAM-INF:BANDWIDTH=5238000,AVERAGE-BANDWIDTH=4761000,CODECS="mp4a.40.2,avc1.4D4028",RESOLUTION=1280x720,AUDIO="audio-aacl-96",CLOSED-CAPTIONS=NONE
test-video=4400000.m3u8?vbegin=1538555580

# variants
#EXT-X-STREAM-INF:BANDWIDTH=107000,AVERAGE-BANDWIDTH=97000,CODECS="mp4a.40.2",AUDIO="audio-aacl-96"
test-audio101_eng=96000.m3u8?vbegin=1538555580

# keyframes
#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=37000,CODECS="avc1.4D400D",RESOLUTION=384x216,URI="keyframes/test-video=252000.m3u8?vbegin=1538555580"
#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=64000,CODECS="avc1.4D4015",RESOLUTION=512x288,URI="keyframes/test-video=436000.m3u8?vbegin=1538555580"
#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=117000,CODECS="avc1.4D401E",RESOLUTION=640x360,URI="keyframes/test-video=800000.m3u8?vbegin=1538555580"
#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=205000,CODECS="avc1.4D401E",RESOLUTION=768x432,URI="keyframes/test-video=1400000.m3u8?vbegin=1538555580"
#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=350000,CODECS="avc1.4D401F",RESOLUTION=1024x576,URI="keyframes/test-video=2400000.m3u8?vbegin=1538555580"
#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=642000,CODECS="avc1.4D4028",RESOLUTION=1280x720,URI="keyframes/test-video=4400000.m3u8?vbegin=1538555580"
"""

let errorString = """
#EXTINF:
#EXT-X-VERSION:"Test"
#EXT-X-VERSION:=ABC
#EXT-X-VERSION:ABC=
#EXT-X-VERSION:,CDE
#EXT-X-VERSION:CDE,
#EXT-X-VERSION:CDE=FGH,
#EXT-X-VERSION:CDE=FGH,IKJ=HJG
#EXT-X-VERSION:VER"http"
#EXT-X-MEDIA-SEQUENCE:266886250
#EXT-X-VERSION:VER="TEST"
"""

/// AttributeList
///
/// AttributeName=AttributeValue
///
/// AttributeName
/// can contain:
/// * [A..Z], [0..9] or '-'
///
/// AttributeValue
/// can be:
/// * Decimal-Integer
///     * unquoted
///     * [0..9]
///     * range [0, 2^64-1] (ie 18446744073709551615)
///     * may be [1, 20] characters long
///
/// * Hexadecimal-Sequence
///     * unquoted
///     * [0..9] and [A..F]
///     * prefixed with 0x or 0X.
///
/// * Decimal-Floating-Point
///     * unqouted
///     * [0..9] and '.'
///     * non-negative (ie NOT '-')
///
/// * Signed-Decimal-Floating-Point
///     * unqouted
///     * [0..9], '.' and '-'
///
/// * Quoted-String
///     * string of characters enclosed by double-quotes (ie 0x22).
///     * NOT allowed charactes: line feed (0xA), carriage return (0xD), or double quote (0x22)
///     * SHOULD be comparable by byte-wise comparison, (case sensitive)
///
/// * Enumerated-String
///     * unquoted
///     * set of characters
///     * NOT double-quotes ("), commas (,), or whitespace
///
/// * Decimal-Resolution
///     * two decimal-integers separated by "x".

//guard let data = rawString.data(using: .utf8) else {
//    print("Failed to generate HLS manifest data")
//    exit(1)
//}
//
//let tokenizer = Tokenizer(tagRules: [EXTTagRule()])
//tokenizer.process(data: data, details: .complete) {
//    print($0)
//}

let usage = """
Usage:

hlstokenizer http://www.example.com/manifest.m3u8
downloads and tokenizes the playlist at the specified url

hlstokenizer path/to/manifest.m3u8
tokenizes the playlist found at the path relative to the current directory

--h | help
--v | version

"""

guard CommandLine.arguments.count > 1 else {
    print("Invalid arguments.\n")
    print(usage)
    exit(EXIT_FAILURE)
}

let cmdArgs = CommandLine.arguments
let dispatchGroup = DispatchGroup()

func resolve(args: [String]) {
    dispatchGroup.enter()
    let path = args[1]
    
    if let url = URL(string: path) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                let tokenizer = Tokenizer(tagRules: [EXTTagRule()])
                tokenizer.process(data: data, details: .complete) {
                    print($0)
                }
            }
            if let error = error {
                print(error)
            }
            dispatchGroup.leave()
        }
        task.resume()
    }
}

resolve(args: cmdArgs)

dispatchGroup.notify(queue: DispatchQueue.main) {
    exit(EXIT_SUCCESS)
}
dispatchMain()
