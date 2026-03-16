//
//  DJPinView.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import SwiftUI

struct DJPinView: View {
    let dj: DJ
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "music.note")
                .foregroundColor(.white)
                .padding(8)
                .background(
                    Circle()
                        .fill(dj.isFollowedByCurrentUser ? Color.purple : Color.gray)
                )
            
            Text(dj.name)
                .font(.caption2)
                .padding(4)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
                .foregroundColor(.white)
        }
    }
}
