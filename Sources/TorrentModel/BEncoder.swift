//
//  BEncoder.swift
//  
//
//  Created by Wynn Zhang on 6/25/23.
//

import Foundation

public class BEncoder {
    public init() {}
    
    public func encode(bencode: Bencode) throws -> Data {
        return try encodeObject(bencode: bencode)
    }
    
    private func encodeObject(bencode: Bencode) throws -> Data {
        switch bencode {
        case .int(let integer): return try encodeInteger(integer: integer)
        case .string(let stringData): return try encodeString(stringData: stringData)
        case .list(let array): return try encodeList(array: array)
        case .dict(let dictionary): return try encodeDictionary(dict: dictionary)
        }
    }
    
    private func encodeInteger(integer: Int) throws -> Data {
        return try (BDelimiter.integer.rawValue + "\(integer)" + BDelimiter.end.rawValue).toData()
    }
    
    private func encodeString(stringData: Data) throws -> Data {
        return try "\(stringData.count):".toData() + stringData
    }
    
    private func encodeList(array: [Bencode]) throws -> Data {
        var data = try BDelimiter.list.rawValue.toData()
        for item in array {
            data += try encodeObject(bencode: item)
        }
        return data + (try BDelimiter.end.rawValue.toData())
    }
    
    private func encodeDictionary(dict: [String : Bencode]) throws -> Data {
        var data = try BDelimiter.dict.rawValue.toData()
        for (key, value) in dict {
            let stringData = try key.toData()
            data += try encodeString(stringData: stringData)
            data += try encodeObject(bencode: value)
        }
        return data + (try BDelimiter.end.rawValue.toData())
    }
}
