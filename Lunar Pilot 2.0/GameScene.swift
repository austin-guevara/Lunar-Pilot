//
//  GameScene.swift
//  Lunar Pilot 2.0
//
//  Created by Austin Guevara on 6/27/23.
//

//import AVFoundation
import SpriteKit
import SwiftUI

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    @Binding var shouldResetLevel: Bool
    @Binding var gameIsPaused: Bool
    @Binding var fuelLevel: CGFloat
    @Binding var crashCount: Int
    
    // Used to turn the class into a singleton
    // This is useful if we need to make function calls directly on the class instance
    // However, this doesn’t seem to be working for changing the isPaused state
    // Also, use of singletons isn’t recommended (for a variety of reasons), and we’re already doing @Bindings...
    // lazy var shared = GameScene($shouldResetLevel, gameIsPaused: $gameIsPaused, fuelLevel: $fuelLevel, crashCount: $crashCount)
    
    let gravityForce = -0.2
    let thrustForce = 2.0
    let rotationForce = 5.0 / 1000000
    let fuelCost = 0.25
    
    var isTouchingLeft = false
    var isTouchingRight = false
    var isTouchingBoth = false
    
    var shouldResetCraft = false
    var didLand = false
    var canyonCollide = false
    
    var top: CGFloat!
    var right: CGFloat!
    
    let CraftName = "craft"
    let CraftCategory: UInt32 = 0x1 << 0        // 00000000000000000000000000000001
    let LandingGearCategory: UInt32 = 0x1 << 1  // 00000000000000000000000000000010
    let BorderCategory: UInt32 = 0x1 << 2       // 00000000000000000000000000000100
    let PadCategory: UInt32 = 0x1 << 3          // 00000000000000000000000000001000
    
    var borderLeft: SKShapeNode!
    var borderRight: SKShapeNode!
    var pad: SKSpriteNode!
    
    var craft: SKSpriteNode!
    var landingGearLeft: SKSpriteNode!
    var landingGearRight: SKSpriteNode!
    var fixed: SKPhysicsJointFixed!
    var spring: SKPhysicsJointSpring!
    var slider: SKPhysicsJointSliding!
    
    var thrustNode: SKEmitterNode!
    var thrustApplied = false
    
    var levelLabel: SKLabelNode!
    var levelCount: Int = 1
    
    var touchesArray = [UITouch]()
    
    init(_ shouldResetLevel: Binding<Bool>, gameIsPaused: Binding<Bool>, fuelLevel: Binding<CGFloat>, crashCount: Binding<Int>) {
        _shouldResetLevel = shouldResetLevel
        _gameIsPaused = gameIsPaused
        _fuelLevel = fuelLevel
        _crashCount = crashCount
        super.init(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
    }
    
    required init?(coder aDecoder: NSCoder) {
        _shouldResetLevel = .constant(false)
        _gameIsPaused = .constant(false)
        _fuelLevel = .constant(100)
        _crashCount = .constant(0)
        super.init(coder: aDecoder)
    }
    
    override func didMove(to: SKView) {
        super.didMove(to: view!)
        
        top = self.frame.size.height;
        right = self.frame.size.width;
        
        // gamescene is the physicsWorld delegate
        physicsWorld.contactDelegate = self
        
        // set gravity
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityForce)
        
        // enable multitouch gestures
        view?.isMultipleTouchEnabled = true
        
        // create the craft and canyon
        createCraft()
        createCanyon()
        
    }
    
//    func togglePause(to state: Bool) {
//        scene?.isPaused = state
//    }
    
    func createCraft() {
        
        // Create craft body
        craft = SKSpriteNode(color: UIColor.red, size: CGSize(width: 40, height: 30))
        craft.texture = SKTexture(imageNamed: "Craft-Body_Texture")
        craft.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "craftCollision"), size: craft.size)
        
        craft.physicsBody!.affectedByGravity = true
        craft.physicsBody!.angularDamping = 1
        craft.physicsBody!.friction = 0.75
        craft.physicsBody!.isDynamic = true
        
        craft.physicsBody!.categoryBitMask = CraftCategory
        craft.physicsBody!.contactTestBitMask = BorderCategory
        craft.position = CGPoint(x: right/2, y: top-20)
        self.addChild(craft)
        
        // Create landing gear left
        landingGearLeft = SKSpriteNode(color: UIColor.white, size: CGSize(width: 10, height: 20))
        landingGearLeft.texture = SKTexture(imageNamed: "Landing-Left_Texture")
        landingGearLeft.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "landingGearLeftCollision"), size: CGSize(width: 10, height: 15))
        
        landingGearLeft.physicsBody!.affectedByGravity = true
        landingGearLeft.physicsBody!.angularDamping = 1
        landingGearLeft.physicsBody!.friction = 1
        landingGearLeft.physicsBody!.isDynamic = true
        
        landingGearLeft.physicsBody!.categoryBitMask = LandingGearCategory
        landingGearLeft.physicsBody!.contactTestBitMask = PadCategory
        landingGearLeft.position = CGPoint(x: right/2 - 15, y: top-27)
        self.addChild(landingGearLeft)
        
        // Create landing gear right
        landingGearRight = SKSpriteNode(color: UIColor.white, size: CGSize(width: 10, height: 20))
        landingGearRight.texture = SKTexture(imageNamed: "Landing-Right_Texture")
        landingGearRight.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "landingGearRightCollision"), size: CGSize(width: 10, height: 15))
        
        landingGearRight.physicsBody!.affectedByGravity = true
        landingGearRight.physicsBody!.angularDamping = 1
//        landingGearRight.physicsBody!.contactTestBitMask = 1
        landingGearRight.physicsBody!.friction = 1
        landingGearRight.physicsBody!.isDynamic = true
        
        landingGearRight.physicsBody!.categoryBitMask = LandingGearCategory
        landingGearRight.physicsBody!.contactTestBitMask = PadCategory
        landingGearRight.position = CGPoint(x: right/2 + 15, y: top-27)
        self.addChild(landingGearRight)
        
        // Create fixed joint
        fixed = SKPhysicsJointFixed.joint(withBodyA: landingGearLeft.physicsBody!, bodyB: landingGearRight.physicsBody!, anchor: CGPoint(x: landingGearLeft.position.x - landingGearRight.position.x, y: landingGearLeft.position.y))
        self.physicsWorld.add(fixed)
        
        // Create sliding joint
        slider = SKPhysicsJointSliding.joint(withBodyA: craft.physicsBody!, bodyB: landingGearLeft.physicsBody!, anchor: craft.position, axis: CGVector(dx: 0, dy: 5))
        slider.upperDistanceLimit = 10
        slider.lowerDistanceLimit = 0
        slider.shouldEnableLimits = true
        self.physicsWorld.add(slider)
        
        // Create spring joint
        spring = SKPhysicsJointSpring.joint(withBodyA: craft.physicsBody!, bodyB: landingGearLeft.physicsBody!, anchorA: craft.position, anchorB: craft.position)
        spring.frequency = 20.0
        spring.damping = 20.0
        self.physicsWorld.add(spring)
    }
    
    func removeCraft() {
        craft.removeFromParent()
        landingGearLeft.removeFromParent()
        landingGearRight.removeFromParent()
    }
    
    func addThrust() {
        if !thrustApplied {
            // Create thrust particle emitter
            thrustNode = SKEmitterNode(fileNamed: "ThrustParticle.sks")
            thrustNode.position = CGPoint(x: 0, y: -(craft.size.height/2))
            thrustNode.targetNode = self.scene
            
            // Attach to craft
            craft.addChild(thrustNode)
            thrustApplied = true
        }
    }
    
    func createCanyon() {
        
        // Create center of path, stored as array
        var thePath: [[CGFloat]] = []
        
        var pathX: CGFloat = right/2
        var pathY: CGFloat = top - 50
        
        
        while pathY > 100 {
            let varianceX = CGMath().CGRandomBetweenNumbers(from: 50, to: 100)
            let c = Int(CGMath().CGRandomBetweenNumbers(from: 1, to: 3))
            
            if c == 1 {
                // x = x
            }
            if c == 2 {
                if (pathX - varianceX > 0) {
                    pathX = pathX - varianceX
                } else {
                    //x = x + m
                }
            } else {
                if (pathX + varianceX < right) {
                    pathX = pathX + varianceX
                } else {
                    pathX = pathX - varianceX
                }
            }
            
            pathY = pathY - CGMath().CGRandomBetweenNumbers(from: 30, to: 100)
            
            //println("x:\(pathX),y:\(pathY)")
            thePath.append([pathX,pathY])
        }
        
        if pathY > 10 {thePath.append([pathX,10])}
        
        
        // Create left & right edge of path
        
        let leftPath = CGMutablePath()
        let rightPath = CGMutablePath()
        
        leftPath.move(to: CGPoint(x: right/2 - 50, y: top))
        leftPath.addLine(to: CGPoint(x: right/2 - 50, y: top - 50))
        
        rightPath.move(to: CGPoint(x: right/2 + 50, y: top))
        rightPath.addLine(to: CGPoint(x: right/2 + 50, y: top - 50))
        
        for point in thePath {
            
            var xL = point[0] - 50 //- r
            var xR = point[0] + 50 //+ r
            
            if xL <= 0 {
                xL = 0
                xR = 100
            }
            if xR >= right {
                xL = right - 100
                xR = right
            }
            
            pathY = point[1]
            
            leftPath.addLine(to: CGPoint(x: xL, y: pathY))
            rightPath.addLine(to: CGPoint(x: xR, y: pathY))
        }
        
        
        // Add edges to game scene
        
        borderLeft = SKShapeNode(path: leftPath)
        borderLeft.physicsBody = SKPhysicsBody(edgeChainFrom: leftPath)
        borderLeft.physicsBody!.categoryBitMask = BorderCategory
        borderLeft.physicsBody!.friction = 0.5
        borderLeft.physicsBody!.isDynamic = false
        self.addChild(borderLeft)
        
        borderRight = SKShapeNode(path: rightPath)
        borderRight.physicsBody = SKPhysicsBody(edgeChainFrom: rightPath)
        borderRight.physicsBody!.categoryBitMask = BorderCategory
        borderRight.physicsBody!.friction = 0.5
        borderRight.physicsBody!.isDynamic = false
        self.addChild(borderRight)
        
        // create landing pad & level label
        pad = SKSpriteNode(color: UIColor.red, size: CGSize(width: 100, height: 5))
        pad.position = CGPoint(x: pathX, y: 5)
        pad.texture = SKTexture(imageNamed: "landingPad")
        
        pad.physicsBody = SKPhysicsBody(texture: pad.texture!, size: pad.size)
        pad.physicsBody!.isDynamic = false
        pad.physicsBody!.categoryBitMask = PadCategory
        pad.physicsBody!.contactTestBitMask = CraftCategory
        self.addChild(pad)
        
        levelLabel = SKLabelNode(fontNamed: "SpaceMono-Bold")
        levelLabel.fontColor = SKColor.white
        levelLabel.text = "\(levelCount)"
        levelLabel.fontSize = 16
        levelLabel.position = CGPoint(x: pathX, y: 10)
        self.addChild(levelLabel)
    }
    
    func resetLevel() {
        // make next level
        borderLeft.removeFromParent()
        borderRight.removeFromParent()
        pad.removeFromParent()
        levelLabel.removeFromParent()
        createCanyon()
        
        // reset craft
        removeCraft()
        shouldResetCraft = true
        
        print("time to reset the level")
    }
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Used to: Convert touches from Set > Array because Set is not indexed
        for touch in touches {
            self.touchesArray.insert(touch, at: 0)
        }
        
        if self.touchesArray.count > 1 {
            
            let touch1 = self.touchesArray[0]
            let touch1Location = touch1.location(in: self)
            
            let touch2 = self.touchesArray[1]
            let touch2Location = touch2.location(in: self)
            
            let portion = self.frame.width/2
            
            // if one touch is on 1 half of the screen and the other is on the other
            if ((touch1Location.x < portion) && (touch2Location.x > portion / 2) || (touch1Location.x > portion / 2) && (touch2Location.x < portion / 2)) {
                
                // will apply force in update
                isTouchingBoth = true
                
                // thrust sounds added
                //thrustStart.play()
//                thrust.numberOfLoops = -1
//                thrust.play()
//                CGAudio().playSound("thrust")
                
            } else {
                
                // go by first touch
                if touch1Location.x < self.frame.size.width / 2 {
                    // rotate left
                    isTouchingLeft = true
                } else {
                    // rotate right
                    isTouchingRight = true
                }
                
            }
        } else {
            
            let touch:UITouch = touches.first!
            let touchLocation = touch.location(in: self)
            
            if touchLocation.x < self.frame.size.width / 2 {
                // rotate left
                isTouchingLeft = true
            } else {
                // rotate right
                isTouchingRight = true
            }
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // clear out current touches from touchesArray
        touchesArray = []
        
        // stops applying force & rotation in update
        isTouchingBoth = false
        isTouchingLeft = false
        isTouchingRight = false
        
        // remove thrust particle emitter
        if thrustNode != nil {
            thrustNode.removeFromParent()
            thrustApplied = false
        }
        
        // thrust sounds stopped
        // thrustStart.stop()
        // thrust.stop()
    }

    override func update(_ currentTime: TimeInterval) {
        
        if didLand {
            if abs(craft.physicsBody!.velocity.dx) <= 0.1 && abs(craft.physicsBody!.velocity.dy) <= 0.1 {
                levelCount += 1
                resetLevel()
                didLand = false
            }
        }
        
        if shouldResetLevel {
            resetLevel()
            shouldResetLevel = false
        }
        
        if canyonCollide {
            
            crashCount += 1
            
            removeCraft()
            
            // TODO: Animation/effect on canyon collision
            // exp.removeFromParent()
            // exp.position = craft.position
            // self.addChild(exp)
            // expAnimated()
            // explosion.play()
            
            shouldResetCraft = true
            canyonCollide = false
        }
        
        if shouldResetCraft {
            fuelLevel = 100
            
            createCraft()
            shouldResetCraft = false
        }
        
        if fuelLevel > 0 {
            if (isTouchingBoth) {
                
                // update fuel level
                fuelLevel -= fuelCost
                
                // apply thrust
                craft.physicsBody!.applyForce(CGMath().createThrustVector(r: thrustForce, sprite:craft))
                
                // add thrust particle emitter
                addThrust()
            }
            if isTouchingLeft {
                // rotate left
                craft.physicsBody!.applyAngularImpulse(rotationForce)
            } else if isTouchingRight {
                // rotate right
                craft.physicsBody!.applyAngularImpulse(-rotationForce)
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // create local variables for two physics bodies
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // assign the two physics bodies so that the one with the lower category is always stored in firstBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        canyonCollide = firstBody.categoryBitMask == CraftCategory && (secondBody.categoryBitMask == BorderCategory || secondBody.categoryBitMask == PadCategory)
        
        didLand = firstBody.categoryBitMask == LandingGearCategory && secondBody.categoryBitMask == PadCategory
    }
}
