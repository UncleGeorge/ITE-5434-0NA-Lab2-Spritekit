//
//  GameScene.swift
//  SuperSpaceMan
//
//  Created by Apptist Inc. on 2023-05-16.
//

import Foundation
import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let playerNode = SKSpriteNode(imageNamed: "Player")
    let backgroundNode = SKSpriteNode(imageNamed: "Background")
    
    let scoreLabel = SKLabelNode(fontNamed: "American Typewriter")
    let gameOverLabel = SKLabelNode(fontNamed: "American Typewriter")
    let elapsedTimeLabel = SKLabelNode(fontNamed: "American Typewriter")
    let restartLabel = SKLabelNode(fontNamed: "American Typewriter")
    
    let enemyCategory: UInt32 = 0x1 << 0
    let powerUpCategory: UInt32 = 0x1 << 1
    let playerCategory: UInt32 = 0x1 << 2
    
    var explosionPlayer: AVAudioPlayer?
    var recoverPlayer: AVAudioPlayer?
    var backgroundMusicPlayer: AVAudioPlayer?
    
    var startTime: Date?
    var spawnInterval: TimeInterval = 0.5
    var enemySpeed: TimeInterval = 1.5
    var powerUpSpeed: TimeInterval = 1.5
    
    var gameOver = false
    
    
    var score = 3 {
        didSet {
            scoreLabel.text = "Score: \(score)"
            if score == 0 {
                gameOver = true
                
                let elapsedTime = Date().timeIntervalSince(startTime!)
                
                gameOverLabel.text = "GAME OVER"
                gameOverLabel.position = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
                addChild(gameOverLabel)
                
                elapsedTimeLabel.text = String(format: "Survival Time: %.3f seconds", elapsedTime)
                elapsedTimeLabel.fontSize = 20
                elapsedTimeLabel.fontColor = SKColor.white
                elapsedTimeLabel.position = CGPoint(x: size.width / 2.0, y: size.height / 2.0 - gameOverLabel.frame.size.height - 10)
                addChild(elapsedTimeLabel)
                
                restartLabel.text = "Tap Here to Play Again"
                restartLabel.fontSize = 20
                restartLabel.fontColor = SKColor.white
                restartLabel.position = CGPoint(x: size.width / 2.0, y: size.height / 2.0 - gameOverLabel.frame.size.height - elapsedTimeLabel.frame.size.height - 30)
                addChild(restartLabel)
                
                if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                    explosion.position = playerNode.position
                    addChild(explosion)
                }
                playerNode.removeFromParent()
                
                removeAction(forKey: "spawn")
            }
        }
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        startTime = Date()
        
        // add difficulty
        startDifficultyTimer()
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -1.8)
        
        //        physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        //        physicsBody?.categoryBitMask = boundaryCategory
        //        physicsBody?.contactTestBitMask = playerCategory
        //        physicsBody?.collisionBitMask = playerCategory
        
        backgroundNode.position = CGPoint(x: size.width / 2.0, y: 0.0)
        backgroundNode.zPosition = -1
        backgroundNode.size.width = frame.size.width
        backgroundNode.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        addChild(backgroundNode)
        
        playerNode.position = CGPoint(x: size.width / 2.0, y: 200)
        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: playerNode.size.width/2)
        playerNode.physicsBody?.isDynamic = false
        playerNode.physicsBody?.categoryBitMask = playerCategory
        playerNode.physicsBody?.collisionBitMask = enemyCategory | powerUpCategory
        playerNode.physicsBody?.contactTestBitMask = enemyCategory | powerUpCategory
        addChild(playerNode)
        
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = SKColor.white
        scoreLabel.position = CGPoint(x: size.width - 80, y: size.height - 80)
        addChild(scoreLabel)
        
        if let explosionURL = Bundle.main.url(forResource: "explosion", withExtension: "mp3"),
           let recoverURL = Bundle.main.url(forResource: "recover", withExtension: "wav"),
           let backgroundMusicURL = Bundle.main.url(forResource: "JeremyBlakePowerup", withExtension: "mp3"){
            do {
                explosionPlayer = try AVAudioPlayer(contentsOf: explosionURL)
                recoverPlayer = try AVAudioPlayer(contentsOf: recoverURL)
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: backgroundMusicURL)
                explosionPlayer?.volume = 0.5
                backgroundMusicPlayer?.numberOfLoops = -1
                backgroundMusicPlayer?.play()
            } catch {
                // Couldn't load file, print error
                print("Couldn't load audio files, error: \(error)")
            }
        }
        
        
        let spawnAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run {
                if self.gameOver {
                    return
                }
                if Int.random(in: 0...100) < 95 {
                    self.addEnemy()
                } else {
                    self.addPowerUp()
                }
            },
            SKAction.wait(forDuration: spawnInterval)
        ]))
        run(spawnAction, withKey: "spawn")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addEnemy() {
        let enemyNode = SKSpriteNode(imageNamed: "BlackHole0")
        enemyNode.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + 100)
        enemyNode.physicsBody = SKPhysicsBody(circleOfRadius: enemyNode.size.width/2)
        enemyNode.physicsBody?.isDynamic = true
        enemyNode.physicsBody?.categoryBitMask = enemyCategory
        enemyNode.physicsBody?.collisionBitMask = playerCategory
        enemyNode.physicsBody?.contactTestBitMask = playerCategory
        enemyNode.run(SKAction.sequence([
            SKAction.moveTo(y: -100, duration: enemySpeed),
            SKAction.removeFromParent()
        ]))
        
        if let flame = SKEmitterNode(fileNamed: "Flame") {
            flame.position = CGPoint(x: 0, y: -enemyNode.size.height/5)
            enemyNode.addChild(flame)
        }
        
        addChild(enemyNode)
    }
    
    func addPowerUp() {
        let powerUpNode = SKSpriteNode(imageNamed: "PowerUp")
        powerUpNode.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + 100)
        powerUpNode.physicsBody = SKPhysicsBody(circleOfRadius: powerUpNode.size.width/2)
        powerUpNode.physicsBody?.isDynamic = true
        powerUpNode.physicsBody?.categoryBitMask = powerUpCategory
        powerUpNode.physicsBody?.collisionBitMask = playerCategory
        powerUpNode.physicsBody?.contactTestBitMask = playerCategory
        powerUpNode.run(SKAction.sequence([
            SKAction.moveTo(y: -100, duration: powerUpSpeed),
            SKAction.removeFromParent()
        ]))
        
        if let fountain = SKEmitterNode(fileNamed: "Fountain") {
            fountain.position = CGPoint(x: 0, y: powerUpNode.size.height/5)
            powerUpNode.addChild(fountain)
        }
        
        addChild(powerUpNode)
    }
    
    func updateGameDifficulty() {
        spawnInterval *= 0.95
        enemySpeed *= 0.95
        powerUpSpeed *= 0.95
    }
    
    func startDifficultyTimer() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if self.gameOver {
                timer.invalidate()
            } else {
                self.updateGameDifficulty()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            playerNode.position = location
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            
            if gameOver {
                if restartLabel.contains(location) {
                    // Restart game logic goes here
                    // e.g. reset score, remove game over and restart labels, respawn player, etc.
                    
                    score = 3
                    startTime = Date()
                    spawnInterval = 0.5
                    enemySpeed = 1.5
                    powerUpSpeed = 1.5
                    
                    startDifficultyTimer()
                    
                    gameOver = false
                    gameOverLabel.removeFromParent()
                    elapsedTimeLabel.removeFromParent()
                    restartLabel.removeFromParent()
                    
                    // Reset player node and add it back
                    playerNode.position = CGPoint(x: size.width / 2.0, y: 100)
                    playerNode.physicsBody?.isDynamic = false
                    addChild(playerNode)
                    
                    // Resume spawn action
                    let spawnAction = SKAction.repeatForever(SKAction.sequence([
                        SKAction.run {
                            if self.gameOver {
                                return
                            }
                            if Int.random(in: 0...100) < 95 {
                                self.addEnemy()
                            } else {
                                self.addPowerUp()
                            }
                        },
                        SKAction.wait(forDuration: spawnInterval)
                    ]))
                    run(spawnAction, withKey: "spawn")
                }
            } else {
                // Normal game touch behavior
                playerNode.position = location
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == enemyCategory | playerCategory {
            print("enemy")
            if let enemyNode = contact.bodyA.categoryBitMask == enemyCategory ? contact.bodyA.node : contact.bodyB.node {
                if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                    explosion.position = enemyNode.position
                    addChild(explosion)
                    explosionPlayer?.play()
                }
                enemyNode.removeFromParent()
            }
            score -= 1
        } else if collision == powerUpCategory | playerCategory {
            if let powerUpNode = contact.bodyA.categoryBitMask == powerUpCategory ? contact.bodyA.node : contact.bodyB.node {
                powerUpNode.removeFromParent()
                recoverPlayer?.play()
            }
            score += 1
        }
        
    }
    
}
