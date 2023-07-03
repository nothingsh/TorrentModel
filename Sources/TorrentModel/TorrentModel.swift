//
//  TorrentModel.swift
//
//
//  Created by Wynn Zhang on 6/25/23.
//

import Foundation

public enum TorrentModelError: Error {
    /// can't find value in dictionary with key
    case valueNotFound
    /// piece data length must be divisible by 20
    case wrongPieceLength
}

public struct TorrentModelInfo: Equatable {
    public let name: String
    public let length: Int?
    public let files: [TorrentModelSubInfo]?
    public let pieceLength: Int
    public let pieces: [Data]
}

public struct TorrentModelSubInfo: Equatable {
    public let path: [String]
    public let length: Int
}

public struct TorrentModel {
    public let announce: String
    public var announceList: [[String]]
    public let creationDate: Date?
    public let comment: String?
    public let createdBy: String?
    public var encoding: String?
    public let info: TorrentModelInfo
    public let infoRawData: Data
    
    // MARK: - encode torrent model to data
    
    public static func encode(model: TorrentModel) throws -> Data {
        let bencode = try encodeToBencode(model: model)
        return try BEncoder().encode(bencode: bencode)
    }
    
    private static func encodeToBencode(model: TorrentModel) throws -> Bencode {
        let name = try model.info.name.toData()
        var infoDict: [String: Bencode] = [
            "name": .string(name),
            "piece length": .int(model.info.pieceLength),
            "pieces": .string(model.info.pieces.reduce(Data(), +))
        ]
        if let length = model.info.length {
            infoDict["length"] = .int(length)
        } else if let files = model.info.files {
            infoDict["files"] = .list(files.map { file in
                var fileDict = [String: Bencode]()
                fileDict["length"] = .int(file.length)
                fileDict["path"] = .list(file.path.compactMap {
                    if let data = try? $0.toData() {
                        return .string(data)
                    } else {
                        return nil
                    }
                })
                return .dict(fileDict)
            })
        }
        
        var torrentDict = [String: Bencode]()
        let announce = try model.announce.toData()
        torrentDict["announce"] = .string(announce)
        torrentDict["info"] = .dict(infoDict)
        if !model.announceList.isEmpty {
            torrentDict["announce-list"] = .list(model.announceList.compactMap { tier in
                .list(tier.compactMap {
                    if let data = try? $0.toData() {
                        return .string(data)
                    } else {
                        return nil
                    }
                })
            })
        }
        if let creationDate = model.creationDate {
            torrentDict["creation date"] = .int(Int(creationDate.timeIntervalSince1970))
        }
        if let comment = try model.comment?.toData() {
            torrentDict["comment"] = .string(comment)
        }
        if let createdBy = try model.createdBy?.toData() {
            torrentDict["created by"] = .string(createdBy)
        }
        if let encoding = try model.encoding?.toData() {
            torrentDict["encoding"] = .string(encoding)
        }
        
        return .dict(torrentDict)
    }
    
    // MARK: - decode data to torrent model
    
    public static func decode(data: Data) throws -> TorrentModel {
        let bencode = try BDecoder().decode(data: data)
        guard case let .dict(bencodeDict) = bencode else {
            throw BencodeError.unexpectedBencode
        }
        
        guard case let .string(announceData) = bencodeDict["announce"] else {
            throw TorrentModelError.valueNotFound
        }
        let announce = try announceData.toString()
        
        var announceList = [[String]]()
        guard case let .list(announce_array) = bencodeDict["announce-list"] else {
            throw TorrentModelError.valueNotFound
        }
        for item_list in announce_array {
            guard case let .list(announce_list) = item_list else {
                throw BencodeError.unexpectedBencode
            }
            var announces = [String]()
            for item in announce_list {
                guard case let .string(announce_item) = item else {
                    throw BencodeError.unexpectedBencode
                }
                let announceString = try announce_item.toString()
                if (!announceString.isEmpty) {
                    announces.append(announceString)
                }
            }
            announceList.append(announces)
        }
        
        var creationDate: Date?
        if case let .int(creation_date) = bencodeDict["creation date"] {
            creationDate = Date(timeIntervalSince1970: TimeInterval(creation_date))
        }
        
        var comment: String?
        if case let .string(commentData) = bencodeDict["comment"] {
            comment = try commentData.toString()
        }
        
        var createdBy: String?
        if case let .string(createdByData) = bencodeDict["created by"] {
            createdBy = try createdByData.toString()
        }
        
        var encoding: String?
        if case let .string(encodingData) = bencodeDict["encoding"] {
            encoding = try encodingData.toString()
        }
        
        guard case let .dict(infoDict) = bencodeDict["info"] else {
            throw TorrentModelError.valueNotFound
        }
        let info = try decodeInfo(dictionary: infoDict)
        
        guard let info_data = try BDecoder().decodeDictionaryKeyRawValue(data: data)["info"] else {
            throw TorrentModelError.valueNotFound
        }
        
        return TorrentModel(announce: announce, announceList: announceList, creationDate: creationDate, comment: comment, createdBy: createdBy, encoding: encoding, info: info, infoRawData: info_data)
    }
    
    private static func decodeInfo(dictionary: [String : Bencode]) throws -> TorrentModelInfo {
        guard case let .string(nameData) = dictionary["name"] else {
            throw TorrentModelError.valueNotFound
        }
        let name = try nameData.toString()
        guard case let .int(pieceLength) = dictionary["piece length"] else {
            throw TorrentModelError.valueNotFound
        }
        guard case let .string(piecesData) = dictionary["pieces"] else {
            throw TorrentModelError.valueNotFound
        }
        let pieces = try decodePiecesData(piecesData: [UInt8](piecesData))
        
        var length: Int?
        if case let .int(full_length) = dictionary["length"] {
            length = full_length
        }
        
        var files: [TorrentModelSubInfo]?
        if case let .list(files_list) = dictionary["files"] {
            files = files_list.compactMap { (try? decodeSubInfo(subInfo: $0) ) }
        }
        
        return TorrentModelInfo(name: name, length: length, files: files, pieceLength: pieceLength, pieces: pieces)
    }
    
    private static func decodePiecesData(piecesData: [UInt8]) throws -> [Data] {
        guard piecesData.count % 20 == 0 else {
            throw TorrentModelError.wrongPieceLength
        }
        
        let count = piecesData.count / 20
        var pieces: [Data] = []
        pieces.reserveCapacity(count)
        
        for i in 0..<count {
            let start = i * 20
            let end = start + 20
            let pieceHash = piecesData[start..<end]
            pieces.append(Data(pieceHash))
        }
        
        return pieces
    }
    
    private static func decodeSubInfo(subInfo: Bencode) throws -> TorrentModelSubInfo {
        guard case let .dict(dictionary) = subInfo else {
            throw BencodeError.unexpectedBencode
        }
        guard case let .int(length) = dictionary["length"] else {
            throw TorrentModelError.valueNotFound
        }
        
        var path = [String]()
        guard case let .list(path_list) = dictionary["path"] else {
            throw TorrentModelError.valueNotFound
        }
        for path_item in path_list {
            guard case let .string(pathData) = path_item else {
                throw BencodeError.unexpectedBencode
            }
            let pathString = try pathData.toString()
            path.append(pathString)
        }
        
        return TorrentModelSubInfo(path: path, length: length)
    }
}
