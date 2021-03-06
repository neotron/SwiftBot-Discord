//
//  CommandAlias+CoreDataProperties.swift
//  SwiftBot
//
//  Created by David Hedbor on 2/18/16.
//  Copyright © 2016 NeoTron. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension CommandAlias {
    @NSManaged var value: String
    @NSManaged var longHelp: String?
    @NSManaged var pmEnabled: Bool
    @NSManaged var group: CommandGroup?

}
