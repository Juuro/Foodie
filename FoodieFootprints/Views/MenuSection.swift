import SwiftUI
import PhotosUI

struct MenuSection: View {
    let restaurant: Restaurant
    @Binding var isEditingMenu: Bool
    @Binding var showingPhotoPicker: Bool
    @Binding var selectedMenuFile: MenuFile?
    @Binding var showingFullScreen: Bool
    @Binding var menuFileToDelete: MenuFile?
    @Binding var showingMenuDeleteConfirmation: Bool
    
    private let gridSpacing: CGFloat = 12
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "Menu"))
                    .font(.title2)
                    .bold()
                Spacer()
                if !restaurant.menuFiles.isEmpty {
                    Button {
                        isEditingMenu.toggle()
                    } label: {
                        Text(isEditingMenu ? String(localized: "Done") : String(localized: "Edit"))
                    }
                }
                Button {
                    showingPhotoPicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.pink)
                }
            }
            .padding(.horizontal)
            
            if restaurant.menuFiles.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "No Menu"), systemImage: "doc.text")
                } description: {
                    Text(String(localized: "Add photos of the menu"))
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVGrid(columns: columns, spacing: gridSpacing) {
                    ForEach(restaurant.menuFiles, id: \.id) { menuFile in
                        if let uiImage = UIImage(data: menuFile.data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width / 3 - gridSpacing * 2,
                                       height: UIScreen.main.bounds.width / 3 - gridSpacing * 2)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture {
                                    if !isEditingMenu {
                                        selectedMenuFile = menuFile
                                        showingFullScreen = true
                                    }
                                }
                                .overlay(alignment: .topTrailing) {
                                    if isEditingMenu {
                                        Button {
                                            menuFileToDelete = menuFile
                                            showingMenuDeleteConfirmation = true
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.white)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                        .padding(4)
                                    }
                                }
                        }
                    }
                }
                .padding(gridSpacing)
            }
        }
    }
} 
