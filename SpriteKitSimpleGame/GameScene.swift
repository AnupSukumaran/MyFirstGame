//
//  GameScene.swift
//  SpriteKitSimpleGame
//
//  Created by Sukumar Anup Sukumaran on 16/02/18.
//  Copyright © 2018 AssaRadviewTech. All rights reserved.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    
    static let None : UInt32 = 0
    static let All  : UInt32 = UInt32.max
    static let Monster : UInt32 = 0b1
    static let Projectile: UInt32 = 0b10
    
}


func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif



extension CGPoint {
    
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
    
    
    
}




class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let player = SKSpriteNode(imageNamed: "player")
    var monstersDestroyed = 0
    
    override func didMove(to view: SKView) {
        
        backgroundColor = SKColor.white
        
        print("size.width = \(size.width), X = \(size.width * 0.1), size.height = \(size.height), Y = \(size.height * 0.5) ")
        
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        
        addChild(player)
    
        //adding monster function
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(addMonster), SKAction.wait(forDuration: 1.0)])))
        
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //1
        guard let touch = touches.first  else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        
        //2
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        
        //3
        let offset = touchLocation - projectile.position
        
        //4
        if (offset.x < 0){
            return
        }
        
        //5
        addChild(projectile)
        
        //6
        let direction = offset.normalized()
        
        //7
        let shootAmount = direction * 1000
        
        //8
        let realDest = shootAmount + projectile.position
        
        //9
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
    }
    
    
    
    func random() -> CGFloat {
        
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF )
        
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        
        return random() * (max - min) + min
        
    }
    

    
    func addMonster() {
        
        //create sprite
        let monster = SKSpriteNode(imageNamed: "monsters")
        
        //Determine where to spawn the monster along y axis
        let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
        
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)

        addChild(monster)

        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))

        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        
        let loseAction = SKAction.run() {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        
        monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) //1
        monster.physicsBody?.isDynamic = true //2
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster //3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile //4
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None //5
        
        
        
    }
    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: SKSpriteNode) {
        print("Hi")
        projectile.removeFromParent()
        monster.removeFromParent()
        
        monstersDestroyed += 1
        if (monstersDestroyed > 2) {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) && (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)){
            
            if let monster = firstBody.node as? SKSpriteNode, let projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster)
            }
            
        }
    }
    
    
    
//    private var label : SKLabelNode?
//    private var spinnyNode : SKShapeNode?
//
//    override func didMove(to view: SKView) {
//
//        // Get label node from scene and store it for use later
//        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
//        if let label = self.label {
//            label.alpha = 0.0
//            label.run(SKAction.fadeIn(withDuration: 2.0))
//        }
//
//        // Create shape node to use during mouse interaction
//        let w = (self.size.width + self.size.height) * 0.05
//        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w + 50), cornerRadius: w * 0.3)
//
//        if let spinnyNode = self.spinnyNode {
//            spinnyNode.lineWidth = 10
//            print("Pie = \(Double.pi)")
//            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
//            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
//                                              SKAction.fadeOut(withDuration: 0.5),
//                                              SKAction.removeFromParent()]))
//        }
//    }
//
//
//    func touchDown(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.green
//            self.addChild(n)
//        }
//    }
//
//    func touchMoved(toPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.blue
//            self.addChild(n)
//        }
//    }
//
//    func touchUp(atPoint pos : CGPoint) {
//        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
//            n.position = pos
//            n.strokeColor = SKColor.red
//            self.addChild(n)
//        }
//    }
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let label = self.label {
//            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
//
//        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
//    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
//    }
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
//    }
//
//    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
//    }
//
//
//    override func update(_ currentTime: TimeInterval) {
//        // Called before each frame is rendered
//    }
}

