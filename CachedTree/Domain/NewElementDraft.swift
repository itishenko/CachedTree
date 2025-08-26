//
//  NewElementDraft.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 22.08.2025.
//
import Foundation

struct NewElementDraft: Hashable {
    let tempId: UUID
    let parentId: ElementID
    var value: String
}
