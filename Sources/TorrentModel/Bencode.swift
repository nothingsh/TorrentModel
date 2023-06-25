//
//  Bencode.swift
//  
//
//  Created by Wynn Zhang on 6/25/23.
//

import Foundation

/// errors that occur during bencode parsing
public enum BencodeError: Error {
    /// data can't be processed, mostly because of decoding format uncompatible
    case unexpectData
    /// string can't be processed, mostly because of encoding format uncompatible
    case unexpectString
    /// access array out of bounds or can't find the target in valid range
    case indexOutOfBounds
    /// wrong bencode string delimiter
    case unexpectedDelimiter(UInt8)
    /// can't convert the string to integer
    case unexpectedIntegerString(String)
    /// wrong bencode, like a bencode dictionary's key is not a bencode string
    case unexpectedBencode
}

enum Bencode {
    case int(Int)
    case string(Data)
    case list([Bencode])
    case dict([String : Bencode])
    
    static let defaultStringEncoding = String.Encoding.ascii
}

extension Bencode: CustomStringConvertible {
    var description: String {
        switch self {
        case .int(let int): return String(int)
        case .string(let data): return (try? data.toString()) ?? "data can't be decoded"
        case .list(let array): return "[" + array.map { $0.description }.joined(separator: " ") + "]"
        case .dict(let dictionary):
            return "{\n" + dictionary.map { $0.key.description + ":" + $0.value.description }.joined(separator: "\n") + "}\n"
        }
    }
}

enum BDelimiter: String {
    case integer = "i"
    case list = "l"
    case dict = "d"
    case end = "e"
    case num_zero = "0"
    case num_nine = "9"
    case colon = ":"
    
    var ascii: UInt8 {
        return (try! self.rawValue.toData()).first!
    }
}
