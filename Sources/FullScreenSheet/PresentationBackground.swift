import SwiftUI

// MARK: - Preference Key

/// Preference key for communicating custom background views from child views to the sheet container.
///
/// This preference key uses a type-erased view wrapper to pass background content up the view hierarchy.
/// The custom equality implementation prevents infinite SwiftUI update loops by only checking for nil state.
struct SheetBackgroundPreferenceKey: PreferenceKey {
    /// Container for the background view.
    struct Value: Equatable {
        /// The type-erased background view, or `nil` for default background.
        let view: AnyView?

        /// Custom equality that prevents infinite update cycles.
        ///
        /// Instead of comparing view contents (which is impossible with `AnyView`), this compares
        /// whether both values are nil or both are non-nil. This is sufficient for SwiftUI's
        /// diffing algorithm and prevents unnecessary re-renders.
        static func == (lhs: Value, rhs: Value) -> Bool {
            // Always consider them equal if both have views or both are nil
            // This prevents infinite updates
            (lhs.view == nil && rhs.view == nil) || (lhs.view != nil && rhs.view != nil)
        }
    }

    /// Default value when no preference has been set (no custom background).
    nonisolated(unsafe) static var defaultValue = Value(view: nil)

    /// Combines multiple preference values by taking the first non-nil value.
    ///
    /// When multiple child views set background preferences, the most recently set
    /// non-nil value takes priority.
    ///
    /// - Parameters:
    ///   - value: The accumulated preference value.
    ///   - nextValue: A closure that returns the next preference value to merge.
    static func reduce(value: inout Value, nextValue: () -> Value) {
        let next = nextValue()
        if next.view != nil {
            value = next
        }
    }
}

// MARK: - View Extension

public extension View {
    /// Sets a custom background for the full-screen sheet using a shape style.
    ///
    /// Apply this modifier to any view inside a `fullScreenSheet` to customize the sheet's background
    /// with gradients, materials, or solid colors.
    ///
    /// - Parameter style: The shape style to use for the background (e.g., `.purple.gradient`, `.regularMaterial`).
    /// - Returns: A view with the custom background preference set.
    ///
    /// ## Example
    /// ```swift
    /// .fullScreenSheet(isPresented: $showSheet) {
    ///     Text("Hello!")
    ///         .presentationFullScreenBackground(.purple.gradient)
    /// }
    /// ```
    func presentationFullScreenBackground<S: ShapeStyle>(_ style: S) -> some View {
        self.background(
            Color.clear.preference(
                key: SheetBackgroundPreferenceKey.self,
                value: SheetBackgroundPreferenceKey.Value(view: AnyView(Rectangle().fill(style)))
            )
        )
    }

    /// Sets a custom background for the full-screen sheet using a view builder.
    ///
    /// Apply this modifier to create complex background compositions with custom views,
    /// images, or layered effects.
    ///
    /// - Parameter content: A view builder that creates the background view.
    /// - Returns: A view with the custom background preference set.
    ///
    /// ## Example
    /// ```swift
    /// .fullScreenSheet(isPresented: $showSheet) {
    ///     Text("Hello!")
    ///         .presentationFullScreenBackground {
    ///             LinearGradient(
    ///                 colors: [.orange, .pink],
    ///                 startPoint: .topLeading,
    ///                 endPoint: .bottomTrailing
    ///             )
    ///         }
    /// }
    /// ```
    func presentationFullScreenBackground<Background: View>(@ViewBuilder content: @escaping () -> Background) -> some View {
        self.background(
            Color.clear.preference(
                key: SheetBackgroundPreferenceKey.self,
                value: SheetBackgroundPreferenceKey.Value(view: AnyView(content()))
            )
        )
    }

    /// Sets a custom background for the full-screen sheet using a view builder with alignment.
    ///
    /// This variant allows you to control how the background content is aligned within the sheet.
    /// The background is automatically expanded to fill the full sheet bounds.
    ///
    /// - Parameters:
    ///   - alignment: The alignment for the background content (default: `.center`).
    ///   - content: A view builder that creates the background view.
    /// - Returns: A view with the custom background preference set.
    ///
    /// ## Example
    /// ```swift
    /// .fullScreenSheet(isPresented: $showSheet) {
    ///     Text("Hello!")
    ///         .presentationFullScreenBackground(alignment: .topLeading) {
    ///             Image(systemName: "star.fill")
    ///                 .resizable()
    ///                 .frame(width: 200, height: 200)
    ///         }
    /// }
    /// ```
    func presentationFullScreenBackground<Background: View>(alignment: Alignment = .center, @ViewBuilder content: @escaping () -> Background) -> some View {
        self.background(
            Color.clear.preference(
                key: SheetBackgroundPreferenceKey.self,
                value: SheetBackgroundPreferenceKey.Value(view: AnyView(content().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)))
            )
        )
    }
}
