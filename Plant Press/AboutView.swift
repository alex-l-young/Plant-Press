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
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .cornerRadius(16) // Gives it that classic curved iOS icon look
                        .shadow(radius: 3) // Adds a subtle drop shadow
                        .padding(.top, 40)
                    
                    Text("Plant Press")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Version 1.0")
                        .foregroundColor(.secondary)
                    
                    Text("A virtual plant press for documenting plant observations and locations.")
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                    
                    Text("Sites")
                        .font(.title2)
                        .padding(.top, 10)
                    
                    Text("A site is the top level in the organization structure and contains all the checklists associated with that site. For example, a site could be a preserve or forest where you are surveying.")
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                    
                    Text("Create a site by clicking the + button at the bottom when the toggle is set to Sites. You will be asked to provide a name, creation date and time, location, and optional photo.")
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                    
                    Text("Checklists")
                        .font(.title2)
                        .padding(.top, 10)
                    
                    Text("Checklists are plant lists that are timestamped and associated with an existing site.")
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                    
                    Text("Create a checklist by clicking the + button at the bottom when the toggle is set to Checklists. You will be asked to provide a creation date and time and the name of the associated site. If the site has not yet been created, you will be prompted to create one.")
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                    
                    Text("When you click on a checklist, you are presented with the list of species that have been observed. The buttons at the bottom allow you to navigate to the NY Flora Atlas webpage, export your plant list for that checklist, view a map of all observations, sort the list alphabetically or by date, and create a new observation.")
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                    
                    Text("Clicking on a species will bring you to a list of all associated observations. For example, if you found multiple populations of the same species, these would all be listed together and organized by the date and time recorded.")
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                    
                    Text("Observations")
                        .font(.title2)
                        .padding(.top, 10)
                    
                    Text("When you create a new observation, you will be asked to provide the genus. If the species is unkonwn, you can select sp., cf., or ? for unknown. Dropdown lists allow you to select pre-specified genera and species names from an internal list of New York State plants. An optional variety and subspecies dialogue is also provided. The location can either be specified with the map or left blank. If left blank, it will be assigned to the site location. You can also add any number of photos and notes before saving the observation.")
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                    
                    Text("Once an observation is created, it will be filed in the associated checklist. If the species has already been created, it will be filed as an additional observation.")
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                                        
                    Text("Privacy Policy")
                        .font(.title2)
                        .padding(.top, 10)
                    
                    Text("This app does not collect any data from you. All the data you record is stored locally on your device.")
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)
                    
                    Text("Disclaimer")
                        .font(.title2)
                        .padding(.top, 10)
                    
                    Text("This app is provided as is and the author shall not be held liable for any claims or damages resulting from use of this app. Please botanize responsibly.")
                        .multilineTextAlignment(.leading)
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
