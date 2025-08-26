//
//  ChangeBatch.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 22.08.2025.
//
import Foundation

struct ChangeBatch {
    let creates: [NewElementDraft]
    let updates: [ElementID: (newValue: String, expectedVersion: Int)]
    let deletes: [ElementID: Int] // expectedVersion
}
