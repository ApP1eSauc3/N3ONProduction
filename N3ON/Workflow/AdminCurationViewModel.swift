// AdminCurationViewModel.swift
// N3ON — Workflow layer
//
// Drives Prompt/Admin/AdminCurationView during the bootstrap phase. Loads the DJ
// roster + events and wraps AdminService. Only ever presented to admins (the
// console is gated on AccessControlService.isAdmin()); AppSync also enforces the
// AdminUser @auth rules server-side, so a non-admin's writes are rejected on sync.

import Foundation

@MainActor
final class AdminCurationViewModel: ObservableObject {
    @Published var djs: [User] = []
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // Two independent full-table reads — run them concurrently.
            async let djsFetch = AdminService.allDJs()
            async let eventsFetch = AdminService.allEvents()
            (djs, events) = try await (djsFetch, eventsFetch)
        } catch {
            errorMessage = "Could not load admin data: \(error.localizedDescription)"
        }
    }

    // MARK: - DJ actions

    func seedRank(_ rank: Int?, for dj: User) async {
        do { replaceDJ(try await AdminService.setDJRank(rank, for: dj)) }
        catch { errorMessage = error.localizedDescription }
    }

    func toggleCurated(_ dj: User) async {
        do { replaceDJ(try await AdminService.setCurated(!dj.isCurated, for: dj)) }
        catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Event actions

    func toggleFeatured(_ event: Event) async {
        do { replaceEvent(try await AdminService.setFeatured(!event.isFeatured, for: event)) }
        catch { errorMessage = error.localizedDescription }
    }

    func forcePublish(_ event: Event) async {
        do {
            try await AdminService.forcePublish(eventID: event.id)
            events = try await AdminService.allEvents()
        } catch { errorMessage = error.localizedDescription }
    }

    func attachDJ(_ dj: User, to event: Event) async {
        do { try await AdminService.attachDJ(dj, toEventID: event.id) }
        catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Local cache helpers

    private func replaceDJ(_ dj: User) {
        if let i = djs.firstIndex(where: { $0.id == dj.id }) { djs[i] = dj }
    }
    private func replaceEvent(_ event: Event) {
        if let i = events.firstIndex(where: { $0.id == event.id }) { events[i] = event }
    }
}
