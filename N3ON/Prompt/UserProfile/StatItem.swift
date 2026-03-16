//
//  StatItem.swift
//  N3ON
//
//  Created by liam howe on 20/4/2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

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

enum QRCodeGenerator {
    static func generate(from text: String) -> UIImage? {
        let ctx = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}


struct StatItem_Previews: PreviewProvider {
    static var previews: some View {
        StatItem(value: 1500, label: "Followers")
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
    }
}
