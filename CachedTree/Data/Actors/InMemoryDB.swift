//
//  InMemoryDB.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 20.08.2025.
//
import Foundation

actor InMemoryDB: DBGateway {
    private var elements: [ElementID: Element] = [:]
    private var childrenIndex: [ElementID: [ElementID]] = [:]
    private var roots: [ElementID] = []
    
    init() {
        Task { await resetToDefaults() }
    }
    
    func resetToDefaults() async {
        elements.removeAll(); childrenIndex.removeAll(); roots.removeAll()
        // Build default tree
        // Root
        let root = makeElement(value: "Root")
        roots = [root.id]
        // Level 1
        let a = makeChild(of: root, value: "A")
        let b = makeChild(of: root, value: "B")
        let c = makeChild(of: root, value: "C")
        // Level 2
        let a1 = makeChild(of: a, value: "A1")
        let a2 = makeChild(of: a, value: "A2")
        let b1 = makeChild(of: b, value: "B1")
        let c1 = makeChild(of: c, value: "C1")
        // Level 3
        let a1x = makeChild(of: a1, value: "A1-X")
        _ = makeChild(of: a2, value: "A2-X")
        _ = makeChild(of: b1, value: "B1-X")
        _ = makeChild(of: c1, value: "C1-X")
        // Level 4
        _ = makeChild(of: a1x, value: "A1-X-i")
        _ = makeChild(of: a1x, value: "A1-X-ii")
    }
    
    
    private func makeElement(value: String, parent: ElementID? = nil) -> Element {
        let e = Element(id: ElementID(), parentId: parent, value: value, isDeleted: false, version: 1)
        elements[e.id] = e
        if let p = parent {
            childrenIndex[p, default: []].append(e.id)
        }
        return e
    }
    
    
    private func makeChild(of parent: Element, value: String) -> Element {
        return makeElement(value: value, parent: parent.id)
    }
    
    // DBGateway
    func fetchElement(id: ElementID) async throws -> Element? {
        return elements[id]
    }
    
    func applyChanges(_ batch: ChangeBatch) async throws -> ApplyResult {
        var created: [UUID: ElementID] = [:]
        var newVersions: [ElementID: Int] = [:]
        var conflicts: [ElementID: ConflictKind] = [:]
        
        // 1) Creates
        for draft in batch.creates {
            // Validate parent exists and not deleted
            guard let parent = elements[draft.parentId], parent.isDeleted == false else {
                conflicts[ElementID(draft.tempId)] = .parentDeleted
                continue
            }
            let newEl = Element(id: ElementID(), parentId: draft.parentId, value: draft.value, isDeleted: false, version: 1)
            elements[newEl.id] = newEl
            childrenIndex[draft.parentId, default: []].append(newEl.id)
            created[draft.tempId] = newEl.id
            newVersions[newEl.id] = newEl.version
        }
        
        // 2) Updates
        for (id, upd) in batch.updates {
            guard var el = elements[id] else { conflicts[id] = .notFound; continue }
            guard el.version == upd.expectedVersion else { conflicts[id] = .versionMismatch; continue }
            guard el.isDeleted == false else { conflicts[id] = .notFound; continue }
            el.value = upd.newValue
            el.version += 1
            elements[id] = el
            newVersions[id] = el.version
        }
        
        
        // 3) Deletes (soft, cascade)
        for (id, expected) in batch.deletes {
            guard let el = elements[id] else { conflicts[id] = .notFound; continue }
            guard el.version == expected else { conflicts[id] = .versionMismatch; continue }
            await cascadeDelete(id)
            if var e = elements[id] { e.version += 1; elements[id] = e; newVersions[id] = e.version }
        }
        
        
        return ApplyResult(createdIdMap: created, newVersions: newVersions, conflicts: conflicts)
    }
    
    
    private func cascadeDelete(_ id: ElementID) async {
        guard var el = elements[id], el.isDeleted == false else { return }
        el.isDeleted = true
        elements[id] = el
        for child in childrenIndex[id, default: []] { await cascadeDelete(child) }
    }
    
    
    func fullTreeSnapshot() async -> [TreeItem] {
        func build(_ id: ElementID) -> TreeItem? {
            guard let el = elements[id] else { return nil }
            let kids = childrenIndex[id, default: []].compactMap { build($0) }
            return TreeItem(id: id, title: el.value, isDeleted: el.isDeleted, children: kids)
        }
        return roots.compactMap { build($0) }
    }
}
