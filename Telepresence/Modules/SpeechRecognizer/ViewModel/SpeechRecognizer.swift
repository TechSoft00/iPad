//
//  SpeechRecognizer.swift
//  Telepresence
//
//  Created by Ditmar Jubica on 2/3/25.
//

import Foundation
import Speech
import AVFoundation

/// `SpeechRecognizer` is an observable object that handles speech-to-text transcription using Apple's Speech framework.
class SpeechRecognizer: ObservableObject {
    
    /// The speech recognizer responsible for processing speech input.
    let speechRecognizer = SFSpeechRecognizer()
    
    /// The audio engine used to capture and process audio from the device's microphone.
    let audioEngine = AVAudioEngine()
    
    /// A request object that handles real-time speech recognition.
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// The active speech recognition task.
    var recognitionTask: SFSpeechRecognitionTask?
    
    /// A published property indicating whether speech recognition is currently active.
    @Published var isRecording = false
    
    /// Repository for handling video data fetching.
    private let repository: VideoRepositoryProtocol
    
    /// A published list of `Videos` fetched from the repository.
    @Published var videos: [Videos] = []
    
    var isMainVideoPlaying: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes the `SpeechRecognizer` with a video repository.
    /// - Parameter repository: An instance of `VideoRepositoryProtocol` (default is `VideoRepository`).
    init(repository: VideoRepositoryProtocol = VideoRepository()) {
        self.repository = repository
        requestPermission()
    }
    
    func getFaceDetetcionVideo() -> URL? {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(UserDefaults.standard.value(forKey: "faceDetectionVideoURL") as! String)
        return fileURL
    }
    
    // MARK: - Video Fetching
    
    /// Fetches videos that are marked to be displayed on the home screen.
    func fetchHomeVideos() {
        videos = repository.fetchVideos(showOnHome: true)
    }
    
    /// Fetches a video based on the spoken text.
    /// - Parameter text: The recognized speech text used for video matching.
    /// - Returns: A `Videos` object if a match is found, otherwise `nil`.
    func fetchVideoOnSpeech(text: String) -> Videos? {
        print(text)
        let video = repository.fetchVideo(matching: text)
        print(video?.keyword ?? "")
        return video
    }
    
    // MARK: - Speech Recognition
    
    /// Starts transcribing the user's speech and provides the transcribed text via a completion handler.
    /// - Parameter completion: A closure that receives the transcribed text.
    func startTranscribing(completion: @escaping (String) -> Void) {
        
        
        // Create a new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        
        // Get the recording format for the input node
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("Audio Format: Sample Rate \(recordingFormat.sampleRate), Channels \(recordingFormat.channelCount)")
        
        // Ensure the input format is valid
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            print("Invalid audio format")
            return
        }
        
        // Enable partial results for real-time transcription
        recognitionRequest?.shouldReportPartialResults = true
        
        // Start the recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                let bestString = result.bestTranscription.formattedString
                completion(bestString)
            }
        }
        
        // ✅ Ensure that any existing audio tap is removed before setting a new one
        inputNode.removeTap(onBus: 0)
        
        // Install a tap on the audio engine input node to capture microphone input
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)
        }
        
        // Prepare and start the audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
        }
    }
    
    /// Stops the ongoing speech recognition and resets the audio engine.
    func stopTranscribing(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.audioEngine.stop()
            self.audioEngine.inputNode.removeTap(onBus: 0)
            
            self.recognitionRequest?.endAudio()
            self.recognitionTask?.cancel()
            
            self.recognitionRequest = nil
            self.recognitionTask = nil
            self.isRecording = false

            print("Speech recognition stopped.")
            completion?() // Execute any action after stopping
        }
    }
    
    // MARK: - Permissions
    
    /// Requests permission from the user to access speech recognition.
    private func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .authorized:
                break
            default:
                print("Speech recognition permission denied")
            }
        }
    }
}
