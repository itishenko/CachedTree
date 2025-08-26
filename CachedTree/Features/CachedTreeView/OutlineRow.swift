//
//  OutlineRow.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 20.08.2025.
//
import SwiftUI

struct OutlineRow: View {
    let item: TreeItem
    @Binding var selection: ElementID?
    
    var body: some View {
        DisclosureGroup(isExpanded: .constant(true)) {
            ForEach(item.children) { child in
                OutlineRow(item: child, selection: $selection)
                    .padding(.leading, 12)
            }
        } label: {
            HStack {
                Text(item.title)
                if item.isDeleted { Text("[deleted]").foregroundColor(.red) }
            }
            .contentShape(Rectangle())
            .onTapGesture { selection = item.id }
            .background(selection == item.id ? Color.accentColor.opacity(0.15) : .clear)
            .cornerRadius(8)
        }
    }
}
