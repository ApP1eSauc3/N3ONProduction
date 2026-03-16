// PostFeedView.swift
// N3ON
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
            PostDetailView(post: post)
        }
    }
}

// MARK: - PostDetailView stub
// TODO: Replace with real fullscreen post viewer.
// Needs: paged media display, caption, timestamp, owner info, like/comment actions.
// Kept minimal here so PostFeedView compiles — do not ship this as-is.
struct PostDetailView: View {
    let post: Post

    var body: some View {
        NavigationStack {
            PostView(post: post)
                .padding()
                .navigationTitle("Post")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
