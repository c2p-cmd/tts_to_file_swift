//: A UIKit based Playground for presenting user interface
  
import AVFoundation
import PlaygroundSupport

let utterance = AVSpeechUtterance(string: "ओम् त्र्यंबकम यजामहे सुगंधीम् पुष्टीवर्धनम् उर्वारुकमिवा बंधनान-मृत्योरमुखेय मामृतात्")
utterance.voice = AVSpeechSynthesisVoice(language: "hi-IN")
utterance.pitchMultiplier = 0.5
utterance.rate = 0.1

let synthesizer = AVSpeechSynthesizer()
//synthesizer.speak(utterance)

let url = URL.documentsDirectory.appending(path: "mahamrutyunjaya_mantra.wav")
print(url)
var avFile: AVAudioFile? = nil

try? FileManager.default.removeItem(at: url)
synthesizer.write(utterance) { buffer in
    print(buffer.format)
    guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
        print("Invalid type for \(buffer)")
        return
    }
    print(pcmBuffer.frameLength)
    if pcmBuffer.frameLength != 0 {
        do {
            if avFile == nil {
                avFile = try AVAudioFile(forWriting: url, settings: pcmBuffer.format.settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            }
            try avFile?.write(from: pcmBuffer)
        } catch {
            print(error)
        }
    }
    print(avFile?.url.description ?? "---")
//    try avFile.write(from: buffer)
}
