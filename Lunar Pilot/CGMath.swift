//
//  CGMath.swift
//  Lunar Pilot 2.0
//
//  Created by Austin Guevara on 6/27/23.
//

import SpriteKit

class CGMath {
    
    func DegreesToRadians (value: CGFloat) -> CGFloat {
        return value * CGFloat(Double.pi) / 180.0
    }
    
    func RadiansToDegrees (value: CGFloat) -> CGFloat {
        return value * 180.0 / CGFloat(Double.pi)
    }
    
    func CGVectorDifference(between vector1: CGVector, and vector2: CGVector) -> CGVector {
        return CGVector(dx: vector1.dx - vector2.dx, dy: vector1.dy - vector2.dy)
    }
    
    func CGVectorAbsolute(for vector: CGVector) -> CGVector {
        let x = abs(vector.dx)
        let y = abs(vector.dy)
        return CGVector(dx: x, dy: y)
    }
    
    func CGRandomBetweenNumbers(from firstNum: CGFloat, to secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func createThrustVector(r: CGFloat, sprite: SKSpriteNode) -> CGVector {
        
        let c: CGFloat = CGMath().DegreesToRadians(value: 90) // 90 deg -> rad
        
        // Create a vector away from bottom of sprite
        let vectorDx: CGFloat = r * cos((sprite.zRotation + c))
        let vectorDy: CGFloat = r * sin((sprite.zRotation + c))
        
        // Return the vector
        return CGVector(dx: vectorDx, dy: vectorDy)
    }
    
}

