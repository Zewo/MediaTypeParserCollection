// MediaTypeParserCollection.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@_exported import MediaType
@_exported import InterchangeData

public enum MediaTypeParserCollectionError: ErrorType {
    case NoSuitableParser
    case MediaTypeNotFound
}

public final class MediaTypeParserCollection {
    public var parsers: [(MediaType, InterchangeDataParser)] = []

    public var mediaTypes: [MediaType] {
        return parsers.map({$0.0})
    }

    public init() {}

    public func setPriority(mediaTypes: MediaType...) throws {
        for mediaType in mediaTypes.reverse() {
            try setTopPriority(mediaType)
        }
    }

    public func setTopPriority(mediaType: MediaType) throws {
        for index in 0 ..< parsers.count {
            let tuple = parsers[index]
            if tuple.0 == mediaType {
                parsers.removeAtIndex(index)
                parsers.insert(tuple, atIndex: 0)
                return
            }
        }

        throw MediaTypeParserCollectionError.MediaTypeNotFound
    }

    public func add(mediaType: MediaType, parser: InterchangeDataParser) {
        parsers.append(mediaType, parser)
    }

    public func parsersFor(mediaType: MediaType) -> [(MediaType, InterchangeDataParser)] {
        return parsers.reduce([]) {
            if $1.0.matches(mediaType) {
                return $0 + [($1.0, $1.1)]
            } else {
                return $0
            }
        }
    }

    public func parse(data: Data, mediaType: MediaType) throws -> (MediaType, InterchangeData) {
        var lastError: ErrorType?

        for (mediaType, parser) in parsersFor(mediaType) {
            do {
                return try (mediaType, parser.parse(data))
            } catch {
                lastError = error
                continue
            }
        }

        if let lastError = lastError {
            throw lastError
        } else {
            throw MediaTypeParserCollectionError.NoSuitableParser
        }
    }
}
