//
//  Element.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 22.08.2025.
//

struct Element: Codable, Identifiable {
    var id: ElementID
    var parentId: ElementID? // nil for root
    var value: String
    var isDeleted: Bool
    var version: Int // optimistic locking
}
