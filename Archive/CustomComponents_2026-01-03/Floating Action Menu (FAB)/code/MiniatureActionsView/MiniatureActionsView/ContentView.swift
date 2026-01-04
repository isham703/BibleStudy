//
//  ContentView.swift
//  MiniatureActionsView
//
//  Created by Balaji Venkatesh on 18/12/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isPresented: Bool = false
    @State private var hideAElement: Bool = false
    @State private var moveToTop: Bool = false
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        NavigationStack {
            List {
                Section("Usage") {
                    Text(
                        """
                        MiniatureAction(isPresented) {
                            
                        } background: {
                            
                        }
                        """
                    )
                    .monospaced()
                    .font(.callout)
                }
                
                Section("Properties") {
                    Toggle("Hide Element", isOn: $hideAElement)
                    Toggle("Move to Top", isOn: $moveToTop)
                }
            }
            .navigationTitle("Apple Books")
        }
        .overlay {
            ZStack(alignment: moveToTop ? .topTrailing : .bottomTrailing) {
                Rectangle()
                    .fill(.primary.opacity(isPresented ? (moveToTop ? 0.4 : 0.25) : 0))
                    .allowsHitTesting(isPresented)
                    .onTapGesture {
                        isPresented = false
                    }
                    .animation(animation, value: isPresented)
                    .ignoresSafeArea()
                
                MiniatureAction(innerScaling: 0.9, animation: animation, isPresented: $isPresented) {
                    ActionContent()
                } background: {
                    ZStack {
                        Capsule()
                            .fill(.background)
                        
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(scheme == .dark ? 1 : 0)
                    }
                    .shadow(color: .black.opacity(isPresented ? 0 : 0.05), radius: 5, x: 5, y: 5)
                    .shadow(color: .black.opacity(isPresented ? 0 : 0.05), radius: 5, x: -5, y: -5)
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 10)
            }
        }
    }
    
    @ViewBuilder
    func ActionContent() -> some View {
        VStack(spacing: isPresented ? 6 : 15) {
            CustomButton(title: "Search Book", symbol: "magnifyingglass", isPresented: $isPresented)
                .frame(width: 250, height: 45)
            
            if hideAElement ? isPresented : true {
                CustomButton(title: "Themes & Settings", symbol: "textformat.size", isPresented: $isPresented)
                    .frame(width: 250, height: 45)
            }
            
            /// Horizontal Actions
            HStack(spacing: 10) {
                CustomSectionButton(symbol: "square.and.arrow.up", isPresented: $isPresented)
                                        
                CustomSectionButton(symbol: "lock.rotation", isPresented: $isPresented)
                
                CustomSectionButton(symbol: "text.line.magnify", isPresented: $isPresented)
                
                CustomSectionButton(symbol: "bookmark", isPresented: $isPresented)
            }
            .font(.title3)
            .fontWeight(.medium)
            .frame(width: 250, height: 50)
        }
        .foregroundStyle(Color.primary)
    }
    
    var animation: Animation {
        .smooth(duration: 0.35, extraBounce: 0)
    }
}

/// Custom Buttons
struct CustomButton: View {
    var title: String
    var symbol: String
    @Binding var isPresented: Bool
    var action: () -> () = { }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
               Text(title)
               
               Spacer(minLength: 0)
               
               Image(systemName: symbol)
           }
           .padding(.horizontal, 20)
           .frame(maxWidth: .infinity, maxHeight: .infinity)
           .opacity(isPresented ? 1 : 0)
           .background {
               ZStack {
                   Rectangle()
                       .fill(Color.primary)
                       .opacity(isPresented ? 0 : 1)
                   
                   Rectangle()
                       .fill(.background)
                       .opacity(isPresented ? 1 : 0)
               }
               .clipShape(.capsule)
           }
        }
    }
}

struct CustomSectionButton: View {
    var symbol: String
    @Binding var isPresented: Bool
    var action: () -> () = { }
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
               .frame(maxWidth: .infinity, maxHeight: .infinity)
               .opacity(isPresented ? 1 : 0)
               .background {
                   ZStack {
                       Rectangle()
                           .fill(Color.primary)
                           .opacity(isPresented ? 0 : 1)
                       
                       Rectangle()
                           .fill(.background)
                           .opacity(isPresented ? 1 : 0)
                   }
                   .clipShape(.capsule)
               }
        }
    }
}

#Preview {
    ContentView()
}
