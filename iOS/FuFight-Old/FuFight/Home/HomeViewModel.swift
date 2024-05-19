//
//  HomeViewModel.swift
//  FuFight
//
//  Created by Samuel Folledo on 2/16/24.
//

import SwiftUI
import FirebaseAuth

final class HomeViewModel: BaseAccountViewModel {
    @Published var player: Player?
    @Published var enemyPlayer: Player?
    @Published var isAccountVerified = false
    @Published var path = NavigationPath()

    //MARK: - Public Methods
    ///Make sure account is valid at least once
    @MainActor func verifyAccount() {
        Task {
            do {
                if try await AccountNetworkManager.isAccountValid(userId: account.userId) {
                    LOGD("Account verified", from: HomeViewModel.self)
                    isAccountVerified = true
                    self.player = Player(userId: account.userId, photoUrl: account.photoUrl ?? fakePhotoUrl,
                                         username: Account.current?.displayName ?? "",
                                         hp: defaultMaxHp,
                                         maxHp: defaultMaxHp,
                                         fighter: Fighter(type: .samuel, isEnemy: false),
                                         state: PlayerState(boostLevel: .none, hasSpeedBoost: false),
                                         moves: Moves(attacks: defaultAllPunchAttacks, defenses: defaultAllDashDefenses))
                    return
                }
                LOGE("Account is invalid \(account.displayName) with id \(account.userId)", from: HomeViewModel.self)
                AccountManager.deleteCurrent()
                updateError(nil)
                account.reset()
                account.status = .logOut
                if Defaults.isSavingEmailAndPassword {
                    Defaults.savedEmailOrUsername = ""
                    Defaults.savedPassword = ""
                }
            } catch {
                updateError(MainError(type: .deletingUser, message: error.localizedDescription))
            }
        }
    }
}
