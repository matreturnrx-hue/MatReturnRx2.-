//
//  Item.swift
//  MatReturnRx Dev
//
//  Created by Juan Sanchez on 6/28/26.
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
