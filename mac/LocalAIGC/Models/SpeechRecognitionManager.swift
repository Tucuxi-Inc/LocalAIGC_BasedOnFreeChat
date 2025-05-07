import Foundation
import Speech
import AVFoundation
import os.log
import Cocoa

class SpeechRecognitionManager: NSObject, ObservableObject {
    private let logger = Logger(subsystem: "ai.tucuxi.LocalAIGC", category: "SpeechRecognition")
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()

    // Used only to prompt mic-permission dialog once
    private var captureSession: AVCaptureSession?

    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var isAuthorized = false
    @Published var errorMessage = ""
    @Published var showErrorAlert = false

    override init() {
        super.init()
        logger.info("SpeechRecognitionManager init")
        requestMicrophonePermission()
    }

    // MARK: – Mic Permission

    private func requestMicrophonePermission() {
        // Kick off a minimal capture session to trigger the mic-permission dialog
        captureSession = AVCaptureSession()
        guard
            let audioDevice = AVCaptureDevice.default(for: .audio),
            let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
            captureSession!.canAddInput(audioInput)
        else {
            logger.warning("No audio device or cannot add input")
            requestSpeechRecognitionPermission()
            return
        }

        captureSession!.addInput(audioInput)
        captureSession!.startRunning()
        logger.info("Started AVCaptureSession to prompt mic permission")

        // Request system mic access
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            guard let self = self else { return }
            self.logger.info("Microphone access granted: \(granted)")
            DispatchQueue.main.async {
                // Stop and clear captureSession so AVAudioEngine can use the mic
                self.captureSession?.stopRunning()
                self.captureSession = nil

                if granted {
                    self.requestSpeechRecognitionPermission()
                } else {
                    self.showError("Microphone access denied. Please enable it in System Settings > Privacy & Security > Microphone.")
                    self.openMicrophonePrivacySettings()
                }
            }
        }
    }

    private func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.isAuthorized = true
                    self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
                    self.logger.info("Speech recognition authorized")
                default:
                    self.isAuthorized = false
                    self.logger.warning("Speech recognition not authorized: \(status.rawValue)")
                    self.showError("Speech recognition not authorized. Please enable it in System Settings > Privacy & Security > Speech Recognition.")
                }
            }
        }
    }

    private func openMicrophonePrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: – Recording

    func startRecording() {
        if audioEngine.isRunning {
            stopRecording()
            return
        }

        guard isAuthorized, let recognizer = speechRecognizer, recognizer.isAvailable else {
            showError("Speech recognizer is not available on this device.")
            return
        }

        // Clear previous
        recognitionTask?.cancel()
        recognitionTask = nil
        transcribedText = ""

        // Create request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else {
            showError("Failed to create speech recognition request.")
            return
        }
        request.shouldReportPartialResults = true

        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcript = result.bestTranscription.formattedString
                DispatchQueue.main.async { self.transcribedText = transcript }
                self.logger.info("Partial transcription: \(transcript)")
            }

            if let err = error as NSError? {
                // Ignore benign errors
                let ignoreDomains = ["kLSRErrorDomain", "kAFAssistantErrorDomain"]
                let ignoreCodes = [301, 1101]
                if !(ignoreDomains.contains(err.domain) && ignoreCodes.contains(err.code)) {
                    self.logger.error("Recognition error: \(err.localizedDescription)")
                    if err.code == 1110 {
                        self.showError("No speech detected. Please speak clearly and try again.")
                    } else if self.audioEngine.isRunning {
                        self.showError("Speech recognition error: \(err.localizedDescription)")
                    }
                }
                // Stop on error
                self.stopRecording()
            } else if result?.isFinal == true {
                self.stopRecording()
            }
        }

        // Install audio tap on engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        // Start audio engine
        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            logger.info("Audio engine started, begin speech recognition")
        } catch {
            logger.error("AudioEngine start error: \(error.localizedDescription)")
            showError("Failed to start audio recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil

        DispatchQueue.main.async {
            self.isRecording = false
            self.logger.info("Recording stopped: final transcription: \(self.transcribedText)")
        }
    }

    // MARK: – Error Handling

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showErrorAlert = true
            self.logger.error("User error: \(message)")
        }
    }
} 