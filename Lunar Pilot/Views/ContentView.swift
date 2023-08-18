//
//  ContentView.swift
//  Lunar Pilot
//
//  Created by Austin Guevara on 6/27/23.
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    
    // Need to wait for iOS 17
    // @Bindable var player: Player
    @State private var highScore: Int = 0
    
    @State private var shouldPauseGame = true
    @State private var shouldPresentInstructions = false
    @State private var firstLoad = true
    @StateObject private var gameScene = GameScene()
    
    @State private var playerMessage: String = ""
    @State private var currentMessageIndex = 0
    @State private var typeWriterRunning = false
    
    private let messages = [
        "Greetings, Lunar Pilot! Your mission is to navigate the Lunar craft to the bottom of the canyon.",
        "The landing gear can safely bounce off the canyon walls. But be sure not to fall too hard, or collide with the canyon walls, or you’ll crash!",
        "Tap and hold on the left side of the screen to rotate left.",
        "Tap and hold on the right side of the screen to rotate right.",
        "Tap and hold on both sides of the screen simultaneously to engage thrusters.",
        "Good luck, pilot! Explore as many canyons as possible. In the name of science!"
    ]
    
    var body: some View {
        ZStack {
            
            // MARK: - GameScene
            SpriteView(scene: gameScene)
                .edgesIgnoringSafeArea(.all)
                .onAppear() {
                    gameScene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    gameScene.scaleMode = .fill
                    gameScene.backgroundColor = .black
                    // gameScene.livesCount = 1
                }
            
            // MARK: - Game Controls
            VStack {
                HStack {
                    Label("\(gameScene.levelCount)", systemImage: "flag")
                    Spacer()
                    Label("\(gameScene.livesCount)", systemImage: "heart")
                }
                .foregroundColor(.white)
                .padding()
                .font(Font.custom("SpaceMono-Bold", size: 16))
                Spacer()
                HStack {
                    Button {
                        gameScene.hardResetCraft()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(shouldPauseGame)
                    Spacer()
                    Button {
                        shouldPauseGame.toggle()
                        gameScene.isPaused = shouldPauseGame
                    } label: {
                        Image(systemName: shouldPauseGame ? "play" : "pause")
                            .foregroundColor(.white)
                    }
                    // .sheet(isPresented: $shouldShowSettings) {
                    //    SettingsView(shouldShowSettings: $shouldShowSettings, gameScene: gameScene)
                    // }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding()
            }
            .padding()
            .edgesIgnoringSafeArea(.all)
            
            // MARK: - Game Menu
            if shouldPauseGame {
                VStack(spacing: 12) {
                    Text(firstLoad ? "Lunar Pilot" : "Game Paused")
                        .font(Font.custom("SpaceMono-Bold", size: 24))
                    Text(highScore > 0 ? "High Score: \(highScore)" : "Play to set a high score!")
                    Button(firstLoad ? "Play Game" : "Resume Game") {
                        gameScene.isPaused = false
                        shouldPauseGame = false
                        
                        if firstLoad {
                            gameScene.createCraft()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                shouldPresentInstructions = true
                            }
                        }
                        
                        firstLoad = false
                    }
                    .font(Font.custom("SpaceMono-Bold", size: 16))
                    .padding([.top, .bottom], 4)
                    .padding([.leading, .trailing], 12)
                    .background(Color.black)
                    .border(Color.gray, width: 1)
                }
                .padding()
                .font(Font.custom("SpaceMono-Bold", size: 16))
                .background(Color.black)
                .foregroundColor(Color.white)
                .border(Color.white, width: 1)
                .onAppear() {
                    if firstLoad {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            gameScene.isPaused = true
                        }
                    }
                }
            }
            
            // MARK: - Pilot Instructions
            if shouldPresentInstructions && !shouldPauseGame {
                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text(playerMessage)
                            .onAppear() {
                                typeWriterRunning = true
                                typeWriter(withText: messages[0])
                            }
                        Text((currentMessageIndex + 1) == messages.count ? "Tap to Close" : "Tap to Continue")
                            .font(Font.custom("SpaceMono-Bold", size: 12))
                    }
                    .padding()
                    .font(Font.custom("SpaceMono-Bold", size: 16))
                    .background(Color.black)
                    .foregroundColor(Color.white)
                    .border(Color.white, width: 1)
                }
                .padding()
                .onAppear() {
                    gameScene.isPaused = true
                }
                .onTapGesture() {
                    if typeWriterRunning {
                        typeWriterRunning = false
                        return
                    }
                    if (currentMessageIndex + 1) <= messages.count {
                        currentMessageIndex += 1
                        if messages.indices.contains(currentMessageIndex) {
                            typeWriterRunning = true
                            typeWriter(withText: messages[currentMessageIndex])
                        } else {
                            shouldPresentInstructions = false
                            gameScene.isPaused = false
                        }
                    }
                }
                .zIndex(2)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
            }
            
            // MARK: - GameOver Message
            if gameScene.gameOver {
                VStack {
                    VStack(spacing: 12) {
                        Text("GAME OVER")
                        VStack {
                            Text("You made it to level \(gameScene.levelCount).")
                            Text(gameScene.levelCount > highScore ? "That’s a new high score!" : "Great attempt, pilot.")
                        }
                        .font(Font.custom("SpaceMono-Bold", size: 16))
                        Button("New Game") {
                            gameScene.resetGame()
                        }
                        .font(Font.custom("SpaceMono-Bold", size: 16))
                        .padding([.top, .bottom], 4)
                        .padding([.leading, .trailing], 12)
                        .background(Color.black)
                        .border(Color.gray, width: 1)
                    }
                    .padding()
                    .font(Font.custom("SpaceMono-Bold", size: 24))
                    .background(Color.black)
                    .foregroundColor(Color.white)
                    .border(Color.white, width: 1)
                }
                .padding()
                .onAppear() {
                    gameScene.isPaused = true
                    
                    if gameScene.levelCount > highScore {
                        highScore = gameScene.levelCount
                    }
                }
            }
        }
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
        .font(Font.custom("SpaceMono-Bold", size: 16))
    }
    
    private func typeWriter(withText finalText: String, at position: Int = 0) {
        if position == 0 {
            playerMessage = "█"
        }
        if position < finalText.count && typeWriterRunning {
            typeWriterRunning = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                let nextChar = String(finalText[position])
                playerMessage = playerMessage.dropLast() + nextChar + "█"
                typeWriter(withText: finalText, at: position + 1)
            }
        } else {
            typeWriterRunning = false
            playerMessage = finalText + "█"
        }
    }
    
    struct SettingsView: View {
        @Binding var shouldPauseGame: Bool
        @ObservedObject var gameScene: GameScene

        var body: some View {
            Button("Press to dismiss") {
                shouldPauseGame = false
                gameScene.isPaused = shouldPauseGame
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension String {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}
