//
//  AudioPlayerView.swift
//  N3ON
//
//  Created by liam howe on 13/5/2025.
//

import SwiftUI
import AVFoundation
import Combine

struct AudioPlayerView: View {
    let url: URL
    @StateObject private var viewModel = AudioPlayerViewModel()
    @State private var isPulsing = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            // Pulse Visualization
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseScale)
                    .opacity(isPulsing ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: isPulsing)
                
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.purple)
            }
            
            // Playback Controls
            HStack(spacing: 30) {
                Button(action: viewModel.skipBackward) {
                    Image(systemName: "gobackward.10")
                        .font(.title)
                }
                
                Button(action: togglePlayback) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                }
                
                Button(action: viewModel.skipForward) {
                    Image(systemName: "goforward.10")
                        .font(.title)
                }
            }
            .foregroundColor(.white)
            
            // Progress Slider
            Slider(value: $viewModel.progress, in: 0...1)
                .padding(.horizontal)
                .accentColor(.purple)
                .disabled(!viewModel.isReady)
            
            // Time Labels
            HStack {
                Text(viewModel.currentTimeString)
                Spacer()
                Text(viewModel.durationString)
            }
            .padding(.horizontal)
            .font(.caption)
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(15)
        .onAppear {
            viewModel.loadAudio(url: url)
            startPulseAnimation()
        }
        .onDisappear {
            viewModel.stop()
            timer?.invalidate()
        }
    }
    
    private func togglePlayback() {
        viewModel.togglePlayback()
        if viewModel.isPlaying {
            startPulseAnimation()
        } else {
            timer?.invalidate()
        }
    }
    
    private func startPulseAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                isPulsing.toggle()
                pulseScale = isPulsing ? 1.5 : 1.0
            }
        }
    }
}

// MARK: - ViewModel
class AudioPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var isReady = false
    @Published var progress: Double = 0
    @Published var currentTimeString = "00:00"
    @Published var durationString = "00:00"
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    func loadAudio(url: URL) {
        player = AVPlayer(url: url)
        
        player?.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isReady = status == .readyToPlay
            }
            .store(in: &cancellables)
        
        player?.currentItem?.publisher(for: \.duration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] duration in
                guard duration.seconds > 0 else { return }
                self?.durationString = duration.formattedString
            }
            .store(in: &cancellables)
        
        setupPeriodicTimeObserver()
    }
    
    func togglePlayback() {
        guard isReady else { return }
        isPlaying ? pause() : play()
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func stop() {
        pause()
        player?.seek(to: .zero)
        progress = 0
    }
    
    func skipForward() {
        guard let currentTime = player?.currentTime() else { return }
        player?.seek(to: currentTime + CMTime(seconds: 10, preferredTimescale: 1))
    }
    
    func skipBackward() {
        guard let currentTime = player?.currentTime() else { return }
        player?.seek(to: currentTime - CMTime(seconds: 10, preferredTimescale: 1))
    }
    
    private func setupPeriodicTimeObserver() {
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            let duration = self.player?.currentItem?.duration.seconds ?? 1
            self.progress = time.seconds / duration
            self.currentTimeString = time.formattedString
        }
    }
}

// MARK: - Extensions
extension CMTime {
    var formattedString: String {
        guard !seconds.isNaN else { return "00:00" }
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview
struct AudioPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        AudioPlayerView(url: URL(string: "https://example.com/sample.mp3")!)
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.black)
    }
}
