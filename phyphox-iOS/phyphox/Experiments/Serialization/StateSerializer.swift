//
//  SimpleStateSerializer.swift
//  phyphox
//
//  Created by Sebastian Kuhlen on 26.05.17.
//  Copyright © 2017 RWTH Aachen. All rights reserved.
//

import Foundation

protocol DataEncodable {
    func encode() -> Data
}

protocol DataDecodable {
    init?(data: Data)
}

typealias DataCodable = DataEncodable & DataDecodable

extension Double: DataCodable {
    func encode() -> Data {
        if CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) {
            var value = self
            return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
        }
        else {
            var littleEndianBitPattern = bitPattern.littleEndian
            return Data(buffer: UnsafeBufferPointer(start: &littleEndianBitPattern, count: 1))
        }
    }

    init?(data: Data) {
        if CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) {
            guard data.count == MemoryLayout<Double>.size else { return nil }

            let value: Double = data.withUnsafeBytes({ $0.pointee })

            self.init(value)
        }
        else {
            let littleEndianBitPattern = UInt64(littleEndian: data.withUnsafeBytes { (pointer: UnsafePointer<UInt64>) -> UInt64 in
                return pointer.pointee
            })

            self.init(bitPattern: littleEndianBitPattern)
        }
    }
}

extension Sequence where Iterator.Element: DataCodable {
    func enumerateDataEncodedElements(using body: (_ data: Data) -> Void) {
        forEach { body($0.encode()) }
    }
}

extension Experiment {
    func saveState(to url: URL, with title: String) throws -> URL {
        guard let sanitizedTitle = title.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "\"\\/?<>:*|").inverted) else {
            throw FileError.genericError
        }

        let stateFolderURL = url.appendingPathComponent(sanitizedTitle).appendingPathExtension(experimentStateFileExtension)

        let fileManager = FileManager.default

        guard !fileManager.fileExists(atPath: stateFolderURL.path) else {
            throw FileError.genericError
        }

        try fileManager.createDirectory(at: stateFolderURL, withIntermediateDirectories: false, attributes: nil)

        let experimentURL = stateFolderURL.appendingPathComponent(experimentStateExperimentFileName).appendingPathExtension(experimentFileExtension)

        guard let source = source else {
            throw FileError.genericError
        }

        try fileManager.copyItem(at: source, to: experimentURL)

        try buffers.forEach { name, buffer in
            let bufferURL = stateFolderURL.appendingPathComponent(name).appendingPathExtension(bufferContentsFileExtension)
            try buffer.writeState(to: bufferURL)
        }

        return stateFolderURL
    }
}
