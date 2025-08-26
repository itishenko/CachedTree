//
//  AppState.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 20.08.2025.
//
import Combine

@MainActor
final class AppState: ObservableObject {
    let db: InMemoryDB
    let cache: TreeCache
    
    @Published var dbTree: [TreeItem] = []
    @Published var cacheTree: [TreeItem] = []
    
    @Published var selectedDB: ElementID? = nil
    @Published var selectedCache: ElementID? = nil
    
    @Published var showValueEditor: Bool = false
    @Published var valueEditorText: String = ""
    @Published var showAddChild: Bool = false
    @Published var addChildText: String = ""
    @Published var lastApplyMessage: String? = nil
    
    init() {
        let db = InMemoryDB()
        self.db = db
        self.cache = TreeCache(db: db)
        Task { await refreshDBSnapshot() }
    }
    
    func refreshDBSnapshot() async {
        dbTree = await db.fullTreeSnapshot()
    }
    
    func refreshCacheSnapshot() {
        Task { @MainActor in
            self.cacheTree = await cache.snapshot()
        }
    }
    
    func reset() {
        Task {
            await db.resetToDefaults()
            await cache.clearAll()
            await MainActor.run { [weak self] in
                self?.selectedDB = nil;
                self?.selectedCache = nil
            }
            await refreshDBSnapshot()
            await MainActor.run { [weak self] in self?.refreshCacheSnapshot() }
        }
    }
    
    // DB → Cache: load selected element
    func loadSelectedFromDB() {
        guard let id = selectedDB else { return }
        Task {
            _ = try? await cache.loadElement(id: id)
            await MainActor.run { [weak self] in self?.refreshCacheSnapshot() }
        }
    }
    
    // Cache actions
    func deleteSelectedInCache() {
        guard let id = selectedCache else { return }
        Task {
            await cache.deleteSubtree(id: id)
            await MainActor.run { [weak self] in self?.refreshCacheSnapshot() }
        }
    }
    
    func presentValueEditor() {
        guard let id = selectedCache else { return }
        // Pre-fill with current value if we can find it in snapshot
        if let value = findTitle(in: cacheTree, id: id) { valueEditorText = value }
        showValueEditor = true
    }
    
    func applyValueEditor() {
        guard let id = selectedCache else { return }
        let text = valueEditorText
        Task {
            await cache.editValue(id: id, newValue: text)
            await MainActor.run { [weak self] in
                self?.showValueEditor = false
                self?.refreshCacheSnapshot()
            }
        }
    }
    
    func presentAddChild() {
        guard selectedCache != nil else { return }
        addChildText = ""
        showAddChild = true
    }

    func applyAddChild() {
        guard let parentId = selectedCache else { return }
        let text = addChildText
        Task {
            await cache.addChild(parentId: parentId, value: text)
            await MainActor.run { [weak self] in
                self?.showAddChild = false
                self?.refreshCacheSnapshot()
            }
        }
    }
    
    func applyAllChanges() {
        Task {
            let result = try? await cache.apply()
            await refreshDBSnapshot()
            await MainActor.run { [weak self] in
                self?.refreshCacheSnapshot()
                if let r = result {
                    let conflicts = r.conflicts.map { $0.key.description }.joined(separator: ", ")
                    self?.lastApplyMessage = r.conflicts.isEmpty ? "Changes applied" : "Conflicts for: \(conflicts)"
                } else {
                    self?.lastApplyMessage = "Application error"
                }
            }
        }
    }
    
    private func findTitle(in items: [TreeItem], id: ElementID) -> String? {
        for it in items {
            if it.id == id { return it.title }
            if let t = findTitle(in: it.children, id: id) { return t }
        }
        return nil
    }
}
