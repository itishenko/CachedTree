//
//  ContentView.swift
//  CachedTree
//
//  Created by Ivan Tishchenko on 20.08.2025.
//

import SwiftUI

struct AlertMessage: Identifiable { let id = UUID(); let text: String }

struct ContentView: View {
    @StateObject private var vm = AppState()
    
    var body: some View {
        AnyView
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("DB").font(.headline)
                    Spacer()
                    Button("Reset") { vm.reset() }
                        .buttonStyle(.bordered)
                }
                DBTreeView(tree: vm.dbTree, selection: $vm.selectedDB)
                HStack {
                    Button("Load to Cache") { vm.loadSelectedFromDB() }
                        .disabled(vm.selectedDB == nil)
                }
            }
            .padding()
        } detail: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Cache").font(.headline)
                CachedTreeView(tree: vm.cacheTree, selection: $vm.selectedCache)
                HStack(spacing: 12) {
                    Button("Delete") { vm.deleteSelectedInCache() }
                        .disabled(vm.selectedCache == nil)
                    Button("Set value") { vm.presentValueEditor() }
                        .disabled(vm.selectedCache == nil)
                    Button("Add child") { vm.presentAddChild() }
                        .disabled(vm.selectedCache == nil)
                    Spacer()
                    Button("Apply") { vm.applyAllChanges() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .sheet(isPresented: $vm.showValueEditor) {
            ValueEditorSheet(title: "Edit", text: $vm.valueEditorText, onApply: vm.applyValueEditor)
                .presentationDetents([.fraction(0.3)])
        }
        .sheet(isPresented: $vm.showAddChild) {
            ValueEditorSheet(title: "New child", text: $vm.addChildText, onApply: vm.applyAddChild)
                .presentationDetents([.fraction(0.3)])
        }
        .alert(item: Binding(get: {
            vm.lastApplyMessage.map { AlertMessage(text: $0) }
        }, set: { _ in vm.lastApplyMessage = nil })) { msg in
            Alert(title: Text(msg.text))
        }
    }
}

#Preview {
    ContentView()
}
