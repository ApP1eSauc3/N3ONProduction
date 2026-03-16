// EventDetailView.swift
// N3ON
//

import SwiftUI
import Amplify

struct EventDetailView: View {
    @ObservedObject var vm: EventViewModel
    @EnvironmentObject var userState: UserState
    
    var ticketTypes: [TicketType] = []
    @State private var selectedTicketID: String?
    @State private var showError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                if let key = vm.event.posterKey {
                    AsyncStorageImage(storageKey: key)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                } else {
                    Color.gray.opacity(0.3).frame(height: 200)
                }

                Text(vm.event.eventName).font(.title.bold())
                Text(vm.formattedDate).foregroundColor(.secondary)

                TicketSelectionView(
                    ticketTypes: ticketTypes,
                    selectedTicketID: $selectedTicketID
                )

                if vm.isSoldOut {
                    Text("Sold Out").foregroundColor(.red).font(.headline)
                }

                HStack {
                    Button("Purchase") {
                        Task { await vm.handlePurchase(ticketID: selectedTicketID) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        vm.isLoading ||
                        vm.isSoldOut ||
                        (!ticketTypes.isEmpty && selectedTicketID == nil)
                    )

                    if vm.isLoading { ProgressView() }
                    Button("Share") { vm.shareEvent() }
                }
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .onChange(of: vm.errorMessage) { message in
            showError = message != nil
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}
