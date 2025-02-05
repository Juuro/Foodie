import SwiftUI

struct PhotoViewer: View {
    let photos: [Visit.Photo]
    let initialIndex: Int
    @Binding var isPresented: Int?
    @State private var currentIndex: Int
    @GestureState private var dragOffset = CGSize.zero
    
    init(photos: [Visit.Photo], initialIndex: Int, isPresented: Binding<Int?>) {
        self.photos = photos
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                TabView(selection: $currentIndex) {
                    ForEach(photos.indices, id: \.self) { index in
                        if let image = photos[index].image {
                            image
                                .resizable()
                                .scaledToFit()
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Close button with more padding from top
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            isPresented = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
        }
    }
} 
