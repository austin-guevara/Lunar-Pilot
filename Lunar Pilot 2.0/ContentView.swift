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
    @StateObject private var gameScene = GameScene()
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
//                .frame(width: screenWidth, height: screenHeight, alignment: .center)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Label("\(Int(gameScene.fuelLevel))", systemImage: "fuelpump")
                    Spacer()
                    // Label("\(gameScene.crashCount)", systemImage: "burst")
                    Label("\(gameScene.levelCount)", systemImage: "heart")
                }
                .foregroundColor(.white)
                .padding()
                .font(Font.custom("SpaceMono-Bold", size: 16))
                Spacer()
                HStack {
                    Button {
                        gameScene.resetLevel()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    Spacer()
                    Button {
                        shouldShowSettings = true
                        gameScene.isPaused = true
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                    }
                    .sheet(isPresented: $shouldShowSettings) {
                        SettingsView(shouldShowSettings: $shouldShowSettings, gameScene: gameScene)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding()
            }
            .padding()
            .edgesIgnoringSafeArea(.all)
            .onAppear() {
                gameScene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                gameScene.scaleMode = .fill
                gameScene.backgroundColor = .black
            }
        }
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
    }
    
    struct SettingsView: View {
        @Binding var shouldShowSettings: Bool
        @ObservedObject var gameScene: GameScene

        var body: some View {
            Button("Press to dismiss") {
                shouldShowSettings = false
                gameScene.isPaused = false
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
