//
//  CommandGroup.swift
//  SwiftBot
//
//  Created by David Hedbor on 2/14/16.
//  Copyright © 2016 NeoTron. All rights reserved.
//

import Foundation
import SQLiteStORM
import StORM


class CommandGroup: SQLiteStORM, Commandable {
    // Insert code here to add functionality to your managed object subclass
    var id: Int = 0
    var command: String = ""
    var help: String?

    func add(command: CommandAlias) -> Bool {
        command.groupId = id
        return Database.instance.save(command)
    }
    func remove(command: CommandAlias) -> Bool {
        command.groupId = nil
        return Database.instance.save(command)
    }
    func commands() -> Array<CommandAlias>  {
        let query = CommandAlias()
        do {
            try query.find(["groupId": "\(id)"])
            return query.rows()
        } catch {
            LOG_ERROR("Failed to load command group aliases: \(error)")
            return []
        }
    }

    override open func table() -> String {
        return "commandGroup"
    }
    override func to(_ this: StORMRow) {
        id = this.data["id"] as! Int
        command = this.data["command"] as! String
        help = this.data["help"] as? String
    }

    func rows() -> [CommandGroup] {
        var rows = [CommandGroup]()
        for row in self.results.rows {
            let command = CommandGroup()
            command.to(row)
            rows.append(command)
        }
        return rows
    }
}
