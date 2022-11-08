//
//  ADTFuncs.swift
//  POC_Audiotoolbox
//
//  Created by Caio Soares on 07/11/22.
//

import Foundation
import AudioToolbox
import AVFoundation

struct Instrument {
    var LSB:        Int // que caralhos é isso
    var MSB:        Int // ditto
    var name:       String  // nome do instrumento
    var program:    Int     // código interno do instrumento dentro da Soundfont. Estamos usando a GeneralUser GS MuseScore v1.442.sf2
}

final class Services {
    
    static var sequencer = AVAudioSequencer()
    
    static func buildInstrument() {
        
        guard let bankURL = Bundle.main.url(forResource: "Soundfont", withExtension: "sf2") else {   // Tem que ir em build phases
            print("didnt managed to open the sf2 file :c")                                           // copy bundle resources e
            return                                                                                   // add a porra da soundfont
        }
        var instruments = [Instrument]()
        var instrumentsInfo: Unmanaged<CFArray>?    // what kind of wizardry is this
        
        CopyInstrumentInfoFromSoundBank(bankURL as CFURL, &instrumentsInfo) // essa func é a da audio tool box. basicamente estamos chamando ela para copiar os dados contidos em bankURL para o !!PONTEIRO!! de instrument info. are you proud mateus rodrigues
        
        let instrInfo = instrumentsInfo!.takeRetainedValue() as! NSArray    // what the actual fuck. acho que isso é para transformar os valores crus, raws, dentro de instrumentInfo para instrInfo. Estamos transformando isso em um valores.
        
        for i in instrInfo {
            let lsb = (i as! NSDictionary).value(forKey: "LSB") as! Int
            let msb = (i as! NSDictionary).value(forKey: "MSB") as! Int
            let name = (i as! NSDictionary).value(forKey: "name") as! String
            let program = (i as! NSDictionary).value(forKey: "program") as! Int
                
            let instrument = Instrument(LSB: lsb, MSB: msb, name: name, program: program)
                
            instruments.append(instrument)
            
            // resumindo a opera: todos os instrumentos são populados em runtime, evitando que a gente tente usar um instrumento e ele acabe não rodando. a situação aqui é o que permite que a gente, por exemplo, consiga trocar de instrumento mid chamada.
        }
        
        print(instrInfo)
        
        // a partir desse momento o código é dependente exclusivamente do instrumento escolhido
        
        let sampler  = AVAudioUnitSampler() // objeto configurável para servir um instrumento baseado em uma unidade de áudio - otávio
        
        try! sampler.loadSoundBankInstrument(
            at: bankURL,                                        // a sample enviada da soundfont
            program: 24,                                        // o programa enumerado pela soundfound
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),   // most significant beat. o limite superior do instrumento
            bankLSB: UInt8(kAUSampler_DefaultBankLSB)           // least significant beat. o limite inferior do instrumento
        )
        
        let engine = AVAudioEngine()
        
        // testar com mais de um sampler attacheado
        
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        try! engine.start()
        
        sequencer = AVAudioSequencer(audioEngine: engine)
        
        var sequence: MusicSequence!
        _ = NewMusicSequence(&sequence)

        var track: MusicTrack!
        _ = MusicSequenceNewTrack(sequence, &track)
        
        let scale = [2, 2, 1, 2]
        // sobe x escalas e desce x escalas

        let c = 60
        // nota base da escala base

        var notes = [Int]()
        // inicializa o vetor de notas que serão tocadas

        notes.append(c)
        // coloca o 60 no valor vazio recem inicializado
        
        scale.enumerated().forEach { (index, interval) in
            let note = notes[index] + interval
            notes.append(note)
        }
        
        var time: MusicTimeStamp = 0.0

        for note in notes {
            var message = MIDINoteMessage(
                channel: 0,
                note: UInt8(note),
                velocity: 64,
                releaseVelocity: 1,
                duration: 1.0
            )
            _ = MusicTrackNewMIDINoteEvent(track, time, &message)
            time += 1
        }

        var output: Unmanaged<CFData>?

        _ = MusicSequenceFileCreateData(
            sequence,
            .midiType,
            .eraseFile,
            480,
            &output
        )

        var data = output!.takeUnretainedValue() as Data

        output?.release()

        do {
            try sequencer.load(from: data, options: AVMusicSequenceLoadOptions())
            print("sequenced  yo")
        } catch {
            fatalError()
        }

        sequencer.prepareToPlay()

        do {
            try sequencer.start()
            print("tried playing yo")
        } catch {
            fatalError()
        }

        
    }
    
}
