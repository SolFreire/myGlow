//
//  SoundManager.swift
//  myGlow
//
//  Created by marquiros on 07/09/26.
//

import AVFoundation
import Foundation

class SoundManager {

    static let shared = SoundManager()

    private var soundEffectPlayer: AVAudioPlayer?
    private var backgroundPlayer: AVAudioPlayer?

    init() {
        UserDefaults.standard.register(defaults: [
            "efeitosSonorosLigados": true,
            "musicaLigada": true
        ])
    }

    func playSoundEffect(named soundName: String) {
        guard somLigado else { return }

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
                    soundEffectPlayer = try AVAudioPlayer(contentsOf: url)
                    soundEffectPlayer?.play()
                } catch {
                    print(error.localizedDescription)
                }

            } else {
                print("Erro carregando \(soundName).mp3")
            }
        }
    }

    func playBackgroundMusic(isOn: Bool) {

        if isOn {

            if backgroundPlayer?.isPlaying == false || backgroundPlayer == nil {

                if let url = Bundle.main.url(
                    forResource: "background-music",
                    withExtension: "wav"
                ) {

                    do {
                        try AVAudioSession.sharedInstance().setCategory(
                            .ambient,
                            options: [.mixWithOthers]
                        )

                        try AVAudioSession.sharedInstance().setActive(true)

                        backgroundPlayer = try AVAudioPlayer(contentsOf: url)

                        backgroundPlayer?.numberOfLoops = -1
                        backgroundPlayer?.volume = 0.5
                        backgroundPlayer?.play()

                    } catch {
                        print(error.localizedDescription)
                    }

                } else {
                    print("Erro carregando background-music.wav")
                }
            }

        } else {
            backgroundPlayer?.stop()
        }
    }
}



