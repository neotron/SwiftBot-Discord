//
// Created by David Hedbor on 2/15/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

import Foundation
import CoreData

class Commandable : NSManagedObject {
    @NSManaged var command: String
    @NSManaged var help: String?
}
