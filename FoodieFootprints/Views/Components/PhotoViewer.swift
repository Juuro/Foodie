import SwiftUI

struct PhotoViewer: View {
    let photos: [Visit.Photo]
    let initialIndex: Int
    @Binding var isPresented: Int?
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    init(photos: [Visit.Photo], initialIndex: Int, isPresented: Binding<Int?>) {
        self.photos = photos
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    if let image = photo.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .tag(index)
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
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    if scale > 1 {
                                        scale = 1.0
                                        offset = .zero
                                    } else {
                                        scale = 2.0
                                    }
                                }
                            }
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .overlay(alignment: .topTrailing) {
                Button {
                    isPresented = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding()
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
} 