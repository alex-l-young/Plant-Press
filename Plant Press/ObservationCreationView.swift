import SwiftUI
import SwiftData
import PhotosUI

struct ObservationCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var site: Site
    var observationToEdit: PlantObservation?
    var initialGenus: String? = nil
    var initialSpecies: String? = nil
    
    @State private var genus: String = ""
    @State private var species: String = ""
    @State private var infraspecificName: String = ""
    @State private var isVariety: Bool = true
    @State private var notes: String = ""
    @State private var pinLocation: CLLocationCoordinate2D?
    
    // Photo handling state variables
    @State private var newSelectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var selectedPhotoData: [Data] = []
    @State private var isEditingPhotos: Bool = false
    
    // Camera & Library state variables
    @State private var showingCamera = false
    @State private var cameraImage: UIImage? = nil
    @State private var showingPhotoLibrary = false // NEW: Safely triggers the photo picker
    
    @State private var showingMapPicker = false
    
    @StateObject private var plantData = PlantDataManager.shared
    @FocusState private var focusedField: Field?
    
    enum Field {
        case genus
        case species
    }
    
    var genusSuggestions: [String] {
        if genus.isEmpty { return plantData.allGenera }
        return plantData.allGenera.filter { $0.lowercased().hasPrefix(genus.lowercased()) }
    }
    
    var speciesSuggestions: [String] {
        guard let availableSpecies = plantData.speciesByGenus[genus] else { return [] }
        if species.isEmpty { return availableSpecies }
        return availableSpecies.filter { $0.lowercased().hasPrefix(species.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Taxonomy")) {
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("Genus", text: $genus)
                            .focused($focusedField, equals: .genus)
                            .onSubmit { focusedField = .species }
                        
                        if focusedField == .genus && !genusSuggestions.isEmpty {
                            ScrollView {
                                ScrollViewReader { proxy in
                                    LazyVStack(alignment: .leading) {
                                        EmptyView().id("genusTop")
                                        ForEach(genusSuggestions, id: \.self) { suggestion in
                                            Button(action: {
                                                genus = suggestion
                                                focusedField = .species
                                            }) {
                                                Text(suggestion)
                                                    .padding(.vertical, 8)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .foregroundColor(.blue)
                                            }
                                            .buttonStyle(.plain)
                                            Divider()
                                        }
                                    }
                                    .onChange(of: genus) { _, _ in proxy.scrollTo("genusTop", anchor: .top) }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("Species", text: $species)
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .species)
                        
                        if focusedField == .species && !speciesSuggestions.isEmpty {
                            ScrollView {
                                ScrollViewReader { proxy in
                                    LazyVStack(alignment: .leading) {
                                        EmptyView().id("speciesTop")
                                        ForEach(speciesSuggestions, id: \.self) { suggestion in
                                            Button(action: {
                                                species = suggestion
                                                focusedField = nil
                                            }) {
                                                Text(suggestion)
                                                    .padding(.vertical, 8)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .foregroundColor(.blue)
                                            }
                                            .buttonStyle(.plain)
                                            Divider()
                                        }
                                    }
                                    .onChange(of: species) { _, _ in proxy.scrollTo("speciesTop", anchor: .top) }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                    }
                    
                    if observationToEdit == nil {
                        HStack {
                            Button("sp.") { species = "sp." }
                            Spacer()
                            Button("cf.") { species = "cf." }
                            Spacer()
                            Button("?") { species = "?" }
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    }
                    
                    HStack {
                        Picker("", selection: $isVariety) {
                            Text("var.").tag(true)
                            Text("ssp.").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                        
                        TextField("Name (optional)", text: $infraspecificName)
                            .textInputAutocapitalization(.never)
                    }
                }
                
                Section(header: Text("Location")) {
                    if let pin = pinLocation {
                        Text("Lat: \(String(format: "%.5f", pin.latitude)), Lon: \(String(format: "%.5f", pin.longitude))")
                            .font(.subheadline)
                    } else {
                        Text("Location Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { showingMapPicker = true }) {
                        Text(pinLocation == nil ? "Select Location on Map" : "Edit Location")
                    }
                    
                    if pinLocation != nil {
                        Button(action: { pinLocation = nil }) {
                            Text("Set to Unknown")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Photos")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, img in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .onLongPressGesture {
                                            withAnimation { isEditingPhotos.toggle() }
                                        }
                                    
                                    if isEditingPhotos {
                                        Button(action: {
                                            withAnimation { removePhoto(at: index) }
                                        }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white))
                                                .font(.title3)
                                        }
                                        .offset(x: 8, y: -8)
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.trailing, isEditingPhotos ? 8 : 0)
                            }
                            
                            // UPDATED: Menu uses standard buttons to trigger states
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
                            .padding(.top, 8)
                        }
                        .padding(.bottom, 8)
                    }
                    
                    if isEditingPhotos {
                        Text("Tap the red badge to delete. Long-press any photo to stop editing.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(action: saveObservation) {
                        Text(observationToEdit == nil ? "Save Observation" : "Update Observation")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(genus.isEmpty || species.isEmpty)
                }
            }
            .navigationTitle(observationToEdit == nil ? "New Observation" : "Edit Observation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveObservation) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                    }
                    .disabled(genus.isEmpty || species.isEmpty)
                }
            }
            .fullScreenCover(isPresented: $showingMapPicker) {
                let siteLoc = (site.latitude != nil && site.longitude != nil) ? CLLocationCoordinate2D(latitude: site.latitude!, longitude: site.longitude!) : nil
                FullScreenMapView(pinLocation: $pinLocation, siteLocation: siteLoc)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                ImagePicker(selectedImage: $cameraImage)
                    .ignoresSafeArea()
            }
            // NEW: The safe way to present the photo library in iOS
            .photosPicker(isPresented: $showingPhotoLibrary, selection: $newSelectedItems, matching: .images)
            .onChange(of: cameraImage) { oldImage, newImage in
                if let image = newImage {
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        selectedImages.append(image)
                        selectedPhotoData.append(data)
                    }
                    cameraImage = nil
                    isEditingPhotos = false
                }
            }
            .onChange(of: newSelectedItems) { oldItems, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedPhotoData.append(data)
                            selectedImages.append(image)
                        }
                    }
                    newSelectedItems.removeAll()
                    isEditingPhotos = false
                }
            }
            .onAppear {
                if let obs = observationToEdit {
                    genus = obs.genus
                    species = obs.species
                    infraspecificName = obs.infraspecificName ?? ""
                    isVariety = obs.isVariety
                    notes = obs.notes
                    selectedPhotoData = obs.photoData
                    selectedImages = obs.photoData.compactMap { UIImage(data: $0) }
                    
                    if let lat = obs.latitude, let lon = obs.longitude {
                        pinLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    }
                } else {
                    if let initialGenus = initialGenus, let initialSpecies = initialSpecies {
                        genus = initialGenus
                        species = initialSpecies
                    }
                }
            }
        }
    }
    
    private func removePhoto(at index: Int) {
        if index >= 0 && index < selectedImages.count {
            selectedImages.remove(at: index)
            selectedPhotoData.remove(at: index)
        }
        if selectedImages.isEmpty {
            isEditingPhotos = false
        }
    }
    
    private func saveObservation() {
        if let obs = observationToEdit {
            obs.genus = genus
            obs.species = species
            obs.infraspecificName = infraspecificName.isEmpty ? nil : infraspecificName
            obs.isVariety = isVariety
            obs.notes = notes
            obs.latitude = pinLocation?.latitude
            obs.longitude = pinLocation?.longitude
            obs.photoData = selectedPhotoData
        } else {
            let newObservation = PlantObservation(
                genus: genus,
                species: species,
                infraspecificName: infraspecificName.isEmpty ? nil : infraspecificName,
                isVariety: isVariety,
                timestamp: Date(),
                latitude: pinLocation?.latitude,
                longitude: pinLocation?.longitude,
                notes: notes,
                photoData: selectedPhotoData
            )
            newObservation.site = site
            modelContext.insert(newObservation)
        }
        dismiss()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
