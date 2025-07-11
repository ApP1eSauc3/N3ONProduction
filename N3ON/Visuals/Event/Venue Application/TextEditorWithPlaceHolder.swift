//
//  TextEditorWithPlaceHolder.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import SwiftUI

struct TextEditorWithPlaceholder: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(.placeholderText))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
            }
            
            TextEditor(text: $text)
                .frame(minHeight: 100)
                .opacity(text.isEmpty ? 0.85 : 1)
        }
    }
}
