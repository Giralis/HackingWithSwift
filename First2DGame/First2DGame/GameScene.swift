//
//  GameScene.swift
//  First2DGame
//
//  Created by Владимир Тимофеев on 14.12.2021.
//

import SpriteKit
import UIKit

class GameScene: SKScene {
    var scoreLabel: SKLabelNode!
    var countBallsLabel: SKLabelNode!
    
    var countBalls = 5 {
        didSet {
            countBallsLabel.text = "Balls: \(countBalls)"
        }
    }
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var editLabel: SKLabelNode!
    
    var editingMode: Bool = false {
        didSet {
            if editingMode {
                editLabel.text = "Done"
            } else {
                editLabel.text = "Edit"
            }
        }
    }
    
    override func didMove(to view: SKView) {
        addBackground()
        addScoreLabel()
        addCountBallsLabel()
        addEditLabel()
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.contactDelegate = self
        
        addSlots()
        addBouncers()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let objects = nodes(at: location)
        
        if objects.contains(editLabel) {
            editingMode.toggle()
        } else {
            if editingMode {
                addBox(at: location)
            } else {
                if countBalls > 0 {
                    addBall(at: location)
                    countBalls -= 1
                } else {
                    countBalls = 5
                    score = 0
                    removeAllChildren()
                    didMove(to: self.view!)
                }
            }
        }
    }
    
    func makeBouncer(at position: CGPoint) {
        let bouncer = SKSpriteNode(imageNamed: "bouncer")
        bouncer.position = position
        bouncer.physicsBody = SKPhysicsBody(circleOfRadius: bouncer.size.width / 2)
        bouncer.physicsBody?.isDynamic = false
        addChild(bouncer)
    }
    
    func makeSlot(at position: CGPoint, isGood: Bool) {
        var slotBase: SKSpriteNode
        var slotGlow: SKSpriteNode
        
        if isGood {
            slotBase = SKSpriteNode(imageNamed: "slotBaseGood")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowGood")
            slotBase.name = "good"
        } else {
            slotBase = SKSpriteNode(imageNamed: "slotBaseBad")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowBad")
            slotBase.name = "bad"
        }
        
        slotBase.position = position
        slotGlow.position = position
        
        slotBase.physicsBody = SKPhysicsBody(rectangleOf: slotBase.size)
        slotBase.physicsBody?.isDynamic = false
        
        addChild(slotBase)
        addChild(slotGlow)
        
        let spin = SKAction.rotate(byAngle: .pi, duration: 10)
        let spinForever = SKAction.repeatForever(spin)
        slotGlow.run(spinForever)
    }
    
    func collision(between ball: SKNode, object: SKNode) {
        if object.name == "good" {
            destroy(ball: ball)
            score += 1
            countBalls += 1
        } else if object.name == "bad" {
            destroy(ball: ball)
            score -= 1
        }
    }
    
    func destroy(ball: SKNode) {
        if let fireParticles = SKEmitterNode(fileNamed: "FireParticles"){
            fireParticles.position = ball.position
            addChild(fireParticles)
        }
        ball.removeFromParent()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA.name == "box" {
            nodeA.removeFromParent()
        } else if nodeB.name == "box" {
            nodeB.removeFromParent()
        } else if nodeA.name == "ball" {
            collision(between: nodeA, object: nodeB)
        } else if nodeB.name == "ball" {
            collision(between: nodeB, object: nodeA)
        }
    }
}

extension GameScene: SKPhysicsContactDelegate{
    func addBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
    }
    
    func addBall(at location: CGPoint) {
        let ballColors = ["Red", "Blue", "Cyan", "Green", "Grey", "Purple", "Yellow"]
        let random = Int.random(in: 0...ballColors.count-1)
        let ball = SKSpriteNode(imageNamed: "ball\(ballColors[random])")
        ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2)
        ball.physicsBody?.restitution = 0.4
        ball.physicsBody?.contactTestBitMask = ball.physicsBody?.collisionBitMask ?? 0
        ball.position = CGPoint(x: location.x, y: 650)
        ball.name = "ball"
        addChild(ball)
    }
    func addScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: 980, y: 700)
        addChild(scoreLabel)
    }
    
    func addCountBallsLabel() {
        countBallsLabel = SKLabelNode(fontNamed: "Chalkduster")
        countBallsLabel.text = "Balls: 5"
        countBallsLabel.horizontalAlignmentMode = .right
        countBallsLabel.position = CGPoint(x: 980, y: 650)
        addChild(countBallsLabel)
    }
    
    func addEditLabel() {
        editLabel = SKLabelNode(fontNamed: "Chalkduster")
        editLabel.text = "Edit"
        editLabel.position = CGPoint(x: 80, y: 700)
        addChild(editLabel)
    }
    
    func addSlots() {
        var goodOrBad = true
        for x in [128, 384, 640, 896] {
            makeSlot(at: CGPoint(x: x, y: 0), isGood: goodOrBad)
            goodOrBad.toggle()
        }
    }
    
    func addBouncers() {
        for x in [0, 256, 512, 768, 1024] {
            makeBouncer(at: CGPoint(x: x, y: 0))
        }
    }
    
    func addBox(at location: CGPoint) {
        let size = CGSize(width: Int.random(in: 16...128), height: 16)
        let randomColor = CGFloat.random(in: 0...1)
        let box = SKSpriteNode(color: UIColor(red: randomColor, green: randomColor, blue: randomColor, alpha: 1), size: size)
        box.zRotation = CGFloat.random(in: 0...3)
        box.position = location
        
        box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
        box.physicsBody?.isDynamic = false
        box.name = "box"
        addChild(box)
    }
}
