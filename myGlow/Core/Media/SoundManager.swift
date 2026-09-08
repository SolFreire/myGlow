//
//  SoundManager.swift
//  myGlow
//
//  Created by marquiros on 07/09/26.
//

import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var soundEffectPlayer: AVAudioPlayer?
    private var backgroundPlayer: AVAudioPlayer?
    
    func playSoundEffect(named soundName: String) {
        if let url = Bundle.main.url(forResource: soundName, withExtension: ".mp3") {
            do {
                soundEffectPlayer = try AVAudioPlayer(contentsOf: url)
                soundEffectPlayer?.play()
            } catch {
                print(error.localizedDescription)
            }
        }
        else {
            print("error loading sound \(soundName).mp3")
        }
    }
    
    func playBackgroundMusic(isOn: Bool) {
        if isOn {
            if let url = Bundle.main.url(forResource: "background-music", withExtension: ".wav") {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                    backgroundPlayer = try AVAudioPlayer(contentsOf: url)
                    backgroundPlayer?.numberOfLoops = -1
                    backgroundPlayer?.volume = 0.5
                    backgroundPlayer?.play()
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        else {
            backgroundPlayer?.stop()
        }
    }
}



