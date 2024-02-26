//
//  AlertButton.swift
//  FuFight
//
//  Created by Samuel Folledo on 2/21/24.
//

import SwiftUI

enum AlertButtonType {
    case cancel, secondaryCancel, ok, secondaryOk, custom, delete

    var title: LocalizedStringKey {
        switch self {
        case .cancel, .secondaryCancel:
            return "Cancel"
        case .delete:
            return "Delete"
        case .ok, .secondaryOk:
            return "Ok"
        case .custom:
            return ""
        }
    }

    var bgColor: UIColor {
        switch self {
        case .cancel, .secondaryCancel:
            return .systemBackground
        case .delete:
            return .systemRed
        case .ok, .secondaryOk:
            return .systemBackground
        case .custom:
            return .clear
        }
    }

    var textColor: UIColor {
        switch self {
        case .cancel:
            return .systemRed
        case .delete:
            return .systemBackground
        case .ok:
            return .systemBlue
        case .secondaryCancel, .secondaryOk:
            return .label
        case .custom:
            return .systemBlue
        }
    }
}

struct AlertButton: View {
    // MARK: - Value
    // MARK: Public
    var type: AlertButtonType
    let title: LocalizedStringKey
    let textColor: UIColor
    let bgColor: UIColor
    let isBordered: Bool
    var action: (() -> Void)? = nil

    init(title: LocalizedStringKey, textColor: UIColor = .systemBackground, bgColor: UIColor = .systemBackground, isBordered: Bool = true, action: (() -> Void)? = nil) {
        self.title = title
        self.textColor = textColor
        self.bgColor = bgColor
        self.isBordered = isBordered
        self.action = action
        self.type = .custom
    }

    init(type: AlertButtonType, isBordered: Bool = false, action: (() -> Void)? = nil) {
        self.type = type
        self.title = type.title
        self.textColor = type.textColor
        self.bgColor = type.bgColor
        self.isBordered = isBordered
        self.action = action
    }

    // MARK: - View
    // MARK: Public
    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Spacer()

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(uiColor: textColor))
                    .contentShape(Rectangle())

                Spacer()
            }
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity)
        .background(
            Color(uiColor: isBordered ? .label : bgColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color(uiColor: isBordered ? bgColor : .clear), lineWidth: 2)
                )
        )
        .cornerRadius(15)
    }
}

struct AlertButton_Previews: PreviewProvider {

    static var previews: some View {
        let dismissButton   = AlertButton(title: "Ok")
        let primaryButton   = AlertButton(title: "Ok")
        let secondaryButton = AlertButton(title: "Cancel")

        let dismissButton2   = AlertButton(type: .cancel)
        let primaryButton2   = AlertButton(type: .delete)
        let secondaryButton2 = AlertButton(type: .ok)

        return VStack {
            dismissButton
            primaryButton
            secondaryButton

            dismissButton2
            primaryButton2
            secondaryButton2
        }
        .padding()
        .preferredColorScheme(.light)
    }
}
