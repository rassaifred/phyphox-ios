//
//  DataBuffer.swift
//  phyphox
//
//  Created by Jonas Gessner on 05.12.15.
//  Copyright © 2015 Jonas Gessner. All rights reserved.
//  By Order of RWTH Aachen.
//

import Foundation
import Dispatch

protocol DataBufferObserver: class {
    func dataBufferUpdated(_ buffer: DataBuffer)
}

private typealias ObserverCapture = () -> DataBufferObserver?

private func weakObserverCapture(_ object: DataBufferObserver) -> ObserverCapture {
    return { [weak object] in
        return object
    }
}

/**
 Data buffer used for raw or processed data from sensors.
 */
final class DataBuffer {
    enum StorageType {
        case memory(size: Int)
        case hybrid(memorySize: Int, persistentStorageLocation: URL)
    }

    let name: String
    private(set) var size: Int {
        didSet {
            syncWrite {
                let effectiveSize = effectiveMemorySize

                if queue.count > effectiveSize {
                    removeFirst(queue.count - effectiveSize)
                }
            }
        }
    }

    private var effectiveMemorySize: Int {
        switch storageType {
        case .memory(size: let size):
            if size == 0 {
                return .max
            }
            else {
                return size
            }
        case .hybrid(memorySize: let memorySize, persistentStorageLocation: _):
            return memorySize
        }
    }

    var attachedToTextField = false

    var hashValue: Int {
        return name.hash
    }

    private let storageType: StorageType

    private var stateToken: UUID?

    private var observerCaptures: [ObserverCapture] = []

    /**
     Notifications are sent in order, first registered, first notified.
     */
    func addObserver(_ observer: DataBufferObserver) {
        let alreadyRegistered = observerCaptures.contains(where: { capture in
            return capture() === observer
        })

        if !alreadyRegistered {
            let capture = weakObserverCapture(observer)
            observerCaptures.append(capture)
        }
    }
    //
    //    func removeObserver(_ observer: DataBufferObserver) {
    //        observerCaptures.filter {
    //            let object = $0()
    //
    //            return $0 != nil && $0 != observer
    //        }
    //    }

    /**
     A state token represents a state of the data contained in the buffer. Whenever the data in the buffer changes the current state token gets invalidated.
     */
    func getStateToken() -> UUID? {
        if stateToken == nil {
            stateToken = UUID()
        }

        return stateToken
    }

    func stateTokenIsValid(_ token: UUID?) -> Bool {
        return token != nil && stateToken != nil && stateToken == token
    }

    private func bufferMutated() {
        stateToken = nil
    }

    var staticBuffer: Bool = false
    var written: Bool = false

    var count: Int {
        return Swift.min(queue.count, effectiveMemorySize)
    }

    private let queueLock = DispatchQueue(label: "de.j-gessner.queue.lock", qos: .default, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)

    private var queue: Queue<Double>

    init(name: String, storage: StorageType) {
        self.name = name
        self.storageType = storage

        switch storage {
        case .memory(size: let size):
            self.size = size
        case .hybrid(memorySize: _, persistentStorageLocation: _):
            self.size = 0
        }

        queue = Queue<Double>(capacity: size)
    }

    private var persistentStorageFileHandle: FileHandle?

    private var isOpen = false

    /**
     Opening a buffer starts notifying observers. In case of a hybrid buffer the file handle for writing data to the persistent storage is opened and the current contents of the buffer are written to the persistent storage.
     */
    func open() {
        guard !isOpen else { return }

        isOpen = true

        switch storageType {
        case .hybrid(memorySize: _, persistentStorageLocation: let url):
            if !FileManager.default.fileExists(atPath: url.path) {
                FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
            }

            let handle = try? FileHandle(forWritingTo: url)
            handle?.truncateFile(atOffset: 0)

            persistentStorageFileHandle = handle
        case .memory(size: _):
            break
        }

        // Write current contents
        if let handle = persistentStorageFileHandle {
            enumerateDataEncodedElements { data in
                handle.write(data)
            }
        }
    }

    /**
     Closing a buffer stops notifying observers, closes the persistent storage file handle in case of a hybrid buffer and deletes the persistent storage file.
     */
    func close() {
        guard isOpen else { return }

        isOpen = false

        switch storageType {
        case .hybrid(memorySize: _, persistentStorageLocation: let url):
            persistentStorageFileHandle?.synchronizeFile()
            persistentStorageFileHandle?.closeFile()
            persistentStorageFileHandle = nil

            try? FileManager.default.removeItem(at: url)
        case .memory(size: _):
            break
        }
    }

    private var hybrid: Bool {
        switch storageType {
        case .memory(size: _):
            return false
        case .hybrid(memorySize: _, persistentStorageLocation: _):
            return true
        }
    }

    private func sendUpdateNotification() {
        guard isOpen else { return }

        for observer in observerCaptures {
            mainThread {
                observer()?.dataBufferUpdated(self)
            }
        }
    }

    private func syncWrite(_ body: () throws -> Void) rethrows {
        try queueLock.sync(flags: .barrier, execute: body)
    }

    private func syncRead<T>(_ body: () throws -> T) rethrows -> T {
        return try queueLock.sync(execute: body)
    }

    func objectAtIndex(_ index: Int) -> Double? {
        return syncRead {
            return queue.objectAtIndex(index)
        }
    }

    func removeFirst(_ n: Int) {
        if hybrid {
            print("Truncating a hybrid buffer is not supported.")
        }

        syncWrite {
            queue.removeFirst(n)
        }
    }

    func clear() {
        syncWrite {
            if isOpen, let handle = persistentStorageFileHandle {
                handle.truncateFile(atOffset: 0)
            }

            queue.clear()
            written = false
        }

        bufferMutated()
        sendUpdateNotification()
    }

    func replaceValues(_ values: [Double]) {
        if !staticBuffer || !written {
            var cutValues = values

            syncWrite {
                written = true

                autoreleasepool {
                    if isOpen, let handle = persistentStorageFileHandle {
                        handle.truncateFile(atOffset: 0)
                        values.enumerateDataEncodedElements { data in
                            handle.write(data)
                        }
                    }

                    let effectiveSize = effectiveMemorySize

                    if cutValues.count > effectiveSize {
                        cutValues = Array(cutValues[cutValues.count-effectiveSize..<cutValues.count])
                    }

                    queue.replaceValues(cutValues)
                }
            }

            bufferMutated()
            sendUpdateNotification()
        }
    }

    func append(_ value: Double?) {
        if (!staticBuffer || !written), let value = value {
            syncWrite {
                written = true

                if isOpen, let handle = persistentStorageFileHandle {
                    handle.write(value.encode())
                }

                self.queue.enqueue(value)

                if queue.count > effectiveMemorySize {
                    _ = queue.dequeue()
                }
            }

            bufferMutated()
            sendUpdateNotification()
        }
    }

    func appendFromArray(_ values: [Double]) {
        guard !values.isEmpty else { return }

        if !staticBuffer || !written {
            syncWrite {
                written = true

                autoreleasepool {
                    if isOpen, let handle = persistentStorageFileHandle {
                        values.enumerateDataEncodedElements { data in
                            handle.write(data)
                        }
                    }

                    let sizeAfterAppend = count + values.count

                    let cutSize = sizeAfterAppend - effectiveMemorySize
                    let shouldCut = cutSize > 0 && sizeAfterAppend > 0

                    let cutAfterAppend = cutSize > count

                    if shouldCut && !cutAfterAppend {
                        queue.removeFirst(cutSize)
                    }

                    queue.enqueue(values)

                    if shouldCut && cutAfterAppend {
                        queue.removeFirst(cutSize)
                    }
                }
            }

            bufferMutated()
            sendUpdateNotification()
        }
    }

    func toArray() -> [Double] {
        return syncRead { return queue.toArray() }
    }
}

extension DataBuffer: Sequence {
    func makeIterator() -> IndexingIterator<[Double]> {
        return queue.makeIterator()
    }

    var last: Double? {
        return syncRead { queue.last }
    }

    var first: Double? {
        return syncRead { queue.first }
    }

    subscript(index: Int) -> Double {
        return syncRead { queue[index] }
    }
}

extension DataBuffer: Collection {
    func index(after i: Int) -> Int {
        return i + 1
    }

    var startIndex: Int {
        return 0
    }

    var endIndex: Int {
        return count
    }
}

extension DataBuffer: CustomStringConvertible {
    var description: String {
        get {
            return "<\(type(of: self)): \(Unmanaged.passUnretained(self).toOpaque()): \(queue.toArray())>"
        }
    }
}

//extension DataBuffer: Equatable {
//    static func ==(lhs: DataBuffer, rhs: DataBuffer) -> Bool {
//        return lhs.name == rhs.name && lhs.size == rhs.size && fir lhs.toArray() == rhs.toArray()
//    }
//}
