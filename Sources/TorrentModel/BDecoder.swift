//
//  BDecoder.swift
//  
//
//  Created by Wynn Zhang on 6/25/23.
//

import Foundation

public class BDecoder {
    private var index = 0
    
    public init() {}
    
    public func decode(data: Data) throws -> Bencode {
        index = data.startIndex
        return try decodeObject(data: data)
    }
    
    public func decodeDictionaryKeyRawValue(data: Data) throws -> [String: Data] {
        index = data.startIndex + 1
        
        var result = [String: Data]()
        
        while (index <= data.endIndex) && data[index] != BDelimiter.end.ascii {
            guard case let .string(keyData) = try decodeString(data: data) else {
                throw BencodeError.unexpectedBencode
            }
            
            guard let key = try? keyData.toString() else {
                throw BencodeError.unexpectData
            }
            
            let startIndex = index
            let _ = try decodeObject(data: data)
            let value = data[startIndex..<index]
            
            result[key] = value
        }
        
        return result
    }
    
    private func decodeObject(data: Data) throws -> Bencode {
        guard index <= data.endIndex else {
            throw BencodeError.indexOutOfBounds
        }
        
        switch data[index] {
        case BDelimiter.num_zero.ascii...BDelimiter.num_nine.ascii:
            return try decodeString(data: data)
        case BDelimiter.list.ascii:
            return try decodeList(data: data)
        case BDelimiter.dict.ascii:
            return try decodeDictionary(data: data)
        case BDelimiter.integer.ascii:
            return try decodeInteger(data: data)
        default:
            throw BencodeError.unexpectedDelimiter(data[index])
        }
    }
    
    private func decodeInteger(data: Data) throws -> Bencode {
        index += 1
        
        guard let endIndex = data[index...].firstIndex(of: BDelimiter.end.ascii) else {
            throw BencodeError.indexOutOfBounds
        }
        let numberString = try data[index..<endIndex].toString()
        guard let number = Int(numberString) else {
            throw BencodeError.unexpectedIntegerString(numberString)
        }
        
        index = endIndex + 1
        return .int(number)
    }
    
    private func decodeString(data: Data) throws -> Bencode {
        guard let colonIndex = data[index...].firstIndex(of: BDelimiter.colon.ascii) else {
            throw BencodeError.indexOutOfBounds
        }
        let lengthString = try data[index..<colonIndex].toString()
        guard let length = Int(lengthString) else {
            throw BencodeError.unexpectedIntegerString(lengthString)
        }
        guard colonIndex+length <= data.endIndex else {
            throw BencodeError.indexOutOfBounds
        }
        let stringData = data[colonIndex+1..<colonIndex+length+1]
        
        index = colonIndex+length+1
        return .string(stringData)
    }
    
    private func decodeList(data: Data) throws -> Bencode {
        var result = [Bencode]()
        index += 1
        
        while index < data.endIndex {
            if (data[index] == BDelimiter.end.ascii) {
                break
            }
            
            let object = try decodeObject(data: data)
            result.append(object)
        }
        
        index += 1
        return .list(result)
    }
    
    private func decodeDictionary(data: Data) throws -> Bencode {
        var result = [String: Bencode]()
        index += 1
        
        while index < data.endIndex {
            if (data[index] == BDelimiter.end.ascii) {
                break
            }
            
            let key = try decodeString(data: data)
            let value = try decodeObject(data: data)
            
            guard case let .string(keyData) = key else {
                throw BencodeError.unexpectedBencode
            }
            guard let keyString = (try? keyData.toString()) else {
                throw BencodeError.unexpectData
            }
            result[keyString] = value
        }
        
        index += 1
        return .dict(result)
    }
}
