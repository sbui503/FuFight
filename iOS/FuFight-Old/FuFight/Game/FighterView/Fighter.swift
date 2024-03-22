//
//  Fighter.swift
//  FuFight
//
//  Created by Samuel Folledo on 3/21/24.
//

import Foundation

class Fighter {
    var name: String = "Samuel"
    var idleImageName: String
    var dodgeImageName: String
    var isFrontFacing: Bool = true

    init() {
        let postFix: String = isFrontFacing ? "Back" : "Front"
        idleImageName = "\(name)-idle\(postFix)"
        dodgeImageName = "\(name)-dodge\(postFix)"
    }
}