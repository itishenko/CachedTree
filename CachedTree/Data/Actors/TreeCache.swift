//
//  Cached.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 20.08.2025.
//
import Foundation

final class Node: Identifiable, Hashable {
    static func == (lhs: Node, rhs: Node) -> Bool { lhs.element.id == rhs.element.id }
    func hash(into hasher: inout Hasher) { hasher.combine(element.id) }
    var id: ElementID { element.id }
    var element: Element
    weak var parent: Node?
    var children: Set<Node> = []
    init(element: Element) { self.element = element }
}

actor TreeCache {
    private var nodesById: [ElementID: Node] = [:]
    private var awaitingParent: [ElementID: Set<Node>] = [:]
    private var childrenIndex: [ElementID: Set<Node>] = [:]
    
    private var creates: Set<NewElementDraft> = []
    private var updates: [ElementID: (newValue: String, expectedVersion: Int)] = [:]
    private var deletes: [ElementID: Int] = [:]
    
    private let db: DBGateway
    init(db: DBGateway) { self.db = db }
    
    // Load single element from DB into cache (allowed access)
    func loadElement(id: ElementID) async throws -> Node? {
        guard let el = try await db.fetchElement(id: id) else { return nil }
        let node = nodesById[id] ?? Node(element: el)
        node.element = el
        nodesById[id] = node
        
        
        if let pid = el.parentId, let p = nodesById[pid] {
            link(child: node, to: p)
        } else if let pid = el.parentId { // parent not present yet
            var w = awaitingParent[pid, default: []]; w.insert(node); awaitingParent[pid] = w
        }
        if let kids = childrenIndex[id] {
            for c in kids { link(child: c, to: node) }
            childrenIndex[id] = nil
        }
        return node
    }
    
    private func link(child: Node, to parent: Node) {
        child.parent = parent
    }
    
    func editValue(id: ElementID, newValue: String) {
        guard deletes[id] == nil else { return }
        // FIXME
//        updates[id] = (newValue, node.element.version)
//        node.element.value = newValue
    }
    
    func addChild(parentId: ElementID, value: String) {
        guard let parent = nodesById[parentId], parent.element.isDeleted == false, deletes[parentId] == nil else { return }
        let draft = NewElementDraft(tempId: UUID(), parentId: parentId, value: value)
        creates.insert(draft)
        let tempEl = Element(id: ElementID(draft.tempId), parentId: parentId, value: value, isDeleted: false, version: 0)
        let node = Node(element: tempEl)
        nodesById[tempEl.id] = node
        link(child: node, to: parent)
    }
    
    func deleteSubtree(id: ElementID) {
        guard let root = nodesById[id], deletes[id] == nil else { return }
        cascadeDelete(node: root)
    }
    
    private func cascadeDelete(node: Node) {
        guard node.element.isDeleted == false else { return }
        node.element.isDeleted = true
        deletes[node.element.id] = node.element.version
        updates[node.element.id] = nil
        for c in node.children { cascadeDelete(node: c) }
    }
    
    func apply() async throws -> ApplyResult {
        let batch = ChangeBatch(
            creates: Array(creates),
            updates: updates,
            deletes: deletes
        )
        let result = try await db.applyChanges(batch)
        
        // Map temp ids to real ids
        for (temp, real) in result.createdIdMap {
            let tempId = ElementID(temp)
            guard let node = nodesById[tempId] else { continue }
            nodesById[tempId] = nil
            node.element.id = real
            node.element.version = result.newVersions[real] ?? 1
            nodesById[real] = node
        }
        // Update versions
        for (id, ver) in result.newVersions { nodesById[id]?.element.version = ver }
        
        // Clear local change sets
        creates.removeAll(); updates.removeAll(); deletes.removeAll()
        return result
    }
    
    func clearAll() {
        nodesById.removeAll(); awaitingParent.removeAll(); childrenIndex.removeAll()
        creates.removeAll(); updates.removeAll(); deletes.removeAll()
    }
    
    // Build UI snapshot (roots = nodes without parent or whose parent not present)
    func snapshot() -> [TreeItem] {
        let present = Set(nodesById.keys)
        let roots = nodesById.values.filter { n in
            guard let pid = n.element.parentId else { return true }
            return !present.contains(pid)
        }
        func build(_ n: Node) -> TreeItem {
            let kids = n.children.map { build($0) }.sorted(by: { $0.title < $1.title })
            return TreeItem(id: n.element.id, title: n.element.value, isDeleted: n.element.isDeleted, children: kids)
        }
        return roots.map { build($0) }.sorted(by: { $0.title < $1.title })
    }
}
