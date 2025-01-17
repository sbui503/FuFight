//
//  RoomNetworkManager.swift
//  FuFight
//
//  Created by Samuel Folledo on 5/22/24.
//

import FirebaseFirestore
import SwiftUI

class RoomNetworkManager {
    private init() {}
}

//MARK: - Extension
extension RoomNetworkManager {
    static func createRoom(_ room: Room) async throws {
        do {
            let userId = room.owner!.userId
            let roomDocument = roomsDb.document(userId)
            try roomDocument.setData(from: room)
            LOGD("Room created for roomId: \(room.owner!.username)")
        } catch {
            throw error
        }
    }

    ///Fetches current room for the authenticated account
    static func fetchRoom(_ account: Account) async throws -> Room {
        do {
            let room = try await roomsDb.document(account.userId).getDocument(as: Room.self)
            LOGD("Room fetched for: \(account.displayName)")
            return room
        } catch {
            throw error
        }
    }

    ///Fetch an available room if there's any available. Return avaialble roomIds
    static func findAvailableRooms(userId: String) async throws -> [String] {
        let isRoomSearchingFilter: Filter = .whereField(kSTATUS, isEqualTo: Room.Status.searching.rawValue)
        do {
            let availableRooms = try await roomsDb
                .whereFilter(Filter.andFilter([
                    isRoomSearchingFilter,
                ]))
                .limit(to: 3)
                .getDocuments()
//                .order(by: "dateAdded", descending: true)
            let roomIds = availableRooms.documents.compactMap { $0.documentID != userId ? $0.documentID : nil }
            LOGD("Total rooms found: \(roomIds.count)")
            return roomIds
        } catch {
            throw error
        }
    }

    ///For room owner to create a new or rejoin an existing room
    static func createOrRejoinRoom(room: Room) async throws {
        do {
            let ownerId = room.ownerId
            let roomDocuments = try await roomsDb.whereField(kOWNERID, isEqualTo: ownerId).getDocuments()
            if roomDocuments.isEmpty {
                //Check if user already has a room created
                let roomDocument = roomsDb.document(ownerId)
                try roomDocument.setData(from: room)
                LOGD("Current room created with id: \(roomDocument.documentID)")
            } else {
                //Rejoin room
                let roomDocument = roomDocuments.documents.first!
                LOGD("Current room rejoined at id: \(roomDocument.documentID)")
            }
        } catch {
            throw error
        }
    }

    static func updateStatus(to status: Room.Status, roomId: String) {
        var roomDic: [String: Any] = [kSTATUS: status.rawValue]
        switch status {
        case .finishing, .searching:
            break
        case .online, .offline, .gaming:
            roomDic[kCHALLENGERS] = FieldValue.delete()
        }
        roomsDb.document(roomId).updateData(roomDic)
        LOGD("Player's room status is updated to: \(status.rawValue)")
    }

    ///For room owner to delete room
    static func deleteCurrentRoom(roomId: String) async throws {
        do {
            try await roomsDb.document(roomId).delete()
            LOGD("Player's room is successfully deleted with room id: \(roomId)")
        } catch {
            throw error
        }
    }

    ///For current player to join a room as one of the challengers
    static func joinRoom(_ player: FetchedPlayer, roomId: String) async throws {
        do {
            let enemyDic: [String: Any] = [
                kCHALLENGERS: FieldValue.arrayUnion([try player.asDictionary()]),
            ]
            try await roomsDb.document(roomId).updateData(enemyDic)
            LOGD("User joined someone's room as enemy with room id: \(roomId)")
        } catch {
            throw error
        }
    }

    ///Updates room's owner in the database
    static func updateOwner(_ player: FetchedPlayer) async throws {
        do {
            let roomDocument = roomsDb.document(player.userId)
            try await roomDocument.updateData([kOWNER: player.asDictionary()])
            LOGD("Room's owner is updated successfully: \(player.username)")
        } catch {
            throw error
        }
    }
}
