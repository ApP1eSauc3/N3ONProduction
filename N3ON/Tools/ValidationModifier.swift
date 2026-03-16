//
//  ValidationModifier.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import SwiftUI

struct ValidationModifier: ViewModifier {
    let condition: Bool
    let message: String
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content
            
            if condition {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
                    .transition(.opacity)
            }
        }
    }
}
extension View {
    func validation(_ condition: Bool, _ message: String) -> some View {
        modifier(ValidationModifier(condition: condition, message: message))
    }
}
