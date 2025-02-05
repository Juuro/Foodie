import SwiftUI

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 4) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var position = CGPoint.zero
        var maxHeight: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for size in sizes {
            if position.x + size.width > (proposal.width ?? .infinity) {
                position.x = 0
                position.y += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            position.x += size.width + spacing
            maxHeight = max(maxHeight, position.y + lineHeight)
        }
        
        return CGSize(width: proposal.width ?? .infinity, height: maxHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var position = CGPoint(x: bounds.minX, y: bounds.minY)
        var lineHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            
            if position.x + size.width > bounds.maxX {
                position.x = bounds.minX
                position.y += lineHeight + spacing
                lineHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: position.x, y: position.y),
                proposal: ProposedViewSize(size)
            )
            
            lineHeight = max(lineHeight, size.height)
            position.x += size.width + spacing
        }
    }
} 