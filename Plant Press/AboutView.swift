//
//  AboutView.swift
//  Plant Press
//
//  Created by Alex Young on 2/25/26.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            // NEW: Added a ScrollView so the text can freely expand downwards
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding(.top, 40)
                    
                    Text("Plant Press")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Version 1.0")
                        .foregroundColor(.secondary)
                    
                    Text("A dedicated field data collection tool for documenting plant observations, locations, and photographic evidence.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // REMOVED: Spacers. Replaced their effect with strategic padding.
                    
                    Text("Privacy Policy")
                        .font(.title2)
                        .padding(.top, 10)
                    
                    Text("This app does not collect any data from you. All the data you record is stored locally on your device.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("Disclaimer")
                        .font(.title2)
                        .padding(.top, 10)
                    
                    Text("This app is provided as is and the author shall not be held liable for any claims or damages resulting from use of this app. Please botanize responsibly.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("© 2026 Alex Young")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 40) // Gives a nice margin at the very bottom of the scroll
                }
            }
            .navigationTitle("About This App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
