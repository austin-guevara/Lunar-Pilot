//
//  ContentView.swift
//  Lunar Pilot 2.0
//
//  Created by Austin Guevara on 6/27/23.
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    
    @State private var shouldShowSettings = false
    
    @State private var shouldResetLevel = false
    @State private var gameIsPaused = false
    @State private var fuelLevel: CGFloat = 100
    @State private var crashCount = 0
    @State private var levelCount = 1
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    var scene: SKScene {
        let scene = GameScene($shouldResetLevel, gameIsPaused: $gameIsPaused, fuelLevel: $fuelLevel, crashCount: $crashCount, levelCount: $levelCount)
        scene.size = CGSize(width: screenWidth, height: screenHeight)
        
        scene.scaleMode = .fill
        scene.backgroundColor = .black
        
        scene.isPaused = gameIsPaused
        
        return scene
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .frame(width: screenWidth, height: screenHeight, alignment: .center)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Label("\(Int(fuelLevel))", systemImage: "fuelpump")
                    Spacer()
                    Label("\(crashCount)", systemImage: "burst")
                }
                .foregroundColor(.white)
                .padding()
                .font(Font.custom("SpaceMono-Bold", size: 16))
                Spacer()
                HStack {
                    Button {
                        shouldResetLevel = true
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    Spacer()
                    Button {
                        gameIsPaused = true
                        shouldShowSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                    }
                    .sheet(isPresented: $shouldShowSettings) {
                        // For some reason, when this is called, it is also re-initializing the whole GameScene
                        // This is a problem because it re-draws the level, resets the score, etc...
                        // We only want it to pause the game
                        SettingsView(gameIsPaused: $gameIsPaused, shouldShowSettings: $shouldShowSettings)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding()
            }
            .padding()
            .edgesIgnoringSafeArea(.all)
        }
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
    }
    
    struct SettingsView: View {
        @Binding var gameIsPaused: Bool
        @Binding var shouldShowSettings: Bool

        var body: some View {
            Button("Press to dismiss") {
                shouldShowSettings = false
                gameIsPaused = false
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
