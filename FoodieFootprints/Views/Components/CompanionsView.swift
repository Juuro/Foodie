import SwiftUI

struct CompanionsView: View {
    let companions: String
    
    var body: some View {
        let names = companions.components(separatedBy: ", ")
        FlowLayout(spacing: 4) {
            ForEach(Array(names.enumerated()), id: \.element) { index, name in
                HStack(spacing: 4) {
                    CompanionButton(name: name)
                    if index < names.count - 1 {
                        Text("·")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
} 