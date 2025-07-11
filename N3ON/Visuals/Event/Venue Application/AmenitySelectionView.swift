//
//  AmenitySelectionView.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import SwiftUI

struct AmenitySelectionView: View {
    @Binding var selectedAmenities: [Amenity]
    
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Amenity.allCases, id: \.self) { amenity in
                Button {
                    if selectedAmenities.contains(amenity) {
                        selectedAmenities.removeAll(where: { $0 == amenity })
                    } else {
                        selectedAmenities.append(amenity)
                    }
                } label: {
                    HStack {
                        Image(systemName: amenity.iconName)
                        Text(amenity.rawValue.capitalized)
                            .font(.caption)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(
                        selectedAmenities.contains(amenity) ?
                        Color.blue.opacity(0.2) : Color.gray.opacity(0.1)
                    )
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedAmenities.contains(amenity) ? Color.blue : Color.gray, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .foregroundColor(selectedAmenities.contains(amenity) ? .blue : .primary)
            }
        }
        .padding(.vertical, 8)
    }
}
