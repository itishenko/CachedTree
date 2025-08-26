//
//  DBTreeView.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 20.08.2025.
//
import SwiftUI

struct DBTreeView: View {
    let tree: [TreeItem]
    @Binding var selection: ElementID?
    
    var body: some View {
        List(selection: Binding(get: { selection.map { Set([$0]) } ?? [] }, set: { set in selection = set.first })) {
            ForEach(tree) { item in
                OutlineRow(item: item, selection: $selection)
            }
        }
        .listStyle(.inset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(Group {
            if tree.isEmpty { Text("Empty").foregroundColor(.secondary) }
        })
    }
}
