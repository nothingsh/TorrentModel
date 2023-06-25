//
//  Utils.swift
//  
//
//  Created by Wynn Zhang on 6/25/23.
//

import Foundation

extension Data {
    func toString(using encoding: String.Encoding = Bencode.defaultStringEncoding) throws -> String {
        if let data_string = String(bytes: self, encoding: encoding) {
            return data_string
        } else {
            throw BencodeError.unexpectData
        }
    }
}

extension String {
    func toData(using encoding: String.Encoding = Bencode.defaultStringEncoding) throws -> Data {
        if let string_data = self.data(using: encoding) {
            return string_data
        } else {
            throw BencodeError.unexpectString
        }
    }
}
