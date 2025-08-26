//
//  TreeItem.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 22.08.2025.
//
import Foundation

// Node snapshot for UI tree rendering
struct TreeItem: Identifiable, Hashable {
    var id: ElementID
    var title: String
    var isDeleted: Bool
    var children: [TreeItem]
}
