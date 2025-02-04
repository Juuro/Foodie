import SwiftUI

struct MenuFileViewer: View {
    let menuFile: MenuFile
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showingDeleteConfirmation = false
    let onDelete: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let uiImage = UIImage(data: menuFile.data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale *= delta
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = value.translation
                                }
                                .onEnded { _ in
                                    withAnimation {
                                        offset = .zero
                                        scale = 1.0
                                    }
                                }
                        )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.white)
                    }
                }
            }
            .alert(String(localized: "Delete Menu Photo"), isPresented: $showingDeleteConfirmation) {
                Button(String(localized: "Cancel"), role: .cancel) { }
                Button(String(localized: "Delete"), role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text(String(localized: "Are you sure you want to delete this menu photo?"))
            }
        }
    }
} 