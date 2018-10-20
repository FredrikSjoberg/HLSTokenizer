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
#EXT-X-MEDIA-SEQUENCE:266886250
"""

guard let data = rawString.data(using: .utf8) else {
    print("Failed to generate HLS manifest data")
    exit(1)
}


data.parseLines{
    print($0)
}
