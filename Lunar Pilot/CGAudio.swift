//
//  Audio.swift
//  Lunar Pilot 2.0
//
//  Created by Austin Guevara on 6/28/23.
//

import AVFoundation

class CGAudio {
    
    var audioPlayer: AVAudioPlayer!
    
    func playSound(_ soundFileName : String) {
        guard let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: nil) else {
            fatalError("Unable to find \(soundFileName) in bundle")
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
        } catch {
            print(error.localizedDescription)
        }
        audioPlayer.play()
    }
}
