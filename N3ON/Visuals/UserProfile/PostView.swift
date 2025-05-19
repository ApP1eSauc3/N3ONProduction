//
//  PostView.swift
//  N3ON
//
//  Created by liam howe on 12/5/2025.
//

import SwiftUI
import AVFoundation

struct PostView: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TabView{
                ForEach(Array(zip(post.urls, post.types)), id: \.self.0) { url, type in
switch type {
                case .image:
                    AsyncImage(url: url)
{ image in
image.resizable().scaledToFill()
} placeholder: {
ProgressView()
            }
case .video:
                VideoPlayer(player: AVPlayer(url: url))
                    
case .audio:
AudioPlayerView(url: url)
      }
    }
}
.frame(height: 250)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            Text(post.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.bottom)
    }
}
