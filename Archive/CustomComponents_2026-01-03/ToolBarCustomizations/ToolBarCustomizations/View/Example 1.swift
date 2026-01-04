//
//  Example 1.swift
//  ToolBarCustomizations
//
//  Created by Balaji Venkatesh on 23/11/25.
//

import SwiftUI

/// NOTES:
/// If you want the "Write" action to be bounced as well then do the following!
/// Replace .toolbar(id: "WRITEACTION") with .toolbar
/// Replace ToolbarItem(id: "WRITE") with ToolbarItem
struct Example_1: View {
    @State private var searchText: String = ""
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    Example1DetailView()
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("New Year 2026")
                            .fontWeight(.semibold)
                        
                        Text("Some description")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationSubtitle("6 Notes")
            .toolbar(id: "WRITEACTION") {
                ToolbarItem(id: "WRITE", placement: .bottomBar) {
                    Button {
                        
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .toolbar {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                
                /// Splitting Two Items
                ToolbarSpacer(.fixed, placement: .bottomBar)
            }
            .searchable(text: $searchText)
        }
    }
}

struct Example1DetailView: View {
    var body: some View {
        VStack {
            
        }
        .toolbar(id: "WRITEACTION") {
            ToolbarItem(id: "WRITE", placement: .bottomBar) {
                Button {
                    
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                /// Or you can create ToolBarItem for each individual item as well!
                HStack(spacing: 12) {
                    Button {
                        
                    } label: {
                        Image(systemName: "checklist")
                            .padding(.horizontal, 5)
                    }
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "paperclip")
                            .padding(.horizontal, 5)
                    }
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "pencil.tip.crop.circle")
                            .padding(.horizontal, 5)
                    }
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "apple.writing.tools")
                            .padding(.horizontal, 5)
                    }
                }
                .padding(.horizontal, 5)
                .buttonStyle(.plain)
            }
            
            /// Splitting Two Items
            ToolbarSpacer(.flexible, placement: .bottomBar)
        }
        .navigationTitle("New Year 2026")
    }
}

#Preview {
    Example_1()
}
