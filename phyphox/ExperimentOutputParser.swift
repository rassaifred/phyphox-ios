//
//  ExperimentOutputParser.swift
//  phyphox
//
//  Created by Jonas Gessner on 15.12.15.
//  Copyright © 2015 RWTH Aachen. All rights reserved.
//

import Foundation

final class ExperimentOutputParser: ExperimentMetadataParser {
    let audio: [NSDictionary]?
    
    required init(_ data: NSDictionary) {
        audio = getElementsWithKey(data, key: "audio") as! [NSDictionary]?
    }
    
    func parse(buffers: [String: DataBuffer]) -> ExperimentOutput? {
        if audio == nil {
            return nil
        }
        
        var audios: [ExperimentAudioOutput] = []
        audios.reserveCapacity(audio!.count)
        
        for audioOut in audio! {
            let attributes = audioOut[XMLDictionaryAttributesKey] as! [String: AnyObject]?
            
            let loop = boolFromXML(attributes, key: "loop", defaultValue: false)
            let sampleRate = intTypeFromXML(attributes, key: "rate", defaultValue: UInt(48000))
            
            let input = getElementsWithKey(audioOut, key: "input")!.first
            
            let bufferName = (input as? String ?? (input as! [String: AnyObject])[XMLDictionaryTextKey] as! String)
            let buffer = buffers[bufferName]!
            
            let out = ExperimentAudioOutput(sampleRate: sampleRate, loop: loop, dataSource: buffer)
            
            audios.append(out)
        }
        
        return ExperimentOutput(audioOutput: audios)
    }
}

