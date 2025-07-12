//
//  PostFeedView.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI

struct PostFeedView: View {
    let posts: [Post]
    @State private var selectedPost: Post?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(posts) { post in
                    PostView(post: post)
                        .onTapGesture { selectedPost = post }
                }
            }
        }
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post) // Create this view for fullscreen viewing
        }
    }
}
