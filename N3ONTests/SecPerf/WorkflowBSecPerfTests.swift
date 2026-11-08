// WorkflowBSecPerfTests.swift
// N3ONTests
//
// Security + performance tests for the chat, inbox, map, event-draft and
// venue ViewModels, the remaining Prompt-layer pure helpers, and the last
// service / motion functions.

import XCTest
import SwiftUI
import MapKit
import CoreLocation
import Amplify
@testable import N3ON

@MainActor
final class WorkflowBSecPerfTests: BackendTestCase {

    private func room(_ id: String, members: [String]?, event: String? = nil) -> ChatRoom {
        ChatRoom(id: id, name: "room-\(id)", createdAt: Make.now(), updatedAt: Make.now(), lastMessage: "",
                 lastMessageTimestamp: Make.now(), associatedEvent: event, participantIDs: members)
    }

    private func message(_ id: String, in roomID: String, from sender: User, read: Bool = false) -> Message {
        Message(id: id, sender: sender, chatRoomID: roomID, content: "hi", timestamp: Make.now(), isRead: read)
    }

    private func image(_ w: Int, _ h: Int) -> UIImage {
        let f = UIGraphicsImageRendererFormat(); f.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: f).image { c in
            UIColor.purple.setFill(); c.fill(CGRect(x: 0, y: 0, width: w, height: h))
        }
    }

    // MARK: - ChatsInboxVM

    func test_ChatsInboxVM_start_security() async {
        backend.auth.userID = nil
        let vm = ChatsInboxVM()
        vm.start()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(vm.pinned.isEmpty && vm.others.isEmpty, "signed out shows no chats")
    }

    func test_ChatsInboxVM_start_performance() {
        let t = elapsedSync(iterations: 500) { ChatsInboxVM().start() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ChatsInboxVM_refresh_security() async {
        let mine = room("mine", members: ["me"]), theirs = room("theirs", members: ["x"])
        db.seed([mine, theirs]); db.seed([UserChatRooms(user: Make.user("me"), chatRoom: mine)])
        let vm = ChatsInboxVM()
        await vm.refresh()
        XCTAssertEqual((vm.pinned + vm.others).map(\.id), ["mine"], "only rooms I'm a member of")
    }

    func test_ChatsInboxVM_refresh_performance() async {
        let rooms = Make.many(2_000) { room("r\($0)", members: ["x"]) }
        db.seed(rooms); db.seed((0..<20).map { UserChatRooms(user: Make.user("me"), chatRoom: rooms[$0]) })
        let vm = ChatsInboxVM()
        db.resetCounters()
        let t = await elapsed { await vm.refresh() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertEqual(vm.others.count, 20)
        XCTAssertEqual(db.unfilteredQueryCount, 0, "used to load every room on the device")
    }

    func test_ChatsInboxVM_summarize_security() async throws {
        // A room tied to someone else's event isn't pinned for me.
        db.seed([Make.event("e", host: "other", days: 1)]); db.seed([Make.venue("v1", owner: Make.user("owner2"))])
        let vm = ChatsInboxVM()
        let s = try await vm.summarize(room: room("r", members: ["me"], event: "e"), me: "me")
        XCTAssertEqual(s?.pinned, false)
        XCTAssertEqual(s?.title, "Event Chat")
    }

    func test_ChatsInboxVM_summarize_performance() async throws {
        let r = room("r", members: ["me"])
        db.seed([r]); db.seed(Make.many(1_000) { self.message("m\($0)", in: "r", from: Make.user("x")) })
        let vm = ChatsInboxVM()
        let t = try await elapsed(iterations: 10) { _ = try await vm.summarize(room: r, me: "me") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_ChatsInboxVM_startObserving_security() async throws {
        db.seed([room("mine", members: ["me"])])
        let vm = ChatsInboxVM()
        vm.startObserving()
        try await Task.sleep(nanoseconds: 50_000_000)
        try await Backend.dataStore.save(message("m", in: "elsewhere", from: Make.user("x")))
        try await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertTrue(vm.others.isEmpty, "a message elsewhere never adds a room I'm not in")
    }

    func test_ChatsInboxVM_startObserving_performance() async throws {
        let vm = ChatsInboxVM()
        vm.startObserving()
        try await Task.sleep(nanoseconds: 50_000_000)
        db.resetCounters()
        let t = try await elapsed { for i in 0..<500 { try await Backend.dataStore.save(self.message("m\(i)", in: "r", from: Make.user("x"))) } }
        try await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertLessThanOrEqual(db.queryCount, 10, "500 messages debounce to ~1 refresh")
    }

    func test_ChatsInboxVM_scheduleDebouncedRefresh_security() async {
        backend.auth.userID = nil
        let vm = ChatsInboxVM()
        vm.scheduleDebouncedRefresh()
        try? await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertNil(vm.me, "a refresh while signed out resolves no identity")
    }

    func test_ChatsInboxVM_scheduleDebouncedRefresh_performance() async {
        let vm = ChatsInboxVM()
        db.resetCounters()
        for _ in 0..<1_000 { vm.scheduleDebouncedRefresh() }
        try? await Task.sleep(nanoseconds: 700_000_000)
        XCTAssertLessThanOrEqual(db.queryCount, 3, "1,000 triggers collapse into one refresh")
    }

    // MARK: - ChatViewModel

    func test_ChatViewModel_load_security() async {
        db.seed([room("locked", members: ["a", "b"])]); db.seed([message("secret", in: "locked", from: Make.user("a"))])
        let vm = ChatViewModel(chatRoomID: "locked", currentUserID: "me")
        await vm.load()
        XCTAssertTrue(vm.messages.isEmpty, "a room I'm not in shows nothing")
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_ChatViewModel_load_performance() async {
        db.seed([room("r", members: ["me", "dj"])])
        db.seed([Make.user("me"), Make.user("dj")])
        db.seed(Make.many(2_000) { self.message("m\($0)", in: "r", from: $0 % 2 == 0 ? Make.user("me") : Make.user("dj")) })
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        let t = await elapsed { await vm.load() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertEqual(vm.messages.count, 2_000)
    }

    func test_ChatViewModel_sendMessage_security() async {
        db.seed([room("r", members: ["me"])]); db.seed([Make.user("me")])
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        await vm.load()
        vm.messageText = String(repeating: "x", count: ChatRoomService.maxMessageLength + 1)
        vm.sendMessage()
        XCTAssertTrue(vm.messages.isEmpty, "an over-long message is refused before it shows as sending")
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_ChatViewModel_sendMessage_performance() async {
        db.seed([room("r", members: ["me"])]); db.seed([Make.user("me")])
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        await vm.load()
        let t = elapsedSync(iterations: 300) { vm.messageText = "yo"; vm.sendMessage() }
        XCTAssertLessThan(t, 2.0, "300 optimistic inserts: \(t)s")
        let sent = await eventually(timeout: 5) { vm.messages.filter { $0.deliveryStatus == .sent }.count == 300 }
        XCTAssertTrue(sent)
    }

    func test_ChatViewModel_markRead_security() async {
        db.seed([message("mine", in: "r", from: Make.user("me"))])
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        await vm.markRead()
        XCTAssertFalse(db.all(Message.self).first?.isRead ?? true, "my own message isn't marked read by me")
    }

    func test_ChatViewModel_markRead_performance() async {
        db.seed(Make.many(1_000) { self.message("m\($0)", in: "r", from: Make.user("dj")) })
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        let t = await elapsed { await vm.markRead() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_ChatViewModel_startObserving_security() async throws {
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        vm.startObserving()
        try await Task.sleep(nanoseconds: 50_000_000)
        try await Backend.dataStore.save(message("other-room", in: "r2", from: Make.user("dj")))
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(vm.messages.isEmpty, "messages from other rooms never appear here")
    }

    func test_ChatViewModel_startObserving_performance() async throws {
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        vm.startObserving()
        try await Task.sleep(nanoseconds: 50_000_000)
        let t = try await elapsed { for i in 0..<300 { try await Backend.dataStore.save(self.message("m\(i)", in: "r", from: Make.user("dj"))) } }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        let all = await eventually(timeout: 5) { vm.messages.count == 300 }
        XCTAssertTrue(all)
    }

    func test_ChatViewModel_toChatMessage_security() {
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        let theirs = vm.toChatMessage(Message(sender: nil, chatRoomID: "r", content: "x", timestamp: Make.now(), isRead: false))
        XCTAssertFalse(theirs.isCurrentUser, "an unattributed message is never shown as mine")
    }

    func test_ChatViewModel_toChatMessage_performance() {
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        let m = message("m", in: "r", from: Make.user("dj"))
        let t = elapsedSync(iterations: 50_000) { _ = vm.toChatMessage(m) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ChatViewModel_resolveSender_security() async {
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        let id = await vm.resolveSender(of: Message(id: "ghost", sender: nil, chatRoomID: "r", content: "x", timestamp: Make.now(), isRead: false))
        XCTAssertEqual(id, "", "unknown senders resolve to no one — never to me")
    }

    func test_ChatViewModel_resolveSender_performance() async {
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        let m = message("m", in: "r", from: Make.user("dj"))
        let t = await elapsed(iterations: 10_000) { _ = await vm.resolveSender(of: m) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ChatViewModel_resolveNames_security() async {
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        await vm.resolveNames(for: ["", "ghost"])
        XCTAssertEqual(backend.graphQL.reads, ["ghost"], "empty ids are never looked up")
    }

    func test_ChatViewModel_resolveNames_performance() async {
        db.seed(Make.many(200) { Make.user("u\($0)") })
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        let ids = (0..<200).map { "u\($0)" }
        let t = await elapsed(iterations: 10) { await vm.resolveNames(for: ids) }
        XCTAssertLessThan(t, 2.0, "cached after the first pass: \(t)s")
    }

    func test_ChatViewModel_updateStatus_security() {
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        vm.messages = [ChatMessage(id: "a", sender: "me", content: "x", timestamp: Date(), isCurrentUser: true, deliveryStatus: .sending)]
        vm.updateStatus(id: "nonexistent", to: .read)
        XCTAssertEqual(vm.messages.first?.deliveryStatus, .sending, "unknown ids change nothing")
    }

    func test_ChatViewModel_updateStatus_performance() {
        let vm = ChatViewModel(chatRoomID: "r", currentUserID: "me")
        vm.messages = Make.many(1_000) { ChatMessage(id: "m\($0)", sender: "me", content: "x", timestamp: Date(), isCurrentUser: true, deliveryStatus: .sending) }
        let t = elapsedSync(iterations: 2_000) { vm.updateStatus(id: "m999", to: .sent) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - EventDraftViewModel

    private func draft(capacity: Int = 150) -> EventDraftViewModel {
        let vm = EventDraftViewModel()
        vm.venue = Make.venue("v1", capacity: capacity)
        vm.eventName = "Warehouse"
        vm.eventDate = Date().addingTimeInterval(90 * 86_400)
        vm.availableTickets = 100
        return vm
    }

    func test_EventDraftViewModel_canPublish_security() {
        let vm = draft(); vm.currentTally = 0
        XCTAssertFalse(vm.canPublish(in: .community), "no lineup, no sale in community mode")
    }

    func test_EventDraftViewModel_canPublish_performance() {
        let vm = draft()
        let t = elapsedSync(iterations: 100_000) { _ = vm.canPublish(in: .community) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EventDraftViewModel_load_security() async {
        backend.auth.userID = nil
        let vm = EventDraftViewModel()
        await vm.load()
        XCTAssertEqual(vm.hostDJRank, 0, "signed out has no host rank")
    }

    func test_EventDraftViewModel_load_performance() async {
        db.seed([Make.user("me", rank: 4)])
        let vm = EventDraftViewModel()
        let t = await elapsed(iterations: 1_000) { await vm.load() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(vm.hostDJRank, 4)
    }

    func test_EventDraftViewModel_draftProblem_security() {
        let future = Date().addingTimeInterval(86_400)
        XCTAssertNotNil(EventDraftViewModel.draftProblem(name: "N", description: "", tickets: 0, capacity: 100, date: future))
        XCTAssertNotNil(EventDraftViewModel.draftProblem(name: "N", description: "", tickets: -5, capacity: 100, date: future))
        XCTAssertNotNil(EventDraftViewModel.draftProblem(name: "N", description: "", tickets: 101, capacity: 100, date: future), "oversell the venue")
        XCTAssertNotNil(EventDraftViewModel.draftProblem(name: "N", description: "", tickets: 10, capacity: 100, date: Date().addingTimeInterval(-60)))
        XCTAssertNotNil(EventDraftViewModel.draftProblem(name: String(repeating: "n", count: 121), description: "", tickets: 1, capacity: 1, date: future))
        XCTAssertNil(EventDraftViewModel.draftProblem(name: "N", description: "d", tickets: 100, capacity: 100, date: future))
    }

    func test_EventDraftViewModel_draftProblem_performance() {
        let future = Date().addingTimeInterval(86_400), desc = String(repeating: "d", count: 1_900)
        let t = elapsedSync(iterations: 20_000) { _ = EventDraftViewModel.draftProblem(name: "Rave", description: desc, tickets: 50, capacity: 200, date: future) }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_EventDraftViewModel_priceProblem_security() {
        for bad in [-1.0, .nan, .infinity, 1_000.01] { XCTAssertNotNil(EventDraftViewModel.priceProblem(bad), "\(bad)") }
        XCTAssertNil(EventDraftViewModel.priceProblem(0))
        XCTAssertNil(EventDraftViewModel.priceProblem(45))
    }

    func test_EventDraftViewModel_priceProblem_performance() {
        let t = elapsedSync(iterations: 500_000) { _ = EventDraftViewModel.priceProblem(25) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EventDraftViewModel_saveEventDraft_security() async {
        let vm = draft(capacity: 50); vm.availableTickets = 5_000
        await vm.saveEventDraft()
        XCTAssertNotNil(vm.submissionError)
        XCTAssertTrue(db.all(Event.self).isEmpty, "an invalid draft is never saved")
        let ok = draft()
        await ok.saveEventDraft()
        let saved = db.all(Event.self).first
        XCTAssertEqual(saved?.hostDJID, "me", "the host is the session user")
        XCTAssertEqual(saved?.status, "pending", "a draft is never created live")
        XCTAssertEqual(saved?.ticketPrice, 0)
    }

    func test_EventDraftViewModel_saveEventDraft_performance() async {
        let t = await elapsed(iterations: 200) { let vm = self.draft(); await vm.saveEventDraft(); vm.reset() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_EventDraftViewModel_joinOwnLineup_security() async throws {
        let vm = EventDraftViewModel()
        vm.joinOwnLineup(eventID: "e1")
        _ = await eventually { !self.backend.rest.requests.isEmpty }
        let body = try XCTUnwrap(backend.rest.requests.first?.body)
        XCTAssertEqual(body.keys.sorted(), ["eventID"], "who joins is the server's call (signed identity)")
        vm.reset()
    }

    func test_EventDraftViewModel_joinOwnLineup_performance() async {
        let vm = EventDraftViewModel()
        let t = elapsedSync(iterations: 2_000) { vm.joinOwnLineup(eventID: "e1") }
        XCTAssertLessThan(t, 2.0, "re-joins cancel the previous attempt: \(t)s")
        vm.reset()
    }

    func test_EventDraftViewModel_startTallyObserver_security() async throws {
        let mine = Make.event("mine"), other = Make.event("other")
        db.seed([mine, other])
        let vm = draft(); vm.createdEventID = "mine"
        vm.startTallyObserver()
        try await Task.sleep(nanoseconds: 50_000_000)
        try await Backend.dataStore.save(Make.link(event: other, dj: "x", rank: 5))
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(vm.currentTally, 0, "another event's lineup never counts toward mine")
        try await Backend.dataStore.save(Make.link(event: mine, dj: "y", rank: 5))
        let counted = await eventually { vm.currentTally == 25 }
        XCTAssertTrue(counted)
        vm.reset()
    }

    func test_EventDraftViewModel_startTallyObserver_performance() async throws {
        let mine = Make.event("mine"), other = Make.event("other"); db.seed([mine, other])
        let vm = draft(); vm.createdEventID = "mine"
        vm.startTallyObserver()
        try await Task.sleep(nanoseconds: 50_000_000)
        db.resetCounters()
        for i in 0..<300 { try await Backend.dataStore.save(Make.link(event: other, dj: "d\(i)")) }
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertLessThanOrEqual(db.queryCount, 2, "other events' links don't re-query the tally")
        vm.reset()
    }

    func test_EventDraftViewModel_refreshTally_security() async {
        let e = Make.event("e"); db.seed([e]); db.seed([Make.link(event: e, dj: "a", rank: 2), Make.link(event: Make.event("x"), dj: "b", rank: 5)])
        let vm = EventDraftViewModel()
        await vm.refreshTally()
        XCTAssertEqual(vm.currentTally, 0, "no draft yet → no tally")
        vm.createdEventID = "e"
        await vm.refreshTally()
        XCTAssertEqual(vm.currentTally, 5)
    }

    func test_EventDraftViewModel_refreshTally_performance() async {
        let e = Make.event("e"); db.seed([e]); db.seed(Make.many(2_000) { Make.link(event: e, dj: "d\($0)") })
        let vm = EventDraftViewModel(); vm.createdEventID = "e"
        let t = await elapsed(iterations: 5) { await vm.refreshTally() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_EventDraftViewModel_uploadPosterAndGoLive_security() async {
        db.seed([Make.event("e", host: "other", status: "pending")])
        let vm = draft(); vm.createdEventID = "e"; vm.ticketPrice = 10
        await vm.uploadPosterAndGoLive(image(100, 100))
        XCTAssertNotEqual(db.all(Event.self).first?.status, "live", "can't publish another host's event")
        vm.ticketPrice = -3
        await vm.uploadPosterAndGoLive(image(10, 10))
        XCTAssertNotNil(vm.posterUploadError)
    }

    func test_EventDraftViewModel_uploadPosterAndGoLive_performance() async {
        db.seed([Make.event("e", host: "me", status: "pending")])
        let vm = draft(); vm.createdEventID = "e"; vm.ticketPrice = 0
        let t = await elapsed { await vm.uploadPosterAndGoLive(self.image(4_032, 3_024)) }
        XCTAssertLessThan(t, 4.0, "\(t)s")
        XCTAssertLessThan(backend.storage.uploads.last?.bytes ?? .max, 2_000_000, "poster downscaled, not full-res")
        XCTAssertEqual(db.all(Event.self).first?.status, "live")
    }

    func test_EventDraftViewModel_glowStrength_security() {
        let vm = EventDraftViewModel(); let v = Make.venue("v1")
        let glow = vm.glowStrength(for: v, allEvents: Make.many(100) { Make.event("e\($0)", venueID: "v1", days: 1) })
        XCTAssertLessThanOrEqual(glow, 1.0, "flooding a venue with events can't exceed full glow")
        XCTAssertEqual(vm.glowStrength(for: v, allEvents: [Make.event("x", venueID: "other", days: 1)]), 0)
    }

    func test_EventDraftViewModel_glowStrength_performance() {
        let vm = EventDraftViewModel(); let v = Make.venue("v1")
        let events = Make.many(5_000) { Make.event("e\($0)", venueID: "v\($0 % 50)", days: $0 % 60) }
        let t = elapsedSync(iterations: 20) { _ = vm.glowStrength(for: v, allEvents: events) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EventDraftViewModel_reset_security() {
        let vm = draft(); vm.createdEventID = "e"; vm.submissionError = "x"; vm.ticketPrice = 50
        vm.reset()
        XCTAssertNil(vm.createdEventID); XCTAssertNil(vm.venue); XCTAssertNil(vm.submissionError)
        XCTAssertEqual(vm.ticketPrice, 0, "no state leaks into the next event")
    }

    func test_EventDraftViewModel_reset_performance() {
        let vm = draft()
        let t = elapsedSync(iterations: 20_000) { vm.reset() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_EventDraftViewModel_combinedEventDateTime_security() {
        let vm = EventDraftViewModel()
        let day = Calendar.current.date(from: DateComponents(year: 2027, month: 3, day: 14))!
        let time = Calendar.current.date(from: DateComponents(year: 1999, month: 1, day: 1, hour: 22, minute: 30))!
        vm.eventDate = day; vm.eventTime = time
        let c = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: vm.combinedEventDateTime())
        XCTAssertEqual([c.year, c.month, c.day, c.hour, c.minute], [2027, 3, 14, 22, 30], "date from the date, time from the time — never the time's year")
    }

    func test_EventDraftViewModel_combinedEventDateTime_performance() {
        let vm = EventDraftViewModel()
        let t = elapsedSync(iterations: 20_000) { _ = vm.combinedEventDateTime() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - MapViewModel

    func test_MapViewModel_loadMapData_security() async {
        db.seed([Make.venue("ok"), Make.venue("pending", status: "pending")])
        db.seed([Make.event("e1", venueID: "ok", days: 2), Make.event("e2", venueID: "pending", days: 2)])
        let vm = MapViewModel()
        await vm.loadMapData()
        XCTAssertEqual(vm.role, .regular)
        XCTAssertEqual(vm.venues.map(\.id), ["ok"], "unapproved venues never reach the public map")
    }

    func test_MapViewModel_loadMapData_performance() async {
        db.seed(Make.many(1_000) { Make.venue("v\($0)") }); db.seed(Make.many(3_000) { Make.event("e\($0)", venueID: "v\($0 % 1_000)", days: 3) })
        let vm = MapViewModel()
        db.resetCounters()
        let t = await elapsed { await vm.loadMapData() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_MapViewModel_directionsItem_security() {
        XCTAssertNil(MapViewModel.directionsItem(for: Make.venue("bad").withCoords(999, 0)), "invalid coordinates never open Maps")
        XCTAssertNil(MapViewModel.directionsItem(for: Make.venue("null").withCoords(0, 0)), "null island is a missing location")
        let item = MapViewModel.directionsItem(for: Make.venue("v", name: String(repeating: "n", count: 500)))
        XCTAssertLessThanOrEqual(item?.name?.count ?? 0, VenueService.maxNameLength)
    }

    func test_MapViewModel_directionsItem_performance() {
        let v = Make.venue("v")
        let t = elapsedSync(iterations: 5_000) { _ = MapViewModel.directionsItem(for: v) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_MapViewModel_zoomToLocation_security() {
        let vm = MapViewModel()
        vm.zoomToLocation(CLLocationCoordinate2D(latitude: -27.4, longitude: 153.0))
        XCTAssertEqual(vm.cameraRequest?.region.span.latitudeDelta, 0.05, "neighbourhood zoom, not a pinpoint")
    }

    func test_MapViewModel_zoomToLocation_performance() {
        let vm = MapViewModel()
        let t = elapsedSync(iterations: 50_000) { vm.zoomToLocation(CLLocationCoordinate2D(latitude: 1, longitude: 1)) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_MapViewModel_zoomToUserLocation_security() {
        let vm = MapViewModel()
        vm.zoomToUserLocation()
        XCTAssertNil(vm.cameraRequest, "no fix → the camera doesn't move to a made-up location")
    }

    func test_MapViewModel_zoomToUserLocation_performance() {
        let vm = MapViewModel()
        let t = elapsedSync(iterations: 100_000) { vm.zoomToUserLocation() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_MapViewModel_loadVenueRoleData_security() async throws {
        let me = Make.user("me", isDJ: false)
        db.seed([Make.venue("mine", owner: me), Make.venue("theirs", owner: Make.user("x"))])
        db.seed([Make.event("a", venueID: "mine", days: 2), Make.event("b", venueID: "theirs", days: 2)])
        let vm = MapViewModel()
        await vm.loadMapData()   // resolves currentUserID
        try await vm.loadVenueRoleData()
        XCTAssertEqual(vm.venues.map(\.id), ["mine"])
        XCTAssertEqual(vm.events.map(\.id), ["a"], "a venue owner sees only their own events")
    }

    func test_MapViewModel_loadVenueRoleData_performance() async throws {
        let me = Make.user("me", isDJ: false)
        db.seed(Make.many(1_000) { Make.venue("v\($0)", owner: $0 < 5 ? me : Make.user("x")) })
        db.seed(Make.many(3_000) { Make.event("e\($0)", venueID: "v\($0 % 1_000)", days: 3) })
        let vm = MapViewModel(); await vm.loadMapData()
        let t = try await elapsed { try await vm.loadVenueRoleData() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_MapViewModel_loadDJRoleData_security() async throws {
        let e = Make.event("e", venueID: "ok", days: 2), hidden = Make.event("h", venueID: "pending", days: 2)
        db.seed([Make.venue("ok"), Make.venue("pending", status: "pending")]); db.seed([e, hidden])
        db.seed([Make.user("dj1"), Make.user("dj2")]); db.seed([Make.link(event: e, dj: "dj1"), Make.link(event: hidden, dj: "dj2")])
        let vm = MapViewModel()
        try await vm.loadDJRoleData()
        XCTAssertEqual(vm.djPins.map(\.djName), ["dj1"], "no pins at unapproved venues")
    }

    func test_MapViewModel_loadDJRoleData_performance() async throws {
        db.seed(Make.many(300) { Make.venue("v\($0)") })
        let events = Make.many(1_000) { Make.event("e\($0)", venueID: "v\($0 % 300)", days: 3) }
        db.seed(events); db.seed(Make.many(50) { Make.user("d\($0)") })
        db.seed(Make.many(1_000) { Make.link(event: events[$0], dj: "d\($0 % 50)") })
        let vm = MapViewModel()
        db.resetCounters()
        let t = try await elapsed { try await vm.loadDJRoleData() }
        XCTAssertLessThan(t, 4.0, "\(t)s")
        XCTAssertLessThanOrEqual(db.queryCount, 3 + 20 + 50, "one user read per DJ (50), not per link (1,000)")
    }

    func test_MapViewModel_loadRegularRoleData_security() async throws {
        let e = Make.event("e", venueID: "v", days: 2); db.seed([Make.venue("v")]); db.seed([e])
        db.seed([Make.user("followed"), Make.user("stranger")]); db.seed([Make.link(event: e, dj: "followed"), Make.link(event: e, dj: "stranger")])
        db.seed([UserFollows(followerID: "me", followeeID: "followed", createdAt: Make.now())])
        let vm = MapViewModel(); await vm.loadMapData()
        try await vm.loadRegularRoleData()
        XCTAssertEqual(vm.djPins.map(\.djName), ["followed"], "fans see only DJs they follow")
    }

    func test_MapViewModel_loadRegularRoleData_performance() async throws {
        db.seed(Make.many(300) { Make.venue("v\($0)") })
        let events = Make.many(1_000) { Make.event("e\($0)", venueID: "v\($0 % 300)", days: 3) }
        db.seed(events); db.seed(Make.many(50) { Make.user("d\($0)") })
        db.seed(Make.many(1_000) { Make.link(event: events[$0], dj: "d\($0 % 50)") })
        db.seed(Make.many(50) { UserFollows(followerID: "me", followeeID: "d\($0)", createdAt: Make.now()) })
        let vm = MapViewModel(); await vm.loadMapData()
        let t = try await elapsed { try await vm.loadRegularRoleData() }
        XCTAssertLessThan(t, 4.0, "\(t)s")
    }

    func test_MapViewModel_setupLocationManager_security() {
        let vm = MapViewModel()
        vm.setupLocationManager()
        XCTAssertEqual(vm.configuredAccuracy, kCLLocationAccuracyHundredMeters, "neighbourhood precision, not GPS-grade")
    }

    func test_MapViewModel_setupLocationManager_performance() {
        let vm = MapViewModel()
        let t = elapsedSync(iterations: 2_000) { vm.setupLocationManager() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_MapViewModel_shouldReverseGeocode_security() async {
        let vm = MapViewModel()
        XCTAssertFalse(vm.shouldReverseGeocode(CLLocation(latitude: 999, longitude: 0)), "invalid fixes never sent to the geocoder")
        XCTAssertTrue(vm.shouldReverseGeocode(CLLocation(latitude: -27.47, longitude: 153.02)))
    }

    func test_MapViewModel_shouldReverseGeocode_performance() {
        let vm = MapViewModel(); let l = CLLocation(latitude: -27.47, longitude: 153.02)
        let t = elapsedSync(iterations: 100_000) { _ = vm.shouldReverseGeocode(l) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_MapViewModel_reverseGeocode_security() async {
        let vm = MapViewModel()
        await vm.reverseGeocode(location: CLLocation(latitude: 999, longitude: 999))
        XCTAssertNil(vm.userCity)
    }

    func test_MapViewModel_reverseGeocode_performance() async {
        // After the first lookup, fixes within 1km are throttled (no request).
        let vm = MapViewModel()
        await vm.reverseGeocode(location: CLLocation(latitude: -27.47, longitude: 153.02))
        let near = CLLocation(latitude: -27.4701, longitude: 153.0201)
        XCTAssertFalse(vm.shouldReverseGeocode(near), "throttled within \(MapViewModel.geocodeDistance)m")
        let t = await elapsed(iterations: 5_000) { await vm.reverseGeocode(location: near) }
        XCTAssertLessThan(t, 2.0, "5k throttled fixes, zero requests: \(t)s")
    }

    func test_MapViewModel_locationManager_security() async {
        let vm = MapViewModel()
        vm.locationManager(CLLocationManager(), didUpdateLocations: [])
        XCTAssertNil(vm.userLocation, "an empty update sets nothing")
        vm.locationManager(CLLocationManager(), didFailWithError: FakeError(tag: "denied"))
        XCTAssertNil(vm.userLocation, "failures never invent a location")
    }

    func test_MapViewModel_locationManager_performance() async {
        let vm = MapViewModel(); let m = CLLocationManager()
        let t = elapsedSync(iterations: 2_000) { vm.locationManager(m, didUpdateLocations: [CLLocation(latitude: 999, longitude: 0)]) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_MapViewModel_locationManagerDidChangeAuthorization_security() {
        // Without permission, nothing starts tracking.
        let vm = MapViewModel(); let m = CLLocationManager()
        vm.locationManagerDidChangeAuthorization(m)
        XCTAssertNil(vm.userLocation)
    }

    func test_MapViewModel_locationManagerDidChangeAuthorization_performance() {
        let vm = MapViewModel(); let m = CLLocationManager()
        // authorizationStatus is an IPC call to locationd (~1ms); the OS calls
        // this only when permission changes, so 200 is already far above use.
        let t = elapsedSync(iterations: 200) { vm.locationManagerDidChangeAuthorization(m) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - VenueApplicationViewModel

    func test_VenueApplicationViewModel_nextStep_security() {
        let vm = VenueApplicationViewModel(); vm.step = .review
        vm.nextStep()
        XCTAssertEqual(vm.step, .review, "can't step past review")
    }

    func test_VenueApplicationViewModel_nextStep_performance() {
        let vm = VenueApplicationViewModel()
        let t = elapsedSync(iterations: 100_000) { vm.nextStep() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_VenueApplicationViewModel_previousStep_security() {
        let vm = VenueApplicationViewModel()
        vm.previousStep()
        XCTAssertEqual(vm.step, .details, "can't step before the first")
    }

    func test_VenueApplicationViewModel_previousStep_performance() {
        let vm = VenueApplicationViewModel()
        let t = elapsedSync(iterations: 100_000) { vm.previousStep() }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_VenueApplicationViewModel_geocodeCurrentAddress_security() async {
        let vm = VenueApplicationViewModel(); vm.address = String(repeating: "a", count: 5_000)
        await vm.geocodeCurrentAddress()
        XCTAssertNil(vm.latitude, "oversized input never geocoded")
        XCTAssertNotNil(vm.geocodeError)
    }

    func test_VenueApplicationViewModel_geocodeCurrentAddress_performance() async {
        let vm = VenueApplicationViewModel(); vm.address = String(repeating: "a", count: 100_000)
        let t = await elapsed(iterations: 50) { await vm.geocodeCurrentAddress() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_VenueApplicationViewModel_submitApplication_security() async {
        db.seed([Make.user("me", isDJ: false)])
        let vm = VenueApplicationViewModel()
        vm.name = "Club"; vm.address = "1 St"; vm.latitude = -27.4; vm.longitude = 153.0; vm.maxCapacity = -10
        await vm.submitApplication()
        XCTAssertFalse(vm.didSubmitSuccessfully)
        XCTAssertTrue(db.all(Venue.self).isEmpty, "an invalid capacity is never submitted")
        vm.maxCapacity = 300
        await vm.submitApplication()
        XCTAssertEqual(db.all(Venue.self).first?.approvalStatus, "pending", "applications start pending")
    }

    func test_VenueApplicationViewModel_submitApplication_performance() async {
        db.seed([Make.user("me", isDJ: false)])
        let vm = VenueApplicationViewModel()
        vm.name = "Club"; vm.address = "1 St"; vm.latitude = -27.4; vm.longitude = 153.0
        vm.selectedImages = Array(repeating: image(2_000, 1_500), count: 3)
        let t = await elapsed { await vm.submitApplication() }
        XCTAssertLessThan(t, 6.0, "\(t)s")
        XCTAssertTrue(vm.didSubmitSuccessfully)
    }

    // MARK: - VenueProfileViewModel

    func test_VenueProfileViewModel_load_security() async {
        db.seed([Make.venue("theirs", owner: Make.user("x"))])
        let vm = VenueProfileViewModel()
        await vm.load()
        XCTAssertNil(vm.venue, "never shows someone else's venue as mine")
    }

    func test_VenueProfileViewModel_load_performance() async {
        db.seed([Make.venue("mine", owner: Make.user("me", isDJ: false))] + Make.many(2_000) { Make.venue("v\($0)", owner: Make.user("x")) })
        db.seed(Make.many(2_000) { Make.event("e\($0)", venueID: $0 % 10 == 0 ? "mine" : "v1", days: 3) })
        let vm = VenueProfileViewModel()
        let t = await elapsed { await vm.load() }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_VenueProfileViewModel_apply_security() {
        let vm = VenueProfileViewModel()
        var v = Make.venue("v"); v.imageKey = nil
        vm.apply(venue: v)
        XCTAssertEqual(vm.avatarState, .remote(avatarKey: "default-venue-avatar"))
        XCTAssertTrue(vm.galleryKeys.isEmpty)
    }

    func test_VenueProfileViewModel_apply_performance() {
        let vm = VenueProfileViewModel(); var v = Make.venue("v"); v.imageKey = Make.many(10) { "venues/v/\($0).jpg" }
        let t = elapsedSync(iterations: 50_000) { vm.apply(venue: v) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_VenueProfileViewModel_saveChanges_security() async {
        let v = Make.venue("mine", owner: Make.user("me", isDJ: false), status: "pending"); db.seed([v])
        let vm = VenueProfileViewModel(); vm.apply(venue: v)
        await vm.saveChanges(name: "", description: "d")
        XCTAssertNotNil(vm.saveError, "an empty name is refused")
        await vm.saveChanges(name: "New", description: "d")
        XCTAssertEqual(vm.venue?.approvalStatus, "pending", "editing never approves")
    }

    func test_VenueProfileViewModel_saveChanges_performance() async {
        let v = Make.venue("mine", owner: Make.user("me", isDJ: false)); db.seed([v])
        let vm = VenueProfileViewModel(); vm.apply(venue: v)
        let t = await elapsed(iterations: 300) { await vm.saveChanges(name: "N", description: "D") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_VenueProfileViewModel_uploadGalleryImage_security() async {
        // Another owner's venue: refused before any upload, gallery unchanged.
        var foreign = Make.venue("theirs", owner: Make.user("x")); foreign.imageKey = []
        db.seed([foreign])
        let vm = VenueProfileViewModel(); vm.apply(venue: foreign)
        await vm.uploadGalleryImage(image(50, 50))
        XCTAssertTrue(vm.galleryKeys.isEmpty)
        XCTAssertNotNil(vm.saveError)
        XCTAssertTrue(backend.storage.uploads.isEmpty, "nothing uploaded into someone else's folder")
        // Own venue, but the record save fails: the uploaded key is NOT kept
        // in the gallery (it used to leave a phantom photo).
        let mine = Make.venue("mine", owner: Make.user("me", isDJ: false)); db.seed([mine])
        let vm2 = VenueProfileViewModel(); vm2.apply(venue: mine)
        await vm2.uploadGalleryImage(image(50, 50))   // succeeds: 1 photo
        let before = vm2.galleryKeys
        XCTAssertEqual(before.count, 1)
        // The stored record disappears: the upload still succeeds, update() fails.
        try? await Backend.dataStore.delete(db.all(Venue.self).first { $0.id == "mine" }!)
        await vm2.uploadGalleryImage(image(50, 50))
        XCTAssertEqual(vm2.galleryKeys, before, "a failed save leaves no phantom photo")
        XCTAssertNotNil(vm2.saveError)
    }

    func test_VenueProfileViewModel_uploadGalleryImage_performance() async {
        let v = Make.venue("mine", owner: Make.user("me", isDJ: false)); db.seed([v])
        let vm = VenueProfileViewModel(); vm.apply(venue: v)
        let t = await elapsed { for _ in 0..<5 { await vm.uploadGalleryImage(self.image(2_000, 1_500)) } }
        XCTAssertLessThan(t, 6.0, "\(t)s")
        XCTAssertEqual(vm.galleryKeys.count, 5)
    }

    func test_VenueProfileViewModel_submitCompliance_security() async {
        let vm = VenueProfileViewModel(); vm.apply(venue: Make.venue("theirs", owner: Make.user("x")))
        db.seed([Make.venue("theirs", owner: Make.user("x"))])
        do { try await vm.submitCompliance(licenseType: "L", contractorName: "C"); XCTFail("filed for another owner's venue") } catch {}
    }

    func test_VenueProfileViewModel_submitCompliance_performance() async throws {
        let v = Make.venue("mine", owner: Make.user("me", isDJ: false)); db.seed([v])
        let vm = VenueProfileViewModel(); vm.apply(venue: v)
        let t = try await elapsed(iterations: 300) { try await vm.submitCompliance(licenseType: "L", contractorName: "C") }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    // MARK: - Remaining service / motion functions

    func test_EventService_upcomingEvents_security() async throws {
        db.seed([Make.event("hosted", host: "dj", days: 3), Make.event("cancelled", host: "dj", days: 3, status: "cancelled"),
                 Make.event("past", host: "dj", days: -3), Make.event("other", host: "x", days: 3)])
        let events = try await EventService.upcomingEvents(forDJ: "dj")
        XCTAssertEqual(events.map(\.id), ["hosted"], "upcoming, not cancelled, this DJ only")
    }

    func test_EventService_upcomingEvents_performance() async throws {
        let events = Make.many(3_000) { Make.event("e\($0)", host: $0 % 100 == 0 ? "dj" : "x", days: 3) }
        db.seed(events); db.seed((0..<30).map { Make.link(event: events[$0 * 7 + 1], dj: "dj") })
        db.resetCounters()
        let t = try await elapsed { _ = try await EventService.upcomingEvents(forDJ: "dj") }
        XCTAssertLessThan(t, 2.0, "\(t)s")
        XCTAssertEqual(db.unfilteredQueryCount, 0)
    }

    func test_Motion_sanitizedAnchor_security() {
        XCTAssertEqual(Motion.sanitizedAnchor(UnitPoint(x: -.infinity, y: 0)), .center)
        XCTAssertEqual(Motion.sanitizedAnchor(UnitPoint(x: 0.2, y: 0.8)), UnitPoint(x: 0.2, y: 0.8))
    }

    func test_Motion_sanitizedAnchor_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = Motion.sanitizedAnchor(.topLeading) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    // MARK: - Prompt pure helpers

    func test_ChatRow_relativeTime_security() {
        let now = Date()
        XCTAssertFalse(ChatRow.relativeTime(.distantFuture, now: now).isEmpty, "absurd timestamps still format")
        XCTAssertFalse(ChatRow.relativeTime(.distantPast, now: now).isEmpty)
    }

    func test_ChatRow_relativeTime_performance() {
        let now = Date(), then = now.addingTimeInterval(-3_600)
        let t = elapsedSync(iterations: 20_000) { _ = ChatRow.relativeTime(then, now: now) }
        XCTAssertLessThan(t, 2.0, "shared formatter: \(t)s")
    }

    func test_EventDatePickerView_hasConflict_security() {
        let cal = Calendar.current
        let booked: Set<Date> = [cal.startOfDay(for: Date().addingTimeInterval(86_400))]
        XCTAssertTrue(EventDatePickerView.hasConflict(Date().addingTimeInterval(86_400 + 60), booked: booked),
                      "any time on a booked day conflicts")
        XCTAssertFalse(EventDatePickerView.hasConflict(Date(), booked: []))
    }

    func test_EventDatePickerView_hasConflict_performance() {
        let cal = Calendar.current
        let booked = Set((0..<365).map { cal.startOfDay(for: Date().addingTimeInterval(Double($0) * 86_400)) })
        let t = elapsedSync(iterations: 50_000) { _ = EventDatePickerView.hasConflict(Date(), booked: booked) }
        XCTAssertLessThan(t, 2.0, "set lookup: \(t)s")
    }

    func test_CustomMapView_glowStrength_security() {
        let events = Make.many(500) { Make.event("e\($0)", venueID: "v", days: 1) }
        XCTAssertLessThanOrEqual(CustomMapView.glowStrength(for: "v", in: events), 1.0)
        XCTAssertEqual(CustomMapView.glowStrength(for: "v", in: [Make.event("past", venueID: "v", days: -1)]), 0, "past events don't glow")
    }

    func test_CustomMapView_glowStrength_performance() {
        let events = Make.many(5_000) { Make.event("e\($0)", venueID: "v\($0 % 200)", days: $0 % 30) }
        let t = elapsedSync(iterations: 200) { _ = CustomMapView.glowStrength(for: "v3", in: events) }
        XCTAssertLessThan(t, 3.0, "200 pins × 5k events: \(t)s")
    }

    func test_CustomMapView_upcomingEvents_security() {
        let dates = CustomMapView.upcomingEvents(for: "v", in: [Make.event("a", venueID: "v", days: 2), Make.event("b", venueID: "w", days: 2),
                                                                Make.event("c", venueID: "v", days: -2)])
        XCTAssertEqual(dates.count, 1, "only this venue's future events")
    }

    func test_CustomMapView_upcomingEvents_performance() {
        let events = Make.many(5_000) { Make.event("e\($0)", venueID: "v\($0 % 200)", days: 1 + $0 % 30) }
        let t = elapsedSync(iterations: 200) { _ = CustomMapView.upcomingEvents(for: "v3", in: events) }
        XCTAssertLessThan(t, 3.0, "shared DateFormatter: \(t)s")
    }

    func test_CustomMapView_firstUpcomingEvent_security() {
        let next = CustomMapView.firstUpcomingEvent(for: "v", in: [Make.event("later", venueID: "v", days: 9), Make.event("soon", venueID: "v", days: 1),
                                                                   Make.event("past", venueID: "v", days: -1)])
        XCTAssertEqual(next?.id, "soon", "tickets offered for the soonest future event, never a past one")
    }

    func test_CustomMapView_firstUpcomingEvent_performance() {
        let events = Make.many(5_000) { Make.event("e\($0)", venueID: "v\($0 % 200)", days: 1 + $0 % 30) }
        let t = elapsedSync(iterations: 200) { _ = CustomMapView.firstUpcomingEvent(for: "v3", in: events) }
        XCTAssertLessThan(t, 3.0, "min, not a sort: \(t)s")
    }

    func test_MapSearchView_resultCount_security() {
        let r = SearchResults(djs: [Make.user("a")], events: [], venues: [])
        XCTAssertEqual(MapSearchView.resultCount(for: .djs, in: r), 1)
        XCTAssertEqual(MapSearchView.resultCount(for: .venues, in: r), 0, "counts never bleed across categories")
    }

    func test_MapSearchView_resultCount_performance() {
        let r = SearchResults(djs: Make.many(50) { Make.user("u\($0)") }, events: [], venues: [])
        let t = elapsedSync(iterations: 500_000) { _ = MapSearchView.resultCount(for: .djs, in: r) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_UnevenCornerClip_path_security() {
        guard #available(iOS 17.0, *) else { return }
        for r in [CGFloat.nan, -50, .infinity] {
            let p = UnevenCornerClip(radius: r, corners: .allCorners).path(in: CGRect(x: 0, y: 0, width: 100, height: 40))
            XCTAssertTrue(p.boundingRect.width.isFinite, "radius \(r) yields a finite path")
        }
    }

    func test_UnevenCornerClip_path_performance() {
        guard #available(iOS 17.0, *) else { return }
        let s = UnevenCornerClip(radius: 20, corners: [.topLeft, .topRight])
        let t = elapsedSync(iterations: 50_000) { _ = s.path(in: CGRect(x: 0, y: 0, width: 390, height: 600)) }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_UnevenCornerClip_safeRadius_security() {
        guard #available(iOS 17.0, *) else { return }
        XCTAssertEqual(UnevenCornerClip.safeRadius(.nan, in: CGRect(x: 0, y: 0, width: 10, height: 10)), 0)
        XCTAssertEqual(UnevenCornerClip.safeRadius(-5, in: CGRect(x: 0, y: 0, width: 10, height: 10)), 0)
        XCTAssertEqual(UnevenCornerClip.safeRadius(99, in: CGRect(x: 0, y: 0, width: 10, height: 40)), 5)
    }

    func test_UnevenCornerClip_safeRadius_performance() {
        guard #available(iOS 17.0, *) else { return }
        let t = elapsedSync(iterations: 1_000_000) { _ = UnevenCornerClip.safeRadius(20, in: CGRect(x: 0, y: 0, width: 300, height: 200)) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_LegacyRoundedCorner_path_security() {
        for r in [CGFloat.nan, -50, .infinity] {
            let p = LegacyRoundedCorner(radius: r, corners: .allCorners).path(in: CGRect(x: 0, y: 0, width: 100, height: 40))
            XCTAssertTrue(p.boundingRect.width.isFinite, "radius \(r) yields a finite path")
        }
    }

    func test_LegacyRoundedCorner_path_performance() {
        let s = LegacyRoundedCorner(radius: 20, corners: [.topLeft, .topRight])
        let t = elapsedSync(iterations: 50_000) { _ = s.path(in: CGRect(x: 0, y: 0, width: 390, height: 600)) }
        XCTAssertLessThan(t, 3.0, "\(t)s")
    }

    func test_LegacyRoundedCorner_safeRadius_security() {
        XCTAssertEqual(LegacyRoundedCorner.safeRadius(.infinity, in: CGRect(x: 0, y: 0, width: 10, height: 10)), 0)
        XCTAssertEqual(LegacyRoundedCorner.safeRadius(3, in: CGRect(x: 0, y: 0, width: 10, height: 10)), 3)
    }

    func test_LegacyRoundedCorner_safeRadius_performance() {
        let t = elapsedSync(iterations: 1_000_000) { _ = LegacyRoundedCorner.safeRadius(20, in: CGRect(x: 0, y: 0, width: 300, height: 200)) }
        XCTAssertLessThan(t, 2.0, "\(t)s")
    }

    func test_ProfileScrollOffsetKey_reduce_security() {
        var v: CGFloat = 0
        ProfileScrollOffsetKey.reduce(value: &v) { .nan }
        XCTAssertEqual(v, 0, "a NaN offset can't trip the QR reveal")
        ProfileScrollOffsetKey.reduce(value: &v) { 120 }
        XCTAssertEqual(v, 120)
    }

    func test_ProfileScrollOffsetKey_reduce_performance() {
        var v: CGFloat = 0
        let t = elapsedSync(iterations: 1_000_000) { ProfileScrollOffsetKey.reduce(value: &v) { 42 } }
        XCTAssertLessThan(t, 2.0, "per-frame scroll ×1M: \(t)s")
    }
}

private extension Venue {
    func withCoords(_ lat: Double, _ lon: Double) -> Venue {
        var v = self; v.latitude = lat; v.longitude = lon; return v
    }
}
