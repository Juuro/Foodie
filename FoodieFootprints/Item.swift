//
//  Item.swift
//  FoodieFootprints
//
//  Created by Sebastian Engel on 24.11.24.
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
