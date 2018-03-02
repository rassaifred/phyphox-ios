//
//  ExperimentManager.swift
//  phyphox
//
//  Created by Jonas Gessner on 04.12.15.
//  Copyright © 2015 Jonas Gessner. All rights reserved.
//  By Order of RWTH Aachen.
//

import UIKit

let experimentsBaseURL = Bundle.main.url(forResource: "phyphox-experiments", withExtension: nil)!

let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

let savedExperimentStatesURL = documentsURL.appendingPathComponent("Saved-States")
let customExperimentsURL = documentsURL.appendingPathComponent("Experiments")

let fileExtension = "phyphox"

let ExperimentsReloadedNotification = "ExperimentsReloadedNotification"

enum FileError: Error {
    case genericError
}

final class ExperimentManager {
    let audioEngine = AudioEngine()

    var experimentCollections: [ExperimentCollection] = []
    static let shared = ExperimentManager()

    func deleteExperiment(_ experiment: Experiment) throws {
        guard let source = experiment.source else { return }
        try FileManager.default.removeItem(at: source)
        try loadCustomExperiments()
    }

    private func registerExperiment(_ experiment: Experiment, custom: Bool) {
        experiment.delegate = self

        let category = experiment.localizedCategory

        if let collection = experimentCollections.first(where: { $0.title == category }) {
            let insertIndex = collection.experiments.index(where: { $0.experiment == experiment }) ?? collection.experiments.endIndex

            collection.experiments.insert((experiment, custom), at: insertIndex)
        }
        else {
            let collection = ExperimentCollection(title: category, experiments: [experiment], customExperiments: custom)

            let insertIndex = experimentCollections.index(where: { $0.title > category }) ?? experimentCollections.endIndex

            experimentCollections.insert(collection, at: insertIndex)
        }
    }

    func loadSavedExperiments() throws {
        guard let experiments = try? FileManager.default.contentsOfDirectory(atPath: savedExperimentStatesURL.path) else { return }

        for file in experiments {
            let url = savedExperimentStatesURL.appendingPathComponent(file)

            guard url.pathExtension == experimentStateFileExtension else { continue }

            let experiment = try ExperimentSerialization.readExperimentFromURL(url)

            registerExperiment(experiment, custom: true)
        }

        NotificationCenter.default.post(name: Notification.Name(rawValue: ExperimentsReloadedNotification), object: nil)
    }

    func loadCustomExperiments() throws {
        guard let experiments = try? FileManager.default.contentsOfDirectory(atPath: customExperimentsURL.path) else { return }

        for file in experiments {
            let url = customExperimentsURL.appendingPathComponent(file)

            guard url.pathExtension == fileExtension else { continue }

            let experiment = try ExperimentSerialization.readExperimentFromURL(url)

            registerExperiment(experiment, custom: true)
        }

        NotificationCenter.default.post(name: Notification.Name(rawValue: ExperimentsReloadedNotification), object: nil)
    }

    private func loadExperiments() throws {
        let experiments = try FileManager.default.contentsOfDirectory(atPath: experimentsBaseURL.path)

        for file in experiments {
            let url = experimentsBaseURL.appendingPathComponent(file)

            guard url.pathExtension == fileExtension else { continue }

            let experiment = try ExperimentSerialization.readExperimentFromURL(url)

            registerExperiment(experiment, custom: false)
        }
    }
    
    init() {
        let timestamp = CFAbsoluteTimeGetCurrent()

        do {
            try loadExperiments()
            try loadCustomExperiments()
            try loadSavedExperiments()
        }
        catch {
            print(error)
        }

        #if DEBUG
            print("Load took \(String(format: "%.2f", (CFAbsoluteTimeGetCurrent()-timestamp)*1000)) ms")
        #endif
    }
}

extension ExperimentManager: ExperimentDelegate {
    func experimentWillBecomeActive(_ experiment: Experiment) {
        guard let url = experiment.source else { return }

        experiment.buffers.0?.forEach { name, buffer in
            let bufferURL = url.appendingPathComponent(name).appendingPathExtension("buffer")
            if FileManager.default.fileExists(atPath: bufferURL.path) {
                try? buffer.readState(from: bufferURL)
            }
        }
    }
}