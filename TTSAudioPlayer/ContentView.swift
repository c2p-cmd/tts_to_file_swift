//
//  ContentView.swift
//  TTSAudioPlayer
//
//  Created by Sharan Thakur on 30/06/24.
//

import AVFoundation
import SwiftUI

struct ContentView: View {
    @State private var vm = ViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Language Choice", selection: $vm.selectedLanguage) {
                    ForEach(LanguageChoice.allCases, id: \.self) {
                        Text($0.rawValue)
                            .tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(vm.isBusy)
                
                TextEditor(text: $vm.textInput)
#if os(iOS)
                    .textInputAutocapitalization(.sentences)
#endif
                    .textSelection(.enabled)
                    .disabled(vm.isBusy)
                    .fileExporter(
                        isPresented: $vm.showFileExporter,
                        item: vm.fileToExport,
                        defaultFilename: "recording_\(Date().ISO8601Format(.iso8601)).wav"
                    ) { result in
                        switch result {
                        case .success(_):
                            self.vm.avFile = nil
                        case .failure(let error):
                            print(error)
                            self.vm.error = String(describing: error)
                        }
                    }
                
                if vm.isBusy {
                    ProgressView()
                }
                
                Button("Text To Speech", action: vm.textToSpeech)
                    .disabled(vm.isBusy)
            }
            .alert("Problem!", isPresented: vm.showError, presenting: vm.error) { _ in
            } message: { error in
                Text(error)
            }
            .navigationTitle("Text To Speech Demo")
        }
    }
}

extension ContentView {
    @Observable
    class ViewModel {
        var error: String?
        var isBusy = false
        var textInput = ""
        var selectedLanguage: LanguageChoice = .eng
        
        var showFileExporter = false
        var fileToExport: Data?
        
        var avFile: AVAudioFile?
        var url = URL.documentsDirectory.appending(path: "recording_\(Date().ISO8601Format(.iso8601Date(timeZone: .current, dateSeparator: .dash))).wav")
        private let synthesizer = AVSpeechSynthesizer()
        
        var showError: Binding<Bool> {
            Binding {
                self.error != nil
            } set: { _ in
                self.error = nil
            }
        }
        
        func textToSpeech() {
            Task.init {
                if isBusy { return }
                
                self.fileToExport = nil
                isBusy = true
                self.showFileExporter = false
                let utterance = AVSpeechUtterance(string: textInput)
                utterance.voice = AVSpeechSynthesisVoice(
                    language: selectedLanguage.languageCode
                )
                utterance.pitchMultiplier = 0.5
                utterance.rate = 0.1
                
                synthesizer.write(utterance, toBufferCallback: bufferCallback(_:))
            }
        }
        
        private func bufferCallback(_ buffer: AVAudioBuffer) {
            print(buffer.format)
            guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                print("Invalid type for \(buffer)")
                return
            }
            print(pcmBuffer.frameLength)
            if pcmBuffer.frameLength > 1 {
                do {
                    if avFile == nil {
                        url = URL.documentsDirectory.appending(path: "recording_\(Date().ISO8601Format(.iso8601Date(timeZone: .current, dateSeparator: .dash))).wav")
                        avFile = try AVAudioFile(
                            forWriting: url,
                            settings: pcmBuffer.format.settings,
                            commonFormat: .pcmFormatFloat32,
                            interleaved: false
                        )
                    }
                    try avFile?.write(from: pcmBuffer)
                } catch {
                    print(error)
                    self.error = String(describing: error)
                }
            } else {
                isBusy = false
                do {
                    if let url = avFile?.url {
                        self.fileToExport = try Data(contentsOf: url)
                        self.showFileExporter = true
                    }
                } catch {
                    print(error)
                    self.error = String(describing: error)
                }
                print(avFile?.url.description ?? "---")
            }
        }
    }
}

enum LanguageChoice: String, CaseIterable {
    case eng = "English"
    case hi = "Hindi"
    
    var languageCode: String {
        switch self {
        case .eng:
            "en-IN"
        case .hi:
            "hi-IN"
        }
    }
}

#Preview {
    ContentView()
}
