import SwiftUI
import SwiftData
import PhotosUI

struct SiteCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var allSites: [Site]
    
    var siteToEdit: Site?
    
    @State private var siteName: String = ""
    @State private var creationDate: Date = Date()
    @State private var pinLocation: CLLocationCoordinate2D? = nil
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var thumbnailData: Data? = nil
    
    // View States
    @State private var showingMapPicker = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    
    // Validation check for duplicates
    var isDuplicateName: Bool {
        let normalizedInput = siteName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalizedInput.isEmpty { return false }
        
        if let editingSite = siteToEdit, editingSite.name.lowercased() == normalizedInput {
            return false
        }
        
        return allSites.contains { $0.name.lowercased() == normalizedInput }
    }
    
    var isFormValid: Bool {
        let isNameEmpty = siteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasLocation = pinLocation != nil
        return !isNameEmpty && !isDuplicateName && hasLocation
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Site Details")) {
                    TextField("Site Name", text: $siteName)
                    
                    if isDuplicateName {
                        Text("A site with this name already exists.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    DatePicker("Creation Date & Time", selection: $creationDate)
                    Button("Now") { creationDate = Date() }
                        .foregroundColor(.blue)
                }
                
                Section(header: Text("Site Photo (Optional)")) {
                    HStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                // Tap image to remove
                                .onTapGesture {
                                    selectedImage = nil
                                    thumbnailData = nil
                                }
                        }
                        
                        // The New Camera Menu
                        Menu {
                            Button(action: { showingCamera = true }) {
                                Label("Take Photo", systemImage: "camera")
                            }
                            Button(action: { showingPhotoLibrary = true }) {
                                Label("Choose from Library", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(Color.gray.opacity(0.6))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "plus")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Section(header: Text("Location")) {
                    if let pin = pinLocation {
                        Text("Lat: \(String(format: "%.5f", pin.latitude)), Lon: \(String(format: "%.5f", pin.longitude))")
                            .font(.subheadline)
                    } else {
                        Text("No location selected")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { showingMapPicker = true }) {
                        Text(pinLocation == nil ? "Select Location on Map" : "Edit Location")
                    }
                }
                
                Section {
                    Button(action: saveSite) {
                        Text(siteToEdit == nil ? "Save site" : "Update site")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle(siteToEdit == nil ? "New Site" : "Edit Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveSite) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                    }
                    .disabled(!isFormValid)
                }
            }
            .fullScreenCover(isPresented: $showingMapPicker) {
                FullScreenMapView(pinLocation: $pinLocation)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                ImagePicker(selectedImage: $selectedImage)
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showingPhotoLibrary, selection: $selectedItem, matching: .images)
            .onChange(of: selectedImage) { oldImg, newImg in
                if let img = newImg {
                    thumbnailData = img.jpegData(compressionQuality: 0.8)
                }
            }
            .onChange(of: selectedItem) { oldItem, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        thumbnailData = data
                        selectedImage = image
                    }
                }
            }
            .onAppear {
                if let site = siteToEdit {
                    siteName = site.name
                    creationDate = site.creationDate
                    thumbnailData = site.thumbnailData
                    if let data = site.thumbnailData {
                        selectedImage = UIImage(data: data)
                    }
                    if let lat = site.latitude, let lon = site.longitude {
                        pinLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                }
            }
        }
    }
    
    private func saveSite() {
        if let site = siteToEdit {
            site.name = siteName.trimmingCharacters(in: .whitespacesAndNewlines)
            site.creationDate = creationDate
            site.latitude = pinLocation?.latitude
            site.longitude = pinLocation?.longitude
            site.thumbnailData = thumbnailData
        } else {
            let newSite = Site(
                name: siteName.trimmingCharacters(in: .whitespacesAndNewlines),
                creationDate: creationDate,
                latitude: pinLocation?.latitude,
                longitude: pinLocation?.longitude,
                thumbnailData: thumbnailData
            )
            modelContext.insert(newSite)
        }
        dismiss()
    }
}
