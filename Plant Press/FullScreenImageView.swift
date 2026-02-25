import SwiftUI
import UIKit // We need this to access the native UIScrollView

struct FullScreenImageView: View {
    @Environment(\.dismiss) private var dismiss
    var image: UIImage
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // NEW: We use our custom native iOS zoomable view instead of a basic Image
                ZoomablePhotoView(image: image)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }
}

// NEW: A wrapper that brings the native Apple Photos zooming experience into SwiftUI
struct ZoomablePhotoView: UIViewRepresentable {
    var image: UIImage
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0 // Allows zooming in up to 5x
        scrollView.minimumZoomScale = 1.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        uiView.subviews.compactMap { $0 as? UIImageView }.first?.image = image
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?
        
        // Tells the UIScrollView which view it should apply the pinch-to-zoom to
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }
    }
}
