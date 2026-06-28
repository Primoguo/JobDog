import SwiftUI

/// 像素风 ViewModifier
struct PixelStyle: ViewModifier {
    let color: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.darker(by: 0.2), lineWidth: 1)
            )
            .shadow(color: color.darker(by: 0.3).opacity(0.3), radius: 0, x: 2, y: 2)
    }
}

extension View {
    func pixelStyle(color: Color, cornerRadius: CGFloat = 8) -> some View {
        modifier(PixelStyle(color: color, cornerRadius: cornerRadius))
    }
}
