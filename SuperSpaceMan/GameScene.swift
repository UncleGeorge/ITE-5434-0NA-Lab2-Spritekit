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
    
    // move to left by 0, value 1
    let enemyCategory: UInt32 = 0x1 << 0
    // move to left by 1, value 2
    let powerUpCategory: UInt32 = 0x1 << 1
    // move to left by 2, value 4
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
        
        // Executed when the value of score changes
        didSet {
            // update scoreLabel
            scoreLabel.text = "Score: \(score)"
            
            // when game is over
            if score == 0 {
                
                gameOver = true
                
                // Calculate the duration of the game just finished
                let elapsedTime = Date().timeIntervalSince(startTime!)
                
                // Place "Game Over" label in the center of the game scene
                gameOverLabel.text = "GAME OVER"
                gameOverLabel.position = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
                addChild(gameOverLabel)
                
                // Place "Survival Time" label under the previous label
                elapsedTimeLabel.text = String(format: "Survival Time: %.3f seconds", elapsedTime)
                elapsedTimeLabel.fontSize = 20
                elapsedTimeLabel.position = CGPoint(x: size.width / 2.0, y: size.height / 2.0 - gameOverLabel.frame.size.height - 10)
                addChild(elapsedTimeLabel)
                
                // Place "Play Again" label under the previous label
                restartLabel.text = "Tap Here to Play Again"
                restartLabel.fontSize = 20
                restartLabel.position = CGPoint(x: size.width / 2.0, y: size.height / 2.0 - gameOverLabel.frame.size.height - elapsedTimeLabel.frame.size.height - 30)
                addChild(restartLabel)
                
                // show explosion of player and remove player
                if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                    explosion.position = playerNode.position
                    addChild(explosion)
                }
                playerNode.removeFromParent()
                
                // Stop spawning enemies and powerups
                removeAction(forKey: "spawn")
            }
        }
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        // start the timer
        startTime = Date()
        
        // Increase game difficulty at regular intervals
        startDifficultyTimer()
        
        // Set delegate
        physicsWorld.contactDelegate = self
        // Set gravity
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -1.8)
        
        // Add background node
        backgroundNode.position = CGPoint(x: size.width / 2.0, y: 0.0)
        backgroundNode.zPosition = -1
        backgroundNode.size.width = frame.size.width
        backgroundNode.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        addChild(backgroundNode)
        
        // Add player node
        playerNode.position = CGPoint(x: size.width / 2.0, y: 200)
        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: playerNode.size.width/2)
        
        // Let the player not be affected by physics engine, tap on screen to control its position
        playerNode.physicsBody?.isDynamic = false
        playerNode.physicsBody?.categoryBitMask = playerCategory
        
        // contact with an enemy or powerUp, contact method didBegin will be triggered
        playerNode.physicsBody?.contactTestBitMask = enemyCategory | powerUpCategory
        addChild(playerNode)
        
        // Add score label
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 20
        scoreLabel.position = CGPoint(x: size.width - 80, y: size.height - 80)
        addChild(scoreLabel)
        
        // Load audio file
        if let explosionURL = Bundle.main.url(forResource: "explosion", withExtension: "mp3"),
           let recoverURL = Bundle.main.url(forResource: "recover", withExtension: "wav"),
           let backgroundMusicURL = Bundle.main.url(forResource: "JeremyBlakePowerup", withExtension: "mp3"){
            do {
                explosionPlayer = try AVAudioPlayer(contentsOf: explosionURL)
                recoverPlayer = try AVAudioPlayer(contentsOf: recoverURL)
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: backgroundMusicURL)
                // The original explosion was too loud, turn down the volume
                explosionPlayer?.volume = 0.5
                // Looping of background music
                backgroundMusicPlayer?.numberOfLoops = -1
                backgroundMusicPlayer?.play()
            } catch {
                // Couldn't load file, print error
                print("Couldn't load audio files, error: \(error)")
            }
        }
        
        startSpawnAction()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addEnemy() {
        let enemyNode = SKSpriteNode(imageNamed: "BlackHole0")
        // Spawn at a random position above the screen
        enemyNode.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + 100)
        enemyNode.physicsBody = SKPhysicsBody(circleOfRadius: enemyNode.size.width/2)
        enemyNode.physicsBody?.isDynamic = true
        enemyNode.physicsBody?.categoryBitMask = enemyCategory
        enemyNode.physicsBody?.contactTestBitMask = playerCategory
        
        // After the enemy drops to -100, it is removed
        enemyNode.run(SKAction.sequence([
            SKAction.moveTo(y: -100, duration: enemySpeed),
            SKAction.removeFromParent()
        ]))
        
        // Add emitter to enemies
        if let flame = SKEmitterNode(fileNamed: "Flame") {
            flame.position = CGPoint(x: 0, y: -enemyNode.size.height/5)
            enemyNode.addChild(flame)
        }
        
        addChild(enemyNode)
    }
    
    func addPowerUp() {
        let powerUpNode = SKSpriteNode(imageNamed: "PowerUp")
        // Spawn at a random position above the screen
        powerUpNode.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + 100)
        powerUpNode.physicsBody = SKPhysicsBody(circleOfRadius: powerUpNode.size.width/2)
        powerUpNode.physicsBody?.isDynamic = true
        powerUpNode.physicsBody?.categoryBitMask = powerUpCategory
        powerUpNode.physicsBody?.contactTestBitMask = playerCategory
        
        // After the powerUp drops to -100, it is removed
        powerUpNode.run(SKAction.sequence([
            SKAction.moveTo(y: -100, duration: powerUpSpeed),
            SKAction.removeFromParent()
        ]))
        
        // Add emitter to powerUp
        if let fountain = SKEmitterNode(fileNamed: "Fountain") {
            fountain.position = CGPoint(x: 0, y: powerUpNode.size.height/5)
            powerUpNode.addChild(fountain)
        }
        
        addChild(powerUpNode)
    }
    
    func updateGameDifficulty() {
        spawnInterval *= 0.93
        enemySpeed *= 0.95
        powerUpSpeed *= 0.95
    }
    
    
    
    // Increase game difficulty at regular intervals
    func startDifficultyTimer() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if self.gameOver {
                timer.invalidate()
            } else {
                self.updateGameDifficulty()
            }
        }
    }
    
    func startSpawnAction(){
        // The sequence repeat in an endless loop
        let spawnAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run {
                // Stop spawning after the game over
                if self.gameOver {
                    return
                }
                // 95% chance to spawn an enemy, 5% chance to spawn a powerUp
                if Int.random(in: 0...100) < 95 {
                    self.addEnemy()
                } else {
                    self.addPowerUp()
                }
            },
            // Time interval between spawns
            SKAction.wait(forDuration: spawnInterval)
        ]))
        // Applies the spawnAction, and provides an key for the action
        run(spawnAction, withKey: "spawn")
    }
    
    // Update the position of the player to the position of the current touch point
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
                // Determine whether the position of the touch point is within restartLabel
                if restartLabel.contains(location) {
                    
                    // Restart new game logic
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
                    
                    // Reset player node
                    playerNode.position = CGPoint(x: size.width / 2.0, y: 100)
                    playerNode.physicsBody?.isDynamic = false
                    addChild(playerNode)
                    
                    // Resume spawn action
                    startSpawnAction()
                }
            } else {
                // Normal game touch behavior
                playerNode.position = location
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // performing a bitwise OR operation on the categoryBitMasks of two physics bodies
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // The player collides with an enemy
        if collision == enemyCategory | playerCategory {
//            print("enemy")
            // Know which of bodyA and bodyB is the enemy
            if let enemyNode = contact.bodyA.categoryBitMask == enemyCategory ? contact.bodyA.node : contact.bodyB.node {
                
                // play explosion particle effects
                if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                    explosion.position = enemyNode.position
                    addChild(explosion)
                    explosionPlayer?.play()
                }
                enemyNode.removeFromParent()
            }
            score -= 1
        // Player collides with a powerUp
        } else if collision == powerUpCategory | playerCategory {
            // Know which of bodyA and bodyB is the powerUp
            if let powerUpNode = contact.bodyA.categoryBitMask == powerUpCategory ? contact.bodyA.node : contact.bodyB.node {
                powerUpNode.removeFromParent()
                recoverPlayer?.play()
            }
            score += 1
        }
        
    }
    
}
