//
//  UserRole.swift
//  SwiftBot
//
//  Created by David Hedbor on 2/16/16.
//  Copyright © 2016 NeoTron. All rights reserved.
//

import Foundation
import SQLiteStORM
import StORM

enum Role: Int16 {
    case owner = 1,
         admin = 2

    static func fromRawValue(_ rawValue: Int16) -> Role {
        switch(rawValue) {
        case 1:
            return .owner
        default:
            return .admin
        }
    }
}

class UserRole: SQLiteStORM {
    var id: Int = 0  // primary key
    var userId: String = ""
    var roleId: Int16 = Role.admin.rawValue
    var role: Role {
        get {
            return Role.fromRawValue(roleId)
        }
        set {
            roleId = newValue.rawValue
        }
    }

    override open func table() -> String {
        return "userRole"
    }
    override func to(_ this: StORMRow) {
        id = this.data["id"] as! Int
        userId = this.data["userId"] as! String
        roleId = Int16(this.data["roleId"] as! String)!
    }

    func rows() -> [UserRole] {
        var rows = [UserRole]()
        for row in self.results.rows {
            let command = UserRole()
            command.to(row)
            rows.append(command)
        }
        return rows
    }
}
