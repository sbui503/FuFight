//
//  AccountViewModel.swift
//  FuFight
//
//  Created by Samuel Folledo on 2/23/24.
//

import Combine
import SwiftUI

enum ReauthenticateReasonType {
    case deleteAccount
    case editAccount
    case saveAccount
}

final class AccountViewModel: BaseAccountViewModel {
    ///False if user is editing after a recent authentication
    @Published var isViewingMode: Bool = true
    var selectedImage: UIImage? = nil {
        didSet {
            if isViewingMode && selectedImage != nil {
                ///If there's a new photo and we are not in editing mode, go to editing mode
                isViewingMode = false
            }
        }
    }
    @Published var usernameFieldText: String = ""
    @Published var usernameFieldHasError: Bool = false
    @Published var usernameFieldIsActive: Bool = false
    @Published var isDeleteAccountAlertPresented: Bool = false
    private var isRecentlyAuthenticated = false
    @Published var isReauthenticationAlertPresented = false
    @Published var password = ""
    @Published private var reauthenticationReasonType: ReauthenticateReasonType = .editAccount

    override func onAppear() {
        super.onAppear()
        selectedImage = nil
        isViewingMode = true
        usernameFieldText = account.username ?? ""
    }

    //MARK: - Public Methods
    func logOut() {
        Task {
            do {
                updateLoadingMessage(to: Str.loggingOut)
                try await AccountNetworkManager.logOut()
                transitionToAuthenticationView()
                updateLoadingMessage(to: Str.updatingUser)
                try await AccountNetworkManager.setData(account: account)
                updateLoadingMessage(to: Str.savingUser)
                try await AccountManager.saveCurrent(account)
                updateError(nil)
            } catch {
                updateError(MainError(type: .logOut, message: error.localizedDescription))
            }
        }
    }

    ///Delete in Auth, Firestore, Storage, and then locally
    func deleteAccount() {
        Task {
            let currentUserId = account.id ?? Account.current?.userId ?? account.userId
            do {
                updateLoadingMessage(to: Str.deletingStoredPhoto)
                try await AccountNetworkManager.deleteStoredPhoto(currentUserId)
                updateLoadingMessage(to: Str.deletingData)
                try await AccountNetworkManager.deleteData(currentUserId)
                try await AccountNetworkManager.deleteAuthData(userId: currentUserId)
                AccountManager.deleteCurrent()
                updateError(nil)
                account.reset()
                account.status = .loggedOut
                if Defaults.isSavingEmailAndPassword {
                    Defaults.savedEmailOrUsername = ""
                    Defaults.savedPassword = ""
                }
            } catch {
                updateError(MainError(type: .deletingUser, message: error.localizedDescription))
            }
        }
    }

    func deleteButtonTapped() {
        if isRecentlyAuthenticated {
            isDeleteAccountAlertPresented = true
        } else {
            showReauthenticateAlert(reasonType: .deleteAccount)
        }
    }

    func editSaveButtonTapped() {
        if isViewingMode {
            if isRecentlyAuthenticated {
                DispatchQueue.main.async {
                    self.isViewingMode = false
                }
            } else {
                showReauthenticateAlert(reasonType: .editAccount)
            }
        } else {
            if isRecentlyAuthenticated {
                saveAccount()
            } else {
                showReauthenticateAlert(reasonType: .saveAccount)
            }
        }
    }

    func reauthenticate() {
        guard !isRecentlyAuthenticated else { return }
        Task {
            do {
                updateLoadingMessage(to: Str.reauthenticatingAccount)
                try await AccountNetworkManager.reauthenticateUser(password: password)
                isRecentlyAuthenticated = true
                updateError(nil)
                ///If success, run the action that triggered reauthentication
                switch reauthenticationReasonType {
                case .deleteAccount:
                    deleteButtonTapped()
                case .editAccount:
                    editSaveButtonTapped()
                case .saveAccount:
                    saveAccount()
                }
            } catch {
                updateError(MainError(type: .reauthenticatingUser, message: error.localizedDescription))
            }
        }
    }
}

//MARK: - Private Methods
private extension AccountViewModel {
    func transitionToAuthenticationView() {
        account.status = .loggedOut
        AccountManager.saveCurrent(account)
    }

    func saveAccount() {
        let username = usernameFieldText.trimmed
        usernameFieldHasError = !username.isValidUsername
        guard !username.isEmpty,
              !usernameFieldHasError else {
            return updateError(MainError(type: .invalidUsername))
        }
        Task {
            ///Update username if needed
            var newUsername: String? = nil
            let didChangeUsername = username.lowercased() != account.displayName.trimmed.lowercased()
            if didChangeUsername {
                ///Check if username is unique
                if try await !AccountNetworkManager.isUnique(username: username) {
                    updateError(MainError(type: .notUniqueUsername))
                    return
                }
                newUsername = username
                account.updateUsername(username)
            }

            ///If there's any photo changes, set account's photo in Storage and save the photo URL
            var newPhotoUrl: URL? = nil
            if let selectedImage {
                updateLoadingMessage(to: Str.storingPhoto)
                if let photoUrl = try await AccountNetworkManager.storePhoto(selectedImage, for: account.userId) {
                    newPhotoUrl = photoUrl
                    account.photoUrl = newPhotoUrl
                }
            }

            if newUsername != nil || newPhotoUrl != nil {
                ///Update authenticated user's displayName and photoUrl
                updateLoadingMessage(to: Str.updatingAuthenticatedUser)
                try await AccountNetworkManager.updateAuthenticatedUser(username: newUsername, photoUrl: newPhotoUrl)
            }

            ///Update database if there are any changes
            if didChangeUsername || newPhotoUrl != nil {
                if didChangeUsername {
                    updateLoadingMessage(to: Str.updatingUsername)
                    try await AccountNetworkManager.updateUsername(to: username, for: account.userId)
                    if Defaults.isSavingEmailAndPassword {
                        Defaults.savedEmailOrUsername = username
                    }
                }
                updateLoadingMessage(to: Str.savingUser)
                try await AccountNetworkManager.setData(account: account)
                try await AccountManager.saveCurrent(account)
            }
            try await auth.currentUser?.reload()
            LOGD("Successfully editted user with \(auth.currentUser!.displayName!) and \(auth.currentUser!.email!)", from: AccountViewModel.self)
            updateError(nil)
            selectedImage = nil
            isViewingMode = true
        }
    }

    func showReauthenticateAlert(reasonType: ReauthenticateReasonType) {
        reauthenticationReasonType = reasonType
        isReauthenticationAlertPresented = true
    }
}
