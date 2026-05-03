import CloudKit
import Foundation
import SwiftData

extension Notification.Name {
    static let sakinahPendingShareChanged = Notification.Name("sakinah.pendingShareChanged")
}

@MainActor
final class CloudKitService {
    static let shared = CloudKitService()

    private enum RecordType {
        static let couple = "Couple"
        static let promptResponse = "PromptResponse"
        static let checkIn = "CheckIn"
        static let weeklyReflection = "WeeklyReflection"
        static let memory = "Memory"
        static let journalEntry = "JournalEntry"
        static let loveLetter = "LoveLetter"
        static let sharedGoal = "SharedGoal"
        static let wishItem = "WishItem"
    }

    private enum FieldKey {
        static let payload = "payload"
        static let updatedAt = "updatedAt"
        static let photoAsset = "photoAsset"
    }

    private enum DefaultsKey {
        static let pendingShare = "sakinah.cloudkit.pendingShare"
    }

    struct PendingShare: Codable, Sendable {
        let zoneName: String
        let ownerName: String
        let shareRecordName: String

        var zoneID: CKRecordZone.ID {
            CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName)
        }
    }

    private struct CouplePayload: Codable {
        let id: String
        let user1ID: String
        let user2ID: String
        let user1Name: String
        let user2Name: String
        let inviteCode: String
        let relationshipStageRaw: String
        let anniversaryDate: Date?
        let useHijriCalendar: Bool
        let createdAt: Date
        let updatedAt: Date
        let gardenStateData: Data?
    }

    private struct PromptResponsePayload: Codable {
        let id: String
        let promptID: String
        let coupleID: String
        let userID: String
        let responseText: String
        let createdAt: Date
        let updatedAt: Date
        let isRevealed: Bool
    }

    private struct CheckInPayload: Codable {
        let id: String
        let coupleID: String
        let userID: String
        let moodRaw: Int
        let note: String?
        let date: Date
        let updatedAt: Date
    }

    private struct WeeklyReflectionPayload: Codable {
        let id: String
        let coupleID: String
        let userID: String
        let weekStartDate: Date
        let communicationScore: Int
        let qualityTimeScore: Int
        let spiritualConnectionScore: Int
        let emotionalSafetyScore: Int
        let growthScore: Int
        let isSharedWithPartner: Bool
        let createdAt: Date
        let updatedAt: Date
    }

    private struct MemoryPayload: Codable {
        let id: String
        let coupleID: String
        let caption: String
        let date: Date
        let createdAt: Date
        let updatedAt: Date
    }

    private struct JournalEntryPayload: Codable {
        let id: String
        let coupleID: String
        let userID: String
        let authorName: String
        let content: String
        let isShared: Bool
        let createdAt: Date
        let updatedAt: Date
    }

    private struct LoveLetterPayload: Codable {
        let id: String
        let coupleID: String
        let senderID: String
        let senderName: String
        let recipientName: String
        let title: String
        let content: String
        let deliveryDate: Date
        let isDelivered: Bool
        let isRead: Bool
        let createdAt: Date
        let updatedAt: Date
    }

    private struct SharedGoalPayload: Codable {
        let id: String
        let coupleID: String
        let title: String
        let targetCount: Int
        let currentCount: Int
        let categoryRaw: String
        let deadline: Date
        let isCompleted: Bool
        let createdAt: Date
        let updatedAt: Date
    }

    private struct WishItemPayload: Codable {
        let id: String
        let coupleID: String
        let userID: String
        let text: String
        let note: String?
        let link: String?
        let createdAt: Date
        let updatedAt: Date
    }

    private struct LocalSnapshot {
        let couple: Couple
        let promptResponses: [PromptResponse]
        let checkIns: [CheckIn]
        let reflections: [WeeklyReflection]
        let memories: [Memory]
        let journalEntries: [JournalEntry]
        let letters: [LoveLetter]
        let goals: [SharedGoal]
        let wishes: [WishItem]
    }

    private struct RemoteSnapshot {
        var couple: CKRecord?
        var promptResponses: [String: CKRecord] = [:]
        var checkIns: [String: CKRecord] = [:]
        var reflections: [String: CKRecord] = [:]
        var memories: [String: CKRecord] = [:]
        var journalEntries: [String: CKRecord] = [:]
        var letters: [String: CKRecord] = [:]
        var goals: [String: CKRecord] = [:]
        var wishes: [String: CKRecord] = [:]
    }

    private let container = CKContainer.default()
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileManager = FileManager.default

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
    }

    var hasPendingAcceptedShare: Bool {
        pendingShare() != nil
    }

    func syncIfPossible(appState: AppState, context: ModelContext) async {
        guard appState.hasPremiumAccess else { return }
        guard let user = appState.currentUser else { return }

        do {
            try await attachPendingShareIfNeeded(appState: appState, context: context)

            guard let couple = appState.currentCouple else { return }

            appState.markSyncStarted()
            try await syncCouple(couple: couple, user: user, context: context)
            appState.markSyncFinished()
        } catch {
            appState.markSyncFailed(userFacingMessage(for: error))
        }
    }

    func createShareURL(appState: AppState, context: ModelContext) async throws -> URL {
        guard let user = appState.currentUser, let couple = appState.currentCouple else {
            throw CloudKitSyncError.missingCouple
        }

        try await syncCouple(couple: couple, user: user, context: context)

        let zoneID = zoneID(for: couple)
        let shareRecordID = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zoneID)
        let shareRecord: CKShare

        let fetchedShare = try? await fetchRecord(recordID: shareRecordID, from: privateDatabase)
        if let existingShare = fetchedShare as? CKShare {
            shareRecord = existingShare
        } else {
            shareRecord = CKShare(recordZoneID: zoneID)
        }

        let partnerLabel = partnerDisplayName(for: couple)
        shareRecord[CKShare.SystemFieldKey.title] = "\(couple.user1Name) and \(partnerLabel)" as CKRecordValue
        shareRecord.publicPermission = .none

        let saved = try await modifyRecords(
            recordsToSave: [shareRecord],
            recordIDsToDelete: [],
            database: privateDatabase
        )

        guard let savedShare = saved.first(where: { $0.recordID == shareRecordID }) as? CKShare,
              let url = savedShare.url else {
            throw CloudKitSyncError.shareUnavailable
        }

        couple.cloudShareRecordName = savedShare.recordID.recordName
        couple.cloudShareURLString = url.absoluteString
        couple.lastCloudSyncAt = Date()
        couple.touch()
        try? context.save()

        return url
    }

    func acceptShare(_ metadata: CKShare.Metadata) async throws {
        if metadata.participantStatus == .pending {
            try await acceptPendingShare(metadata)
        }

        let pending = PendingShare(
            zoneName: metadata.share.recordID.zoneID.zoneName,
            ownerName: metadata.share.recordID.zoneID.ownerName,
            shareRecordName: metadata.share.recordID.recordName
        )

        savePendingShare(pending)
        NotificationCenter.default.post(name: .sakinahPendingShareChanged, object: nil)
    }

    func deleteRemoteDataIfOwned(couple: Couple) async {
        guard isOwner(of: couple) else { return }

        do {
            try await deleteZone(zoneID(for: couple))
        } catch {}
    }

    private func attachPendingShareIfNeeded(appState: AppState, context: ModelContext) async throws {
        guard let currentUser = appState.currentUser else { return }
        guard let pending = pendingShare() else { return }

        let remoteSnapshot = try await fetchRemoteSnapshot(zoneID: pending.zoneID, database: sharedDatabase)
        guard let coupleRecord = remoteSnapshot.couple else {
            throw CloudKitSyncError.shareUnavailable
        }

        let payload = try decode(CouplePayload.self, from: coupleRecord)
        let sharedCouple = upsertCouple(
            from: payload,
            zoneID: pending.zoneID,
            shareRecordName: pending.shareRecordName,
            context: context
        )

        if let existingCouple = appState.currentCouple, existingCouple.id != sharedCouple.id {
            migrateLocalData(from: existingCouple.id, to: sharedCouple.id, context: context)
            context.delete(existingCouple)
        }

        if sharedCouple.user2ID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sharedCouple.user2ID = currentUser.id
            sharedCouple.user2Name = currentUser.name
            sharedCouple.touch()
        } else if sharedCouple.user1ID == currentUser.id {
            sharedCouple.user1Name = currentUser.name
            sharedCouple.touch()
        } else if sharedCouple.user2ID == currentUser.id {
            sharedCouple.user2Name = currentUser.name
            sharedCouple.touch()
        }

        currentUser.coupleID = sharedCouple.id
        currentUser.partnerID = sharedCouple.user1ID == currentUser.id ? sharedCouple.user2ID : sharedCouple.user1ID
        currentUser.touch()

        sharedCouple.cloudZoneName = pending.zoneName
        sharedCouple.cloudZoneOwnerName = pending.ownerName
        sharedCouple.cloudShareRecordName = pending.shareRecordName
        sharedCouple.lastCloudSyncAt = Date()

        try? context.save()

        appState.currentCouple = sharedCouple
        appState.markShareAttached()
        clearPendingShare()
    }

    private func syncCouple(couple: Couple, user: User, context: ModelContext) async throws {
        let zoneID = zoneID(for: couple)
        let database = database(for: couple)

        if database === privateDatabase {
            try await ensureZoneExists(zoneID)
        }

        let remoteSnapshot = try await fetchRemoteSnapshot(zoneID: zoneID, database: database)
        try mergeRemoteSnapshot(remoteSnapshot, into: couple, context: context)

        let refreshedSnapshot = snapshot(for: couple.id, fallbackCouple: couple, context: context)
        let recordsToSave = try buildRecordsToSave(
            from: refreshedSnapshot,
            remoteSnapshot: remoteSnapshot,
            zoneID: zoneID
        )

        if !recordsToSave.records.isEmpty {
            defer {
                recordsToSave.cleanupURLs.forEach { try? fileManager.removeItem(at: $0) }
            }

            _ = try await modifyRecords(
                recordsToSave: recordsToSave.records,
                recordIDsToDelete: [],
                database: database
            )
        }

        if user.coupleID != couple.id {
            user.coupleID = couple.id
            user.touch()
        }

        couple.lastCloudSyncAt = Date()
        try? context.save()
    }

    private func mergeRemoteSnapshot(_ remoteSnapshot: RemoteSnapshot, into localCouple: Couple, context: ModelContext) throws {
        if let remoteCoupleRecord = remoteSnapshot.couple {
            let payload = try decode(CouplePayload.self, from: remoteCoupleRecord)
            if payload.updatedAt > localCouple.updatedAt {
                apply(payload: payload, to: localCouple)
                localCouple.cloudZoneName = remoteCoupleRecord.recordID.zoneID.zoneName
                localCouple.cloudZoneOwnerName = remoteCoupleRecord.recordID.zoneID.ownerName
                localCouple.cloudShareRecordName = localCouple.cloudShareRecordName ?? CKRecordNameZoneWideShare
            }
        }

        try mergeRecords(
            remoteSnapshot.promptResponses,
            existing: dictionary(for: promptResponses(for: localCouple.id, context: context)),
            decode: { try self.decode(PromptResponsePayload.self, from: $0) },
            apply: apply(promptResponse:to:),
            insert: { payload in
                let model = PromptResponse(
                    id: payload.id,
                    promptID: payload.promptID,
                    coupleID: payload.coupleID,
                    userID: payload.userID,
                    responseText: payload.responseText,
                    createdAt: payload.createdAt,
                    isRevealed: payload.isRevealed
                )
                model.updatedAt = payload.updatedAt
                context.insert(model)
            }
        )

        try mergeRecords(
            remoteSnapshot.checkIns,
            existing: dictionary(for: checkIns(for: localCouple.id, context: context)),
            decode: { try self.decode(CheckInPayload.self, from: $0) },
            apply: apply(checkIn:to:),
            insert: { payload in
                let model = CheckIn(
                    id: payload.id,
                    coupleID: payload.coupleID,
                    userID: payload.userID,
                    mood: Mood(rawValue: payload.moodRaw) ?? .okay,
                    note: payload.note,
                    date: payload.date
                )
                model.updatedAt = payload.updatedAt
                context.insert(model)
            }
        )

        try mergeRecords(
            remoteSnapshot.reflections,
            existing: dictionary(for: reflections(for: localCouple.id, context: context)),
            decode: { try self.decode(WeeklyReflectionPayload.self, from: $0) },
            apply: apply(reflection:to:),
            insert: { payload in
                let model = WeeklyReflection(
                    id: payload.id,
                    coupleID: payload.coupleID,
                    userID: payload.userID,
                    weekStartDate: payload.weekStartDate,
                    communicationScore: payload.communicationScore,
                    qualityTimeScore: payload.qualityTimeScore,
                    spiritualConnectionScore: payload.spiritualConnectionScore,
                    emotionalSafetyScore: payload.emotionalSafetyScore,
                    growthScore: payload.growthScore,
                    isSharedWithPartner: payload.isSharedWithPartner,
                    createdAt: payload.createdAt
                )
                model.updatedAt = payload.updatedAt
                context.insert(model)
            }
        )

        try mergeRecords(
            remoteSnapshot.memories,
            existing: dictionary(for: memories(for: localCouple.id, context: context)),
            decode: { try self.decodeMemoryPayload(from: $0) },
            apply: apply(memory:to:),
            insert: { payload in
                let model = Memory(
                    id: payload.payload.id,
                    coupleID: payload.payload.coupleID,
                    caption: payload.payload.caption,
                    photoData: payload.photoData,
                    date: payload.payload.date,
                    createdAt: payload.payload.createdAt
                )
                model.updatedAt = payload.payload.updatedAt
                context.insert(model)
            }
        )

        try mergeRecords(
            remoteSnapshot.journalEntries,
            existing: dictionary(for: journalEntries(for: localCouple.id, context: context)),
            decode: { try self.decode(JournalEntryPayload.self, from: $0) },
            apply: apply(journalEntry:to:),
            insert: { payload in
                let model = JournalEntry(
                    id: payload.id,
                    coupleID: payload.coupleID,
                    userID: payload.userID,
                    authorName: payload.authorName,
                    content: payload.content,
                    isShared: payload.isShared,
                    createdAt: payload.createdAt
                )
                model.updatedAt = payload.updatedAt
                context.insert(model)
            }
        )

        try mergeRecords(
            remoteSnapshot.letters,
            existing: dictionary(for: letters(for: localCouple.id, context: context)),
            decode: { try self.decode(LoveLetterPayload.self, from: $0) },
            apply: apply(letter:to:),
            insert: { payload in
                let model = LoveLetter(
                    id: payload.id,
                    coupleID: payload.coupleID,
                    senderID: payload.senderID,
                    senderName: payload.senderName,
                    recipientName: payload.recipientName,
                    title: payload.title,
                    content: payload.content,
                    deliveryDate: payload.deliveryDate,
                    isDelivered: payload.isDelivered,
                    isRead: payload.isRead,
                    createdAt: payload.createdAt
                )
                model.updatedAt = payload.updatedAt
                context.insert(model)
            }
        )

        try mergeRecords(
            remoteSnapshot.goals,
            existing: dictionary(for: goals(for: localCouple.id, context: context)),
            decode: { try self.decode(SharedGoalPayload.self, from: $0) },
            apply: apply(goal:to:),
            insert: { payload in
                let model = SharedGoal(
                    id: payload.id,
                    coupleID: payload.coupleID,
                    title: payload.title,
                    targetCount: payload.targetCount,
                    currentCount: payload.currentCount,
                    category: GoalCategory(rawValue: payload.categoryRaw) ?? .other,
                    deadline: payload.deadline,
                    isCompleted: payload.isCompleted,
                    createdAt: payload.createdAt
                )
                model.updatedAt = payload.updatedAt
                context.insert(model)
            }
        )

        try mergeRecords(
            remoteSnapshot.wishes,
            existing: dictionary(for: wishes(for: localCouple.id, context: context)),
            decode: { try self.decode(WishItemPayload.self, from: $0) },
            apply: apply(wish:to:),
            insert: { payload in
                let model = WishItem(
                    id: payload.id,
                    coupleID: payload.coupleID,
                    userID: payload.userID,
                    text: payload.text,
                    note: payload.note,
                    link: payload.link,
                    createdAt: payload.createdAt
                )
                model.updatedAt = payload.updatedAt
                context.insert(model)
            }
        )

        try? context.save()
    }

    private func buildRecordsToSave(from snapshot: LocalSnapshot, remoteSnapshot: RemoteSnapshot, zoneID: CKRecordZone.ID) throws -> (records: [CKRecord], cleanupURLs: [URL]) {
        var records: [CKRecord] = []
        var cleanupURLs: [URL] = []

        let coupleRecord = try record(for: snapshot.couple, zoneID: zoneID, existing: remoteSnapshot.couple)
        if shouldSave(localUpdatedAt: snapshot.couple.updatedAt, remoteRecord: remoteSnapshot.couple) {
            records.append(coupleRecord)
        }

        for response in snapshot.promptResponses where shouldSave(localUpdatedAt: response.updatedAt, remoteRecord: remoteSnapshot.promptResponses[response.id]) {
            records.append(try record(for: response, zoneID: zoneID, existing: remoteSnapshot.promptResponses[response.id]))
        }

        for checkIn in snapshot.checkIns where shouldSave(localUpdatedAt: checkIn.updatedAt, remoteRecord: remoteSnapshot.checkIns[checkIn.id]) {
            records.append(try record(for: checkIn, zoneID: zoneID, existing: remoteSnapshot.checkIns[checkIn.id]))
        }

        for reflection in snapshot.reflections where shouldSave(localUpdatedAt: reflection.updatedAt, remoteRecord: remoteSnapshot.reflections[reflection.id]) {
            records.append(try record(for: reflection, zoneID: zoneID, existing: remoteSnapshot.reflections[reflection.id]))
        }

        for memory in snapshot.memories where shouldSave(localUpdatedAt: memory.updatedAt, remoteRecord: remoteSnapshot.memories[memory.id]) {
            let built = try record(for: memory, zoneID: zoneID, existing: remoteSnapshot.memories[memory.id])
            records.append(built.record)
            cleanupURLs.append(contentsOf: built.cleanupURLs)
        }

        for entry in snapshot.journalEntries where shouldSave(localUpdatedAt: entry.updatedAt, remoteRecord: remoteSnapshot.journalEntries[entry.id]) {
            records.append(try record(for: entry, zoneID: zoneID, existing: remoteSnapshot.journalEntries[entry.id]))
        }

        for letter in snapshot.letters where shouldSave(localUpdatedAt: letter.updatedAt, remoteRecord: remoteSnapshot.letters[letter.id]) {
            records.append(try record(for: letter, zoneID: zoneID, existing: remoteSnapshot.letters[letter.id]))
        }

        for goal in snapshot.goals where shouldSave(localUpdatedAt: goal.updatedAt, remoteRecord: remoteSnapshot.goals[goal.id]) {
            records.append(try record(for: goal, zoneID: zoneID, existing: remoteSnapshot.goals[goal.id]))
        }

        for wish in snapshot.wishes where shouldSave(localUpdatedAt: wish.updatedAt, remoteRecord: remoteSnapshot.wishes[wish.id]) {
            records.append(try record(for: wish, zoneID: zoneID, existing: remoteSnapshot.wishes[wish.id]))
        }

        return (records, cleanupURLs)
    }

    private func fetchRemoteSnapshot(zoneID: CKRecordZone.ID, database: CKDatabase) async throws -> RemoteSnapshot {
        async let coupleRecords = query(recordType: RecordType.couple, zoneID: zoneID, database: database)
        async let responseRecords = query(recordType: RecordType.promptResponse, zoneID: zoneID, database: database)
        async let checkInRecords = query(recordType: RecordType.checkIn, zoneID: zoneID, database: database)
        async let reflectionRecords = query(recordType: RecordType.weeklyReflection, zoneID: zoneID, database: database)
        async let memoryRecords = query(recordType: RecordType.memory, zoneID: zoneID, database: database)
        async let journalRecords = query(recordType: RecordType.journalEntry, zoneID: zoneID, database: database)
        async let letterRecords = query(recordType: RecordType.loveLetter, zoneID: zoneID, database: database)
        async let goalRecords = query(recordType: RecordType.sharedGoal, zoneID: zoneID, database: database)
        async let wishRecords = query(recordType: RecordType.wishItem, zoneID: zoneID, database: database)

        let resolvedCoupleRecords = try await coupleRecords
        var snapshot = RemoteSnapshot()
        snapshot.couple = resolvedCoupleRecords.first
        snapshot.promptResponses = dictionaryFromRemote(try await responseRecords)
        snapshot.checkIns = dictionaryFromRemote(try await checkInRecords)
        snapshot.reflections = dictionaryFromRemote(try await reflectionRecords)
        snapshot.memories = dictionaryFromRemote(try await memoryRecords)
        snapshot.journalEntries = dictionaryFromRemote(try await journalRecords)
        snapshot.letters = dictionaryFromRemote(try await letterRecords)
        snapshot.goals = dictionaryFromRemote(try await goalRecords)
        snapshot.wishes = dictionaryFromRemote(try await wishRecords)
        return snapshot
    }

    private func snapshot(for coupleID: String, fallbackCouple: Couple, context: ModelContext) -> LocalSnapshot {
        let predicate = #Predicate<Couple> { $0.id == coupleID }
        let descriptor = FetchDescriptor<Couple>(predicate: predicate)
        let couple = ((try? context.fetch(descriptor))?.first) ?? fallbackCouple

        return LocalSnapshot(
            couple: couple,
            promptResponses: promptResponses(for: coupleID, context: context),
            checkIns: checkIns(for: coupleID, context: context),
            reflections: reflections(for: coupleID, context: context),
            memories: memories(for: coupleID, context: context),
            journalEntries: journalEntries(for: coupleID, context: context),
            letters: letters(for: coupleID, context: context),
            goals: goals(for: coupleID, context: context),
            wishes: wishes(for: coupleID, context: context)
        )
    }

    private func upsertCouple(from payload: CouplePayload, zoneID: CKRecordZone.ID, shareRecordName: String, context: ModelContext) -> Couple {
        let predicate = #Predicate<Couple> { $0.id == payload.id }
        let descriptor = FetchDescriptor<Couple>(predicate: predicate)

        if let existing = (try? context.fetch(descriptor))?.first {
            apply(payload: payload, to: existing)
            existing.cloudZoneName = zoneID.zoneName
            existing.cloudZoneOwnerName = zoneID.ownerName
            existing.cloudShareRecordName = shareRecordName
            return existing
        }

        let model = Couple(
            id: payload.id,
            user1ID: payload.user1ID,
            user2ID: payload.user2ID,
            user1Name: payload.user1Name,
            user2Name: payload.user2Name,
            inviteCode: payload.inviteCode,
            relationshipStage: RelationshipStage(rawValue: payload.relationshipStageRaw) ?? .married,
            anniversaryDate: payload.anniversaryDate,
            useHijriCalendar: payload.useHijriCalendar,
            createdAt: payload.createdAt
        )
        model.updatedAt = payload.updatedAt
        model.gardenStateData = payload.gardenStateData
        model.cloudZoneName = zoneID.zoneName
        model.cloudZoneOwnerName = zoneID.ownerName
        model.cloudShareRecordName = shareRecordName
        context.insert(model)
        return model
    }

    private func migrateLocalData(from sourceCoupleID: String, to destinationCoupleID: String, context: ModelContext) {
        for response in promptResponses(for: sourceCoupleID, context: context) {
            response.coupleID = destinationCoupleID
            response.touch()
        }

        for checkIn in checkIns(for: sourceCoupleID, context: context) {
            checkIn.coupleID = destinationCoupleID
            checkIn.touch()
        }

        for reflection in reflections(for: sourceCoupleID, context: context) {
            reflection.coupleID = destinationCoupleID
            reflection.touch()
        }

        for memory in memories(for: sourceCoupleID, context: context) {
            memory.coupleID = destinationCoupleID
            memory.touch()
        }

        for entry in journalEntries(for: sourceCoupleID, context: context) {
            entry.coupleID = destinationCoupleID
            entry.touch()
        }

        for letter in letters(for: sourceCoupleID, context: context) {
            letter.coupleID = destinationCoupleID
            letter.touch()
        }

        for goal in goals(for: sourceCoupleID, context: context) {
            goal.coupleID = destinationCoupleID
            goal.touch()
        }

        for wish in wishes(for: sourceCoupleID, context: context) {
            wish.coupleID = destinationCoupleID
            wish.touch()
        }

        try? context.save()
    }

    private func record(for couple: Couple, zoneID: CKRecordZone.ID, existing: CKRecord?) throws -> CKRecord {
        let payload = CouplePayload(
            id: couple.id,
            user1ID: couple.user1ID,
            user2ID: couple.user2ID,
            user1Name: couple.user1Name,
            user2Name: couple.user2Name,
            inviteCode: couple.inviteCode,
            relationshipStageRaw: couple.relationshipStageRaw,
            anniversaryDate: couple.anniversaryDate,
            useHijriCalendar: couple.useHijriCalendar,
            createdAt: couple.createdAt,
            updatedAt: couple.updatedAt,
            gardenStateData: couple.gardenStateData
        )
        return try configuredRecord(
            type: RecordType.couple,
            id: couple.id,
            zoneID: zoneID,
            updatedAt: couple.updatedAt,
            payload: payload,
            existing: existing
        )
    }

    private func record(for model: PromptResponse, zoneID: CKRecordZone.ID, existing: CKRecord?) throws -> CKRecord {
        try configuredRecord(
            type: RecordType.promptResponse,
            id: model.id,
            zoneID: zoneID,
            updatedAt: model.updatedAt,
            payload: PromptResponsePayload(
                id: model.id,
                promptID: model.promptID,
                coupleID: model.coupleID,
                userID: model.userID,
                responseText: model.responseText,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt,
                isRevealed: model.isRevealed
            ),
            existing: existing
        )
    }

    private func record(for model: CheckIn, zoneID: CKRecordZone.ID, existing: CKRecord?) throws -> CKRecord {
        try configuredRecord(
            type: RecordType.checkIn,
            id: model.id,
            zoneID: zoneID,
            updatedAt: model.updatedAt,
            payload: CheckInPayload(
                id: model.id,
                coupleID: model.coupleID,
                userID: model.userID,
                moodRaw: model.moodRaw,
                note: model.note,
                date: model.date,
                updatedAt: model.updatedAt
            ),
            existing: existing
        )
    }

    private func record(for model: WeeklyReflection, zoneID: CKRecordZone.ID, existing: CKRecord?) throws -> CKRecord {
        try configuredRecord(
            type: RecordType.weeklyReflection,
            id: model.id,
            zoneID: zoneID,
            updatedAt: model.updatedAt,
            payload: WeeklyReflectionPayload(
                id: model.id,
                coupleID: model.coupleID,
                userID: model.userID,
                weekStartDate: model.weekStartDate,
                communicationScore: model.communicationScore,
                qualityTimeScore: model.qualityTimeScore,
                spiritualConnectionScore: model.spiritualConnectionScore,
                emotionalSafetyScore: model.emotionalSafetyScore,
                growthScore: model.growthScore,
                isSharedWithPartner: model.isSharedWithPartner,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt
            ),
            existing: existing
        )
    }

    private func record(for model: Memory, zoneID: CKRecordZone.ID, existing: CKRecord?) throws -> (record: CKRecord, cleanupURLs: [URL]) {
        let record = CKRecord(
            recordType: RecordType.memory,
            recordID: existing?.recordID ?? CKRecord.ID(recordName: model.id, zoneID: zoneID)
        )
        let payload = MemoryPayload(
            id: model.id,
            coupleID: model.coupleID,
            caption: model.caption,
            date: model.date,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
        record[FieldKey.payload] = try encoder.encode(payload) as NSData
        record[FieldKey.updatedAt] = model.updatedAt as CKRecordValue

        var cleanupURLs: [URL] = []

        if let photoData = model.photoData {
            let tempURL = fileManager.temporaryDirectory
                .appendingPathComponent("sakinah-memory-\(model.id)-\(UUID().uuidString).jpg")
            try photoData.write(to: tempURL, options: .atomic)
            record[FieldKey.photoAsset] = CKAsset(fileURL: tempURL)
            cleanupURLs.append(tempURL)
        } else {
            record[FieldKey.photoAsset] = nil
        }

        return (record, cleanupURLs)
    }

    private func record(for model: JournalEntry, zoneID: CKRecordZone.ID, existing: CKRecord?) throws -> CKRecord {
        try configuredRecord(
            type: RecordType.journalEntry,
            id: model.id,
            zoneID: zoneID,
            updatedAt: model.updatedAt,
            payload: JournalEntryPayload(
                id: model.id,
                coupleID: model.coupleID,
                userID: model.userID,
                authorName: model.authorName,
                content: model.content,
                isShared: model.isShared,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt
            ),
            existing: existing
        )
    }

    private func record(for model: LoveLetter, zoneID: CKRecordZone.ID, existing: CKRecord?) throws -> CKRecord {
        try configuredRecord(
            type: RecordType.loveLetter,
            id: model.id,
            zoneID: zoneID,
            updatedAt: model.updatedAt,
            payload: LoveLetterPayload(
                id: model.id,
                coupleID: model.coupleID,
                senderID: model.senderID,
                senderName: model.senderName,
                recipientName: model.recipientName,
                title: model.title,
                content: model.content,
                deliveryDate: model.deliveryDate,
                isDelivered: model.isDelivered,
                isRead: model.isRead,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt
            ),
            existing: existing
        )
    }

    private func record(for model: SharedGoal, zoneID: CKRecordZone.ID, existing: CKRecord?) throws -> CKRecord {
        try configuredRecord(
            type: RecordType.sharedGoal,
            id: model.id,
            zoneID: zoneID,
            updatedAt: model.updatedAt,
            payload: SharedGoalPayload(
                id: model.id,
                coupleID: model.coupleID,
                title: model.title,
                targetCount: model.targetCount,
                currentCount: model.currentCount,
                categoryRaw: model.categoryRaw,
                deadline: model.deadline,
                isCompleted: model.isCompleted,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt
            ),
            existing: existing
        )
    }

    private func record(for model: WishItem, zoneID: CKRecordZone.ID, existing: CKRecord?) throws -> CKRecord {
        try configuredRecord(
            type: RecordType.wishItem,
            id: model.id,
            zoneID: zoneID,
            updatedAt: model.updatedAt,
            payload: WishItemPayload(
                id: model.id,
                coupleID: model.coupleID,
                userID: model.userID,
                text: model.text,
                note: model.note,
                link: model.link,
                createdAt: model.createdAt,
                updatedAt: model.updatedAt
            ),
            existing: existing
        )
    }

    private func configuredRecord<T: Encodable>(type: String, id: String, zoneID: CKRecordZone.ID, updatedAt: Date, payload: T, existing: CKRecord?) throws -> CKRecord {
        let record = CKRecord(
            recordType: type,
            recordID: existing?.recordID ?? CKRecord.ID(recordName: id, zoneID: zoneID)
        )
        record[FieldKey.payload] = try encoder.encode(payload) as NSData
        record[FieldKey.updatedAt] = updatedAt as CKRecordValue
        return record
    }

    private func decode<T: Decodable>(_ type: T.Type, from record: CKRecord) throws -> T {
        guard let payload = record[FieldKey.payload] as? Data else {
            throw CloudKitSyncError.invalidRecordPayload
        }
        return try decoder.decode(type, from: payload)
    }

    private func decodeMemoryPayload(from record: CKRecord) throws -> (payload: MemoryPayload, photoData: Data?) {
        let payload = try decode(MemoryPayload.self, from: record)
        let photoData: Data?

        if let asset = record[FieldKey.photoAsset] as? CKAsset,
           let fileURL = asset.fileURL {
            photoData = try? Data(contentsOf: fileURL)
        } else {
            photoData = nil
        }

        return (payload, photoData)
    }

    private func apply(payload: CouplePayload, to couple: Couple) {
        couple.user1ID = payload.user1ID
        couple.user2ID = payload.user2ID
        couple.user1Name = payload.user1Name
        couple.user2Name = payload.user2Name
        couple.inviteCode = payload.inviteCode
        couple.relationshipStageRaw = payload.relationshipStageRaw
        couple.anniversaryDate = payload.anniversaryDate
        couple.useHijriCalendar = payload.useHijriCalendar
        couple.createdAt = payload.createdAt
        couple.updatedAt = payload.updatedAt
        couple.gardenStateData = payload.gardenStateData
    }

    private func apply(promptResponse payload: PromptResponsePayload, to model: PromptResponse) {
        guard payload.updatedAt > model.updatedAt else { return }
        model.promptID = payload.promptID
        model.coupleID = payload.coupleID
        model.userID = payload.userID
        model.responseText = payload.responseText
        model.createdAt = payload.createdAt
        model.updatedAt = payload.updatedAt
        model.isRevealed = payload.isRevealed
    }

    private func apply(checkIn payload: CheckInPayload, to model: CheckIn) {
        guard payload.updatedAt > model.updatedAt else { return }
        model.coupleID = payload.coupleID
        model.userID = payload.userID
        model.moodRaw = payload.moodRaw
        model.note = payload.note
        model.date = payload.date
        model.updatedAt = payload.updatedAt
    }

    private func apply(reflection payload: WeeklyReflectionPayload, to model: WeeklyReflection) {
        guard payload.updatedAt > model.updatedAt else { return }
        model.coupleID = payload.coupleID
        model.userID = payload.userID
        model.weekStartDate = payload.weekStartDate
        model.communicationScore = payload.communicationScore
        model.qualityTimeScore = payload.qualityTimeScore
        model.spiritualConnectionScore = payload.spiritualConnectionScore
        model.emotionalSafetyScore = payload.emotionalSafetyScore
        model.growthScore = payload.growthScore
        model.isSharedWithPartner = payload.isSharedWithPartner
        model.createdAt = payload.createdAt
        model.updatedAt = payload.updatedAt
    }

    private func apply(memory payload: (payload: MemoryPayload, photoData: Data?), to model: Memory) {
        guard payload.payload.updatedAt > model.updatedAt else { return }
        model.coupleID = payload.payload.coupleID
        model.caption = payload.payload.caption
        model.photoData = payload.photoData
        model.date = payload.payload.date
        model.createdAt = payload.payload.createdAt
        model.updatedAt = payload.payload.updatedAt
    }

    private func apply(journalEntry payload: JournalEntryPayload, to model: JournalEntry) {
        guard payload.updatedAt > model.updatedAt else { return }
        model.coupleID = payload.coupleID
        model.userID = payload.userID
        model.authorName = payload.authorName
        model.content = payload.content
        model.isShared = payload.isShared
        model.createdAt = payload.createdAt
        model.updatedAt = payload.updatedAt
    }

    private func apply(letter payload: LoveLetterPayload, to model: LoveLetter) {
        guard payload.updatedAt > model.updatedAt else { return }
        model.coupleID = payload.coupleID
        model.senderID = payload.senderID
        model.senderName = payload.senderName
        model.recipientName = payload.recipientName
        model.title = payload.title
        model.content = payload.content
        model.deliveryDate = payload.deliveryDate
        model.isDelivered = payload.isDelivered
        model.isRead = payload.isRead
        model.createdAt = payload.createdAt
        model.updatedAt = payload.updatedAt
    }

    private func apply(goal payload: SharedGoalPayload, to model: SharedGoal) {
        guard payload.updatedAt > model.updatedAt else { return }
        model.coupleID = payload.coupleID
        model.title = payload.title
        model.targetCount = payload.targetCount
        model.currentCount = payload.currentCount
        model.categoryRaw = payload.categoryRaw
        model.deadline = payload.deadline
        model.isCompleted = payload.isCompleted
        model.createdAt = payload.createdAt
        model.updatedAt = payload.updatedAt
    }

    private func apply(wish payload: WishItemPayload, to model: WishItem) {
        guard payload.updatedAt > model.updatedAt else { return }
        model.coupleID = payload.coupleID
        model.userID = payload.userID
        model.text = payload.text
        model.note = payload.note
        model.link = payload.link
        model.createdAt = payload.createdAt
        model.updatedAt = payload.updatedAt
    }

    private func mergeRecords<Model, Payload>(
        _ remoteRecords: [String: CKRecord],
        existing localRecords: [String: Model],
        decode: (CKRecord) throws -> Payload,
        apply: (Payload, Model) -> Void,
        insert: (Payload) -> Void
    ) throws {
        for (id, record) in remoteRecords {
            let payload = try decode(record)

            if let local = localRecords[id] {
                apply(payload, local)
            } else {
                insert(payload)
            }
        }
    }

    private func dictionary(for models: [PromptResponse]) -> [String: PromptResponse] {
        Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
    }

    private func dictionary(for models: [CheckIn]) -> [String: CheckIn] {
        Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
    }

    private func dictionary(for models: [WeeklyReflection]) -> [String: WeeklyReflection] {
        Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
    }

    private func dictionary(for models: [Memory]) -> [String: Memory] {
        Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
    }

    private func dictionary(for models: [JournalEntry]) -> [String: JournalEntry] {
        Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
    }

    private func dictionary(for models: [LoveLetter]) -> [String: LoveLetter] {
        Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
    }

    private func dictionary(for models: [SharedGoal]) -> [String: SharedGoal] {
        Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
    }

    private func dictionary(for models: [WishItem]) -> [String: WishItem] {
        Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
    }

    private func dictionaryFromRemote(_ records: [CKRecord]) -> [String: CKRecord] {
        Dictionary(uniqueKeysWithValues: records.map { ($0.recordID.recordName, $0) })
    }

    private func shouldSave(localUpdatedAt: Date, remoteRecord: CKRecord?) -> Bool {
        guard let remoteRecord else { return true }
        let remoteUpdatedAt = (remoteRecord[FieldKey.updatedAt] as? Date) ?? .distantPast
        return localUpdatedAt > remoteUpdatedAt
    }

    private func promptResponses(for coupleID: String, context: ModelContext) -> [PromptResponse] {
        let predicate = #Predicate<PromptResponse> { $0.coupleID == coupleID }
        return (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private func checkIns(for coupleID: String, context: ModelContext) -> [CheckIn] {
        let predicate = #Predicate<CheckIn> { $0.coupleID == coupleID }
        return (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private func reflections(for coupleID: String, context: ModelContext) -> [WeeklyReflection] {
        let predicate = #Predicate<WeeklyReflection> { $0.coupleID == coupleID }
        return (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private func memories(for coupleID: String, context: ModelContext) -> [Memory] {
        let predicate = #Predicate<Memory> { $0.coupleID == coupleID }
        return (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private func journalEntries(for coupleID: String, context: ModelContext) -> [JournalEntry] {
        let predicate = #Predicate<JournalEntry> { $0.coupleID == coupleID }
        return (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private func letters(for coupleID: String, context: ModelContext) -> [LoveLetter] {
        let predicate = #Predicate<LoveLetter> { $0.coupleID == coupleID }
        return (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private func goals(for coupleID: String, context: ModelContext) -> [SharedGoal] {
        let predicate = #Predicate<SharedGoal> { $0.coupleID == coupleID }
        return (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private func wishes(for coupleID: String, context: ModelContext) -> [WishItem] {
        let predicate = #Predicate<WishItem> { $0.coupleID == coupleID }
        return (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []
    }

    private func zoneID(for couple: Couple) -> CKRecordZone.ID {
        CKRecordZone.ID(
            zoneName: couple.cloudZoneName ?? "couple.\(couple.id)",
            ownerName: couple.cloudZoneOwnerName ?? CKCurrentUserDefaultName
        )
    }

    private func database(for couple: Couple) -> CKDatabase {
        isOwner(of: couple) ? privateDatabase : sharedDatabase
    }

    private func isOwner(of couple: Couple) -> Bool {
        let ownerName = couple.cloudZoneOwnerName ?? CKCurrentUserDefaultName
        return ownerName == CKCurrentUserDefaultName
    }

    private func partnerDisplayName(for couple: Couple) -> String {
        let trimmed = couple.user2Name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "your spouse" : trimmed
    }

    private func ensureZoneExists(_ zoneID: CKRecordZone.ID) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let zone = CKRecordZone(zoneID: zoneID)
            let operation = CKModifyRecordZonesOperation(
                recordZonesToSave: [zone],
                recordZoneIDsToDelete: nil
            )
            operation.modifyRecordZonesCompletionBlock = { _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
            privateDatabase.add(operation)
        }
    }

    private func deleteZone(_ zoneID: CKRecordZone.ID) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordZonesOperation(
                recordZonesToSave: nil,
                recordZoneIDsToDelete: [zoneID]
            )
            operation.modifyRecordZonesCompletionBlock = { _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
            privateDatabase.add(operation)
        }
    }

    private func query(recordType: String, zoneID: CKRecordZone.ID, database: CKDatabase) async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { continuation in
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            database.perform(query, inZoneWith: zoneID) { records, error in
                if let ckError = error as? CKError, ckError.code == .unknownItem {
                    continuation.resume(returning: [])
                    return
                }

                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: records ?? [])
                }
            }
        }
    }

    private func fetchRecord(recordID: CKRecord.ID, from database: CKDatabase) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            database.fetch(withRecordID: recordID) { record, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let record {
                    continuation.resume(returning: record)
                } else {
                    continuation.resume(throwing: CloudKitSyncError.recordNotFound)
                }
            }
        }
    }

    private func modifyRecords(recordsToSave: [CKRecord], recordIDsToDelete: [CKRecord.ID], database: CKDatabase) async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKModifyRecordsOperation(
                recordsToSave: recordsToSave,
                recordIDsToDelete: recordIDsToDelete.isEmpty ? nil : recordIDsToDelete
            )
            operation.savePolicy = .changedKeys
            operation.isAtomic = false
            operation.modifyRecordsCompletionBlock = { savedRecords, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: savedRecords ?? [])
                }
            }
            database.add(operation)
        }
    }

    private func acceptPendingShare(_ metadata: CKShare.Metadata) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
            operation.acceptSharesCompletionBlock = { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
            container.add(operation)
        }
    }

    private func pendingShare() -> PendingShare? {
        guard let data = defaults.data(forKey: DefaultsKey.pendingShare) else { return nil }
        return try? decoder.decode(PendingShare.self, from: data)
    }

    private func savePendingShare(_ pendingShare: PendingShare) {
        defaults.set(try? encoder.encode(pendingShare), forKey: DefaultsKey.pendingShare)
    }

    private func clearPendingShare() {
        defaults.removeObject(forKey: DefaultsKey.pendingShare)
    }

    private func userFacingMessage(for error: Error) -> String {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                return "Sign in to iCloud to invite your spouse and sync your shared space."
            case .networkUnavailable, .networkFailure:
                return "Sakinah will sync again when you’re back online."
            case .permissionFailure:
                return "This shared space isn’t available with the current iCloud account."
            default:
                break
            }
        }

        return "Your shared space couldn’t sync right now."
    }
}

private enum CloudKitSyncError: Error {
    case missingCouple
    case invalidRecordPayload
    case recordNotFound
    case shareUnavailable
}
