// EventCreationFlow.swift
// N3ON — Prompt layer
// Three-step coordinator. Routes between EventDatePickerView → EventLimboView →
// TicketPricingStepView. All state lives in EventDraftViewModel.

import SwiftUI

struct EventCreationFlowView: View {
    @EnvironmentObject var draft: EventDraftViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.25), value: draft.currentStep)
            }
        }
        .task { await draft.load() }
        .alert("Event Live!", isPresented: $draft.didSubmitSuccessfully) {
            Button("Done") { draft.reset(); dismiss() }
        } message: {
            Text("Your event is now visible on the map.")
        }
    }

    @ViewBuilder private var stepContent: some View {
        switch draft.currentStep {
        case .datePicker: EventDatePickerView()
        case .limbo:      EventLimboView()
        case .pricing:    TicketPricingStepView()
        }
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(EventCreationStep.allCases, id: \.rawValue) { step in
                Capsule()
                    .fill(step.rawValue <= draft.currentStep.rawValue
                          ? Color("neonPurpleBackground")
                          : Color.white.opacity(0.15))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.25), value: draft.currentStep)
            }
        }
    }
}
