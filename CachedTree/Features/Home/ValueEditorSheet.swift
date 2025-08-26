//
//  ValueEditorSheet.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 20.08.2025.
//
import SwiftUI

struct ValueEditorSheet: View {
    let title: String
    @Binding var text: String
    var onApply: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(title) {
                    TextField("Value", text: $text)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("OK") { onApply(); dismiss() } .disabled(text.isEmpty) }
            }
        }
    }
    
    @Environment(\ .dismiss) private var dismiss
}
