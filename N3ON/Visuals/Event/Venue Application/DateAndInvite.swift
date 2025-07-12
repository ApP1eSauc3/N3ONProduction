//
//  DateAndInvite.swift
//  N3ON
//
//  Created by liam howe on 12/7/2025.
//

import SwiftUI

struct DateAndInviteStep: View {
    @Binding var date: Date
    @Binding var invitedDJs: [String]
    @Binding var selectedVJ: String?

    var body: some View {
        VStack(spacing: 20) {
            DatePicker("Event Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(GraphicalDatePickerStyle())

            InviteSearchBar(title: "Invite DJs", entries: $invitedDJs)
            InviteSearchBar(title: "Select VJ", entries: Binding(get: {
                selectedVJ.map { [$0] } ?? []
            }, set: { selectedVJ = $0.first }))
        }
    }
}
