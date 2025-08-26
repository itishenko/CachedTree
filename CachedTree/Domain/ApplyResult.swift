//
//  ApplyResult.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 22.08.2025.
//
import Foundation

struct ApplyResult {
    let createdIdMap: [UUID: ElementID]
    let newVersions: [ElementID: Int]
    let conflicts: [ElementID: ConflictKind]
}
