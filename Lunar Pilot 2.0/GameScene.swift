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
    
    // TODO: toggle isPaused from parent view
    // Initially was using this to turn the class into a singleton
    // This is useful if we need to make function calls directly on the class instance
    // However, this doesn’t seem to be working for changing the isPaused state
    // Also, use of singletons isn’t recommended (for a variety of reasons), and we’re already doing @Bindings...
    
    // lazy var shared = GameScene($shouldResetLevel, gameIsPaused: $gameIsPaused, fuelLevel: $fuelLevel, crashCount: $crashCount)
    
    // func togglePause(to state: Bool) {
    // scene?.isPaused = state
    // }
    
    // Next thing to try: add a @Binding initialSetup bool to ensure that
    
    private let gravityForce = -0.2
    private let thrustForce = 2.0
    private let rotationForce = 5.0 / 1000000
    private let fuelCost = 0.05
    
    enum isTouching {
        case left, right, both, none
    }
    
    private var currentTouch = isTouching.none
    
    private var shouldResetCraft = false
    private var didLand = false
    private var canyonCollide = false
    
    private var screenHeight: CGFloat!
    private var screenWidth: CGFloat!
    
    private let CraftCategory: UInt32 = 0x1 << 0        // 00000000000000000000000000000001
    private let LandingGearCategory: UInt32 = 0x1 << 1  // 00000000000000000000000000000010
    private let BorderCategory: UInt32 = 0x1 << 2       // 00000000000000000000000000000100
    private let PadCategory: UInt32 = 0x1 << 3          // 00000000000000000000000000001000
    
    private var borderLeft: SKShapeNode!
    private var borderRight: SKShapeNode!
    private var pad: SKSpriteNode!
    
    private var craft: SKSpriteNode!
    private var landingGearLeft: SKSpriteNode!
    private var landingGearRight: SKSpriteNode!
    private var fixedJoint: SKPhysicsJointFixed!
    private var springJoint: SKPhysicsJointSpring!
    private var sliderJoint: SKPhysicsJointSliding!
    
    private var thrustNode: SKEmitterNode!
    private var rotateLeftNode: SKEmitterNode!
    private var rotateRightNode: SKEmitterNode!
    private var crashNode: SKEmitterNode!
    
    private var backgroundTexture: SKSpriteNode!
    
    private var levelLabel: SKLabelNode!
    private var levelCount: Int = 1
    
    private var crashResetTimer: Int = 60
    
    private var touchesArray = [UITouch]()
    
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
        
        screenHeight = self.frame.size.height;
        screenWidth = self.frame.size.width;
        
        // gamescene is the physicsWorld delegate
        physicsWorld.contactDelegate = self
        
        // set gravity
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityForce)
        
        // enable multitouch gestures
        view?.isMultipleTouchEnabled = true
        
        // set crash reset timer
        setCrashResetTimer()
        
        // create the craft and canyon
        createBackground()
        createCanyon()
        createCraft()
    }
    
    func createBackground() {
        // Procedurally place large, medium, and small stars as individual sprites
        backgroundTexture = SKSpriteNode(color: UIColor.black, size: self.size)
        backgroundTexture.zPosition = -1
        
        let numCols = 2
        let numRows = 4
        
        // Create boxes based on width and height
        // X
        // 0 -> width/3 | width/3 -> width*2/3 | width*2/3 -> width
        // 0/3 -> 1/3   | 1/3 -> 2/3           | 2/3 -> 3/3
        
        // Define rows iteration
        for y in 1...numRows {
            // Define column iteration
            for x in 1...numCols {
                let currentMinX = CGFloat(Int(screenWidth) * (x-1)/numCols)
                let currentMaxX = CGFloat(Int(screenWidth) * x/numCols)
                
                let currentMinY = CGFloat(Int(screenHeight) * (y-1)/numRows)
                let currentMaxY = CGFloat(Int(screenHeight) * y/numRows)
                
                // 1 large star per grid box
                let starLarge = SKSpriteNode(texture: SKTexture(imageNamed: "Star_Large"), size: CGSize(width: 20, height: 20))
                starLarge.position = CGPoint(x: CGMath().CGRandomBetweenNumbers(from: currentMinX, to: currentMaxX), y: CGMath().CGRandomBetweenNumbers(from: currentMinY, to: currentMaxY))
                backgroundTexture.addChild(starLarge)
                
                // 2 medium stars per grid box
                for _ in 1...2 {
                    let starMedium = SKSpriteNode(texture: SKTexture(imageNamed: "Star_Medium"), size: CGSize(width: 10, height: 10))
                    starMedium.position = CGPoint(x: CGMath().CGRandomBetweenNumbers(from: currentMinX, to: currentMaxX), y: CGMath().CGRandomBetweenNumbers(from: currentMinY, to: currentMaxY))
                    backgroundTexture.addChild(starMedium)
                }
                
                // 3 small stars per grid box
                for _ in 1...3 {
                    let starSmall = SKSpriteNode(texture: SKTexture(imageNamed: "Star_Small"), size: CGSize(width: 5, height: 5))
                    starSmall.position = CGPoint(x: CGMath().CGRandomBetweenNumbers(from: currentMinX, to: currentMaxX), y: CGMath().CGRandomBetweenNumbers(from: currentMinY, to: currentMaxY))
                    backgroundTexture.addChild(starSmall)
                }
            }
        }
        
        self.addChild(backgroundTexture)
    }
    
    func createCraft() {
        
        // Create craft body
        craft = SKSpriteNode(color: UIColor.red, size: CGSize(width: 40, height: 30))
        craft.texture = SKTexture(imageNamed: "Craft-Body_Texture")
        craft.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "Craft-Body_Collision"), size: CGSize(width: craft.size.width - 4, height: craft.size.height - 4))
        
        craft.physicsBody!.angularDamping = 1
        
        craft.physicsBody!.categoryBitMask = CraftCategory
        craft.physicsBody!.contactTestBitMask = BorderCategory
        craft.position = CGPoint(x: screenWidth/2, y: screenHeight-20)
        self.addChild(craft)
        
        // Create landing gear left
        landingGearLeft = SKSpriteNode(color: UIColor.white, size: CGSize(width: 10, height: 17))
        landingGearLeft.texture = SKTexture(imageNamed: "Landing-Left_Texture")
        
        let leftFootPath = CGMutablePath()
        let leftEdge = -4.5
        let rightEdge = -1.0
        let topEdge = -5.5
        let bottomEdge = -6.75
        leftFootPath.addLines(between: [CGPoint(x: leftEdge, y: bottomEdge), CGPoint(x: rightEdge, y: bottomEdge), CGPoint(x: rightEdge, y: topEdge), CGPoint(x: leftEdge, y: topEdge)])
        leftFootPath.closeSubpath()
        landingGearLeft.physicsBody = SKPhysicsBody(polygonFrom: leftFootPath)
        
        landingGearLeft.physicsBody!.friction = 1
        
        landingGearLeft.physicsBody!.categoryBitMask = LandingGearCategory
        landingGearLeft.physicsBody!.contactTestBitMask = PadCategory
        landingGearLeft.position = CGPoint(x: screenWidth/2 - 15, y: screenHeight-27)
        self.addChild(landingGearLeft)
        
        // Create landing gear right
        landingGearRight = landingGearLeft.copy() as? SKSpriteNode
        landingGearRight.xScale = -1.0
        landingGearRight.position = CGPoint(x: screenWidth/2 + 15, y: screenHeight-27)
        self.addChild(landingGearRight)
        
        // Create fixed joint between each landing gear
        fixedJoint = SKPhysicsJointFixed.joint(withBodyA: landingGearLeft.physicsBody!, bodyB: landingGearRight.physicsBody!, anchor: CGPoint(x: landingGearLeft.position.x - landingGearRight.position.x, y: landingGearLeft.position.y))
        self.physicsWorld.add(fixedJoint)
        
        // Create sliding joint between landing gear and craft body
        sliderJoint = SKPhysicsJointSliding.joint(withBodyA: craft.physicsBody!, bodyB: landingGearLeft.physicsBody!, anchor: craft.position, axis: CGVector(dx: 0, dy: 5))
        sliderJoint.upperDistanceLimit = 10
        sliderJoint.lowerDistanceLimit = 0
        sliderJoint.shouldEnableLimits = true
        self.physicsWorld.add(sliderJoint)
        
        // Create spring joint between landing gear and craft body
        springJoint = SKPhysicsJointSpring.joint(withBodyA: craft.physicsBody!, bodyB: landingGearLeft.physicsBody!, anchorA: craft.position, anchorB: craft.position)
        springJoint.frequency = 20.0
        springJoint.damping = 5.0
        self.physicsWorld.add(springJoint)
        
        // Create thrust particle emitter
        thrustNode = SKEmitterNode(fileNamed: "ThrustParticle.sks")
        thrustNode.position = CGPoint(x: 0, y: -(craft.size.height/2))
        thrustNode.targetNode = self.scene
        thrustNode.particleBirthRate = 0
        craft.addChild(thrustNode)
        
        // Create left and right thrust particle emitter
        rotateLeftNode = SKEmitterNode(fileNamed: "ThrustParticle.sks")
        rotateRightNode = SKEmitterNode(fileNamed: "ThrustParticle.sks")
        rotateLeftNode.position = CGPoint(x: -(craft.size.width/2), y: -(craft.size.height/2))
        rotateRightNode.position = CGPoint(x: craft.size.width/2, y: -(craft.size.height/2))
        
        rotateLeftNode.targetNode = self.scene
        rotateRightNode.targetNode = self.scene
        
        rotateLeftNode.particleBirthRate = 0
        rotateRightNode.particleBirthRate = 0
        rotateLeftNode.emissionAngle = 180
        rotateRightNode.emissionAngle = 0
        rotateLeftNode.particlePositionRange.dx = 1
        rotateRightNode.particlePositionRange.dx = 1
        rotateLeftNode.particleLifetimeRange = 0.15
        rotateRightNode.particleLifetimeRange = 0.15
        
        craft.addChild(rotateLeftNode)
        craft.addChild(rotateRightNode)
    }
    
    func removeCraft() {
        craft.removeFromParent()
        landingGearLeft.removeFromParent()
        landingGearRight.removeFromParent()
    }
    
    func createCanyon() {
        
        // Create center of path, stored as array
        var canyonRoutePath: [[CGFloat]] = []
        
        var pathX: CGFloat = screenWidth/2
        var pathY: CGFloat = screenHeight - 50
        
        
        while pathY > 100 {
            let varianceX = CGMath().CGRandomBetweenNumbers(from: 1, to: 75)
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
                if (pathX + varianceX < screenWidth) {
                    pathX = pathX + varianceX
                } else {
                    pathX = pathX - varianceX
                }
            }
            
            pathY = pathY - CGMath().CGRandomBetweenNumbers(from: 1, to: 100)
            
            //println("x:\(pathX),y:\(pathY)")
            canyonRoutePath.append([pathX,pathY])
        }
        
        if pathY > 10 {canyonRoutePath.append([pathX,10])}
        
        // Create left & right edge of path
        
        let leftPath = CGMutablePath()
        let rightPath = CGMutablePath()
        
        leftPath.move(to: CGPoint(x: screenWidth/2 - 50, y: screenHeight))
        leftPath.addLine(to: CGPoint(x: screenWidth/2 - 50, y: screenHeight - 50))
        
        rightPath.move(to: CGPoint(x: screenWidth/2 + 50, y: screenHeight))
        rightPath.addLine(to: CGPoint(x: screenWidth/2 + 50, y: screenHeight - 50))
        
        for point in canyonRoutePath {
            
            var xL = point[0] - 100 //- r
            var xR = point[0] + 100 //+ r
            
            if xL <= 0 {
                xL = 0
                xR = 100
            }
            if xR >= screenWidth {
                xL = screenWidth - 100
                xR = screenWidth
            }
            
            pathY = point[1]
            
            leftPath.addLine(to: CGPoint(x: xL, y: pathY))
            rightPath.addLine(to: CGPoint(x: xR, y: pathY))
        }
        
        // Complete path around edge of the screen
        leftPath.addLine(to: CGPoint(x: 0 - 5, y: 0 - 5))
        leftPath.addLine(to: CGPoint(x: 0 - 5, y: screenHeight + 5))
        rightPath.addLine(to: CGPoint(x: screenWidth + 5, y: 0 - 5))
        rightPath.addLine(to: CGPoint(x: screenWidth + 5, y: screenHeight + 5))
        
        // Add edges to game scene
        borderLeft = SKShapeNode(path: leftPath)
        borderLeft.physicsBody = SKPhysicsBody(edgeChainFrom: leftPath)
        borderLeft.physicsBody!.categoryBitMask = BorderCategory
        borderLeft.physicsBody!.friction = 0.5
        borderLeft.physicsBody!.isDynamic = false
        borderLeft.fillColor = UIColor.black
        self.addChild(borderLeft)
        
        borderRight = SKShapeNode(path: rightPath)
        borderRight.physicsBody = SKPhysicsBody(edgeChainFrom: rightPath)
        borderRight.physicsBody!.categoryBitMask = BorderCategory
        borderRight.physicsBody!.friction = 0.5
        borderRight.physicsBody!.isDynamic = false
        borderRight.fillColor = UIColor.black
        self.addChild(borderRight)
        
        // Create landing pad & level count label
        let padWidth: CGFloat = 100
        let padHeight: CGFloat = 5
        var padX: CGFloat = padWidth/2
        
        // Make sure the pad doesn’t go off the edge of the screen
        if pathX < padWidth/2 {
            padX = padWidth/2
        } else if pathX > screenWidth - padWidth/2 {
            padX = screenWidth - padWidth/2
        } else {
            padX = pathX
        }
        
        pad = SKSpriteNode(color: UIColor.red, size: CGSize(width: padWidth, height: padHeight))
        pad.position = CGPoint(x: padX, y: padHeight)
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
        levelLabel.position = CGPoint(x: pad.position.x, y: (pad.position.y + 10))
        self.addChild(levelLabel)
    }
    
    func resetLevel() {
        
        // remove current level
        borderLeft.removeFromParent()
        borderRight.removeFromParent()
        backgroundTexture.removeFromParent()
        pad.removeFromParent()
        levelLabel.removeFromParent()
        
        // redraw level
        createCanyon()
        createBackground()
        
        // reset craft
        removeCraft()
        shouldResetCraft = true
    }
    
    func setCrashResetTimer() {
        crashResetTimer = (self.scene?.view?.preferredFramesPerSecond ?? 60) * 3
    }
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            // Place touches in global array so that they persist beyond the initial touchesBegan() event
            self.touchesArray.insert(touch, at: 0)
        }
        
        resolveTouchState()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Remove the touch that ended from the global array
        for touch in touches {
            if let index = self.touchesArray.firstIndex(of: touch) {
                self.touchesArray.remove(at: index)
            }
        }
        
        resolveTouchState()
    }
    
    func resolveTouchState() {
        
        var touchingLeft = false
        var touchingRight = false
        
        if touchesArray.count > 0 {
            
            // For touches in the array, record whether there was at least 1 touch on left or right of screen
            for touch in touchesArray {
                if (touch.location(in: self).x < self.frame.width/2) {
                    touchingLeft = true
                } else {
                    touchingRight = true
                }
            }
            
            // Set value of currentTouch based on whether touches exist on both sides
            if touchingLeft && touchingRight {
                currentTouch = isTouching.both
            } else if touchingLeft && !touchingRight {
                currentTouch = isTouching.left
            } else {
                currentTouch = isTouching.right
            }
        } else {
            // If touch array is empty, set touching to none
            currentTouch = isTouching.none
        }
    }

    override func update(_ currentTime: TimeInterval) {
        
        if didLand {
            if abs(craft.physicsBody!.velocity.dx) <= 0.3 && abs(craft.physicsBody!.velocity.dy) <= 0.3 {
                levelCount += 1
                resetLevel()
                didLand = false
            }
        }
        
        if shouldResetLevel {
            resetLevel()
            shouldResetLevel = false
        }
        
        if shouldResetCraft {
            fuelLevel = 100
            
            createCraft()
            shouldResetCraft = false
        }
        
        if canyonCollide {
            
            // Break the craft apart into pieces
            self.physicsWorld.remove(fixedJoint)
            self.physicsWorld.remove(sliderJoint)
            self.physicsWorld.remove(springJoint)
            // Need to set a delay before placing explosion emitter and resetting craft
            
            crashResetTimer -= 1
            if crashResetTimer <= 0 {
                crashNode = SKEmitterNode(fileNamed: "BurstParticle.sks")
                crashNode.position = craft.position
                crashNode.targetNode = self.scene
                self.addChild(crashNode)
                
                crashCount += 1
                
                setCrashResetTimer()
                removeCraft()
                
                shouldResetCraft = true
                canyonCollide = false
                
            }
        }
        
        if fuelLevel > 0 {
            switch currentTouch {
            case .both:
                
                // update fuel level
                fuelLevel -= fuelCost
                
                // apply thrust
                craft.physicsBody!.applyForce(CGMath().createThrustVector(r: thrustForce, sprite:craft))
                
                // add thrust particle emitter
                thrustNode.particleBirthRate = 200
                
            case .left:
                
                // update fuel level
                fuelLevel -= fuelCost/2
                
                // rotate left
                craft.physicsBody!.applyAngularImpulse(rotationForce)
                
                // add rotate particle emitter
                rotateLeftNode.particleBirthRate = 100
                
            case .right:
                
                // update fuel level
                fuelLevel -= fuelCost/2
                
                // rotate right
                craft.physicsBody!.applyAngularImpulse(-rotationForce)
                
                // add rotate particle emitter
                rotateRightNode.particleBirthRate = 100
                
            case .none:
                
                // turn off thrust
                thrustNode.particleBirthRate = 0
                rotateLeftNode.particleBirthRate = 0
                rotateRightNode.particleBirthRate = 0
            }
        }
    }
    
//    override func didFinishUpdate() {
//        centerCamera()
//    }
//
//    func centerCamera() {
//
//    }
    
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
