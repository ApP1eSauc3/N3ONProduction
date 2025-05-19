//
//  StatItem.swift
//  N3ON
//
//  Created by liam howe on 20/4/2025.
//

import SwiftUI

struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.medium)
                .contentTransition(.numericText())
            
            Text(label)
                .font(.system(.caption, design: .rounded))
                .opacity(0.9)
        }
        .foregroundColor(.white)
        .accessibilityElement(children: .combine)
    }
}

struct StatItem_Previews: PreviewProvider {
    static var previews: some View {
        StatItem(value: 1500, label: "Followers")
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
    }
}
