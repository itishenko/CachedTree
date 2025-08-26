//
//  DBGateway.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 20.08.2025.
//

protocol DBGateway {
    func fetchElement(id: ElementID) async throws -> Element?
    func applyChanges(_ batch: ChangeBatch) async throws -> ApplyResult
    func fullTreeSnapshot() async -> [TreeItem] // for demo UI only
    func resetToDefaults() async
}
