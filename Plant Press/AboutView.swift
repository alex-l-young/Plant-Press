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
            VStack(spacing: 20) {
                // A placeholder for your actual app icon
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
                    .padding()
                
                Spacer()
                
                Text("© 2026 Alex Young")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationTitle("About This App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // A clean "Done" button to dismiss the sheet
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
