//
//  Item.swift
//  BulletJournal
//
//  Created by David Sanders on 10/1/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
