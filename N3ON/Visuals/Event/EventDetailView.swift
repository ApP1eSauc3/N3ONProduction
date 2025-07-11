//
//  EventDetailView.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

struct EventDetailView: View {
    @ObservedObject var vm: EventViewModel
    @EnvironmentObject var userState: UserState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                AsyncImage(url: vm.event.imageURL) { phase in
                    // Image loading states
                }
                .frame(height: 200)
                
                // Info
                Text(vm.event.name).font(.title.bold())
                Text(vm.formattedDate).foregroundColor(.secondary)
                
                // Tickets
                TicketSelectionView(ticketTypes: vm.event.ticketTypes ?? [])
                
                // Action Buttons
                HStack {
                    Button("Purchase") { vm.handlePurchase() }
                        .buttonStyle(.borderedProminent)
                    
                    Button("Share") { vm.shareEvent() }
                }
            }
            .padding()
        }
        .navigationTitle("Event Details")
    }
}
