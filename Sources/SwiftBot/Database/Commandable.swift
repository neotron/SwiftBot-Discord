//
// Created by David Hedbor on 2/15/16.
// Copyright (c) 2016 NeoTron. All rights reserved.
//

protocol Commandable {
    var command: String { get set }
    var help: String? { get set }
}
