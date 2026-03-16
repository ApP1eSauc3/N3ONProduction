//
//  PhotoSelectionGrid.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import SwiftUI

struct PhotoSelectionGrid: View {
    @Binding var selectedImages: [UIImage]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(selectedImages, id: \.self) { image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                if let index = selectedImages.firstIndex(of: image) {
                                    selectedImages.remove(at: index)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .offset(x: 8, y: -8)
                        }
                }
            }
        }
        .frame(minHeight: selectedImages.isEmpty ? 0 : 90)
    }
}
