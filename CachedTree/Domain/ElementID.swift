//
//  ElementID.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 20.08.2025.
//
import Foundation

struct ElementID: Hashable, Codable, Identifiable, CustomStringConvertible {
    let raw: UUID
    var id: UUID { raw }
    init(_ raw: UUID = UUID()) { self.raw = raw }
    var description: String { raw.uuidString }
}


