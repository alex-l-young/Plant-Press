import SwiftUI
import SwiftData
import PhotosUI

struct SiteCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var siteToEdit: Site?
    
    @State private var siteName: String = ""
    @State private var creationDate: Date = Date()
    @State private var pinLocation: CLLocationCoordinate2D? = nil
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var thumbnailData: Data? = nil
    
    // NEW: Controls the presentation of the full-screen map
    @State private var showingMapPicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Site Details")) {
                    TextField("Site Name", text: $siteName)
                    DatePicker("Creation Date & Time", selection: $creationDate)
                    Button("Now") { creationDate = Date() }
                        .foregroundColor(.blue)
                }
                
                Section(header: Text("Site Photo (Optional)")) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label(selectedImage == nil ? "Add Thumbnail" : "Change Thumbnail", systemImage: "photo.circle")
                    }
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                // REFACTORED: Location Section
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
                    // REFACTORED: Require name and a pinLocation
                    .disabled(siteName.trimmingCharacters(in: .whitespaces).isEmpty || pinLocation == nil)
                }
            }
            .navigationTitle(siteToEdit == nil ? "New Site" : "Edit Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                // NEW: Top right save button
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveSite) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            // We use the exact same validation logic as the bottom button
                    }
                    .disabled(siteName.trimmingCharacters(in: .whitespaces).isEmpty || pinLocation == nil)
                }
            }
            // NEW: Launch the full-screen map
            .fullScreenCover(isPresented: $showingMapPicker) {
                FullScreenMapView(pinLocation: $pinLocation)
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
            site.name = siteName
            site.creationDate = creationDate
            site.latitude = pinLocation?.latitude
            site.longitude = pinLocation?.longitude
            site.thumbnailData = thumbnailData
        } else {
            let newSite = Site(
                name: siteName,
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
