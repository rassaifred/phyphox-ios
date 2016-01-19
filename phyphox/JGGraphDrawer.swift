//
//  JGGraphDrawer.swift
//  Crono
//
//  Created by Jonas Gessner on 31.03.15.
//  Copyright (c) 2015 Jonas Gessner. All rights reserved.
//

/**
This code is taken from the Crono iOS app (https://itunes.apple.com/app/id980940387). © 2015-2016 Jonas Gessner
*/

import UIKit

protocol JGGraphValueSource {
    subscript(index: Int) -> Double { get }
    var count: Int { get }
    var last: Double? { get }
}

class JGGraphFixedValueSource: JGGraphValueSource {
    let array: [Double]
    
    init(array: [Double]) {
        self.array = array
    }
    
    subscript(index: Int) -> Double {
        return array[index]
    }
    
    var last: Double? {
        get {
            return array.last
        }
    }
    
    var count: Int {
        get {
            return array.count
        }
    }
}

final class JGGraphDrawer {
    //    class func drawImage(xs: [[Double]], ys: [[Double]], minX: Double = 0.0, maxX: Double, minY: Double = 0.0, maxY: Double, size: CGSize, lineWidth: CGFloat = 2.0, color: UIColor) -> UIImage {
    //        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    //
    //        let path = drawPath(xs, ys: ys, minX: minX, maxX: maxX, minY: minY, maxY: maxY, size: size)
    //
    //        path.lineWidth = lineWidth
    //
    //        color.setStroke()
    //
    //        path.stroke()
    //
    //        let img = UIGraphicsGetImageFromCurrentImageContext()
    //
    //        UIGraphicsEndImageContext()
    //
    //        return img
    //    }
    
    class func drawPathToImage(path: UIBezierPath, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        UIColor.blackColor().setStroke()
        path.stroke()
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return img
    }
    
    /*
    class func getPoints(xs: JGGraphValueSource, ys: JGGraphValueSource, minX: Double = 0.0, maxX: Double, logX: Bool = false, minY: Double = 0.0, maxY: Double, logY: Bool = false, count: Int, size: CGSize, reusePath: UIBezierPath? = nil, lastIndex: Int? = nil) -> [CGPoint] {
    var points: [CGPoint] = []
    
    let startIndex = (lastIndex != nil ? lastIndex! : 0)
    
    if startIndex >= count {
    print("Da fuck man")
    return points
    }
    
    var translationRateX = (maxX-minX)/Double(size.width)
    var translationRateY = (maxY-minY)/Double(size.height)
    
    if (!isnormal(translationRateX)) {
    translationRateX = 1.0
    }
    
    if (!isnormal(translationRateY)) {
    translationRateY = 1.0
    }
    
    for idx in startIndex..<count {
    var x = xs[idx]
    var y = ys[idx]
    
    if logX {
    x = log(x)
    }
    
    if logY {
    y = log(y)
    }
    
    //            for i in 0..<x.count {
    let xVal = x-minX//x[i]
    let yVal = y-minY//y[i]-minY
    
    var tX = CGFloat(xVal/translationRateX)
    var tY = CGFloat(yVal/translationRateY)
    
    if (!isnormal(tX)) {
    tX = 0.0
    }
    
    if (!isnormal(tY)) {
    tY = 0.0
    }
    
    let translatedPoint = CGPointMake(tX, size.height-tY)
    
    points.append(translatedPoint)
    //            if (path.empty) {
    //                path.moveToPoint(translatedPoint)
    //            }
    //            else {
    //                path.addLineToPoint(translatedPoint)
    //            }
    //            }
    }
    
    return points
    }
    */
    
    class func drawPath(xs: JGGraphValueSource, ys: JGGraphValueSource, minX: Double = 0.0, maxX: Double, logX: Bool = false, minY: Double = 0.0, maxY: Double, logY: Bool = false, count: Int, size: CGSize, reusePath: UIBezierPath? = nil, start: Int = 0, averaging: Bool = true) -> UIBezierPath {
        let path = (reusePath != nil ? reusePath! : UIBezierPath())
        
        if count == 0 {
            return path
        }
        
        assert(start < count, "Invalid start")
        
        var translationRateX = (maxX-minX)/Double(size.width)
        var translationRateY = (maxY-minY)/Double(size.height)
        
        if (!isnormal(translationRateX)) {
            translationRateX = 1.0
        }
        
        if (!isnormal(translationRateY)) {
            translationRateY = 1.0
        }
        
        var currentAveragingX: Int = 0
        var currentAveragingYSum: CGFloat = 0.0
        var currentXAveragingCount: Int = 0
        var scale = UIScreen.mainScreen().scale
        
        func addPoint(point: CGPoint) {
            if (path.empty) {
                path.moveToPoint(point)
            }
            else {
                path.addLineToPoint(point)
            }
        }
        
        func tryAddingAveragedPoint() {
            if currentXAveragingCount > 0 {
                let averagedPoint = CGPointMake(CGFloat(currentAveragingX)/scale, currentAveragingYSum/CGFloat(currentXAveragingCount))
                
                addPoint(averagedPoint)
            }
        }
        
        for idx in start..<count {
            var x = xs[idx]
            var y = ys[idx]
            
            if logX {
                x = log(x)
            }
            
            if logY {
                y = log(y)
            }
            
            let xVal = x-minX
            let yVal = y-minY
            
            let tX = CGFloat(xVal/translationRateX)
            let tY = CGFloat(yVal/translationRateY)
            
            if !isfinite(tX) || !isfinite(tY) {
                print("Value \(tX) or \(tY) is not finite")
                continue
            }
            
            if averaging {
                let tXInt = Int(round(tX*scale))
                
                if tXInt > currentAveragingX {
                    tryAddingAveragedPoint()
                    
                    currentXAveragingCount = 1
                    currentAveragingX = tXInt
                    currentAveragingYSum = tY
                }
                else {
                    currentXAveragingCount++
                    currentAveragingYSum += tY
                }
            }
            else {
                let translatedPoint = CGPointMake(tX, size.height-tY)
                
                addPoint(translatedPoint)
            }
        }
        
        if averaging {
            tryAddingAveragedPoint()
        }
        
        return path
    }
}
