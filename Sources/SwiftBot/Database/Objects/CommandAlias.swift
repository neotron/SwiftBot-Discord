//
//  CommandAlias.swift
//  SwiftBot
//
//  Created by David Hedbor on 2/14/16.
//  Copyright © 2016 NeoTron. All rights reserved.
//

import Foundation
import SQLiteStORM
import StORM

class CommandAlias: SQLiteStORM, Commandable {
    var id: Int = 0
    var value: String = ""
    var longHelp: String?
    var pmEnabled: Bool = false
    var groupId: Int?
    var command: String = ""
    var help: String?

    override open func table() -> String {
        return "commandAlias"
    }

    override func to(_ this: StORMRow) {
        id = this.data["id"] as! Int
        value = this.data["value"] as! String
        pmEnabled = this.data["pmEnabled"] as! String == "true"
        groupId = this.data["groupId"] as? Int
        command = this.data["command"] as! String
        help = this.data["help"] as? String
        longHelp = this.data["longhelp"] as? String
    }

    func rows() -> [CommandAlias] {
        var rows = [CommandAlias]()
        for row in self.results.rows {
            let command = CommandAlias()
            command.to(row)
            rows.append(command)
        }
        return rows
    }
}
