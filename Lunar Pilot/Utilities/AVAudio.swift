//
//  Audio.swift
//  Lunar Pilot
//
//  Created by Austin Guevara on 6/28/23.
//

import AVFoundation

class AVAudio {
    
    func makeSound(fileNamed fileName: String) -> AVAudioPlayer? {
        let path = Bundle.main.path(forResource: fileName, ofType:nil)!
        let url = URL(fileURLWithPath: path)

        do {
            let soundEffect = try AVAudioPlayer(contentsOf: url)
            return soundEffect
            // bombSoundEffect?.play()
        } catch {
            // couldn't load file :(
        }
        return nil
    }
    
//    var audioPlayer: AVAudioPlayer!
//
//    func playSound(_ soundFileName: String) {
//        guard let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: nil) else {
//            fatalError("Unable to find \(soundFileName) in bundle")
//        }
//
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
//        } catch {
//            print(error.localizedDescription)
//        }
//        audioPlayer.play()
//    }
}
