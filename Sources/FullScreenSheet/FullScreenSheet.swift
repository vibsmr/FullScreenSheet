import SwiftUI

// MARK: - Constants

/// Configuration values for sheet dismissal behavior.
private enum SheetConstants {
    /// The duration of snap-back and re-enable animations.
    static let animationDuration: TimeInterval = 0.3

    /// Factor to scale down velocity contribution to dismissal threshold.
    /// Higher values make velocity less influential in the dismiss decision.
    static let velocityDampening: CGFloat = 5
}

// MARK: - Public View Extension

public extension View {
    /// Presents a full-screen sheet with pull-to-dismiss gesture support.
    ///
    /// This modifier wraps your content in a full-screen cover that can be dismissed by
    /// pulling down from the top. It works seamlessly with scrollable content like `List`,
    /// `ScrollView`, and `UICollectionView`.
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls the presentation state of the sheet.
    ///   - onDismiss: An optional closure to execute when the sheet is dismissed.
    ///   - content: A view builder that creates the content to display in the sheet.
    ///
    /// - Note: Use ``presentationFullScreenBackground(_:)`` to customize the sheet's background.
    ///
    /// - Important: When using `.navigationTransition` for matched geometry effects, the custom
    ///   pull-to-dismiss gesture is automatically disabled to prevent conflicts with the
    ///   navigation transition animation.
    @ViewBuilder
    func fullScreenSheet<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self
            .fullScreenCover(isPresented: isPresented, onDismiss: onDismiss) {
                FullScreenSheetView(content: content)
            }
    }

    /// Presents a full-screen sheet using an identifiable item.
    ///
    /// This modifier wraps your content in a full-screen cover that can be dismissed by
    /// pulling down from the top. It works seamlessly with scrollable content like `List`,
    /// `ScrollView`, and `UICollectionView`.
    ///
    /// - Parameters:
    ///   - item: A binding to an optional identifiable value that controls the presentation.
    ///           When the item is non-nil, the sheet is presented. When it becomes nil, the sheet is dismissed.
    ///   - onDismiss: An optional closure to execute when the sheet is dismissed.
    ///   - content: A view builder that receives the unwrapped item and creates the content to display.
    ///
    /// - Note: Use ``presentationFullScreenBackground(_:)`` to customize the sheet's background.
    ///
    /// - Important: When using `.navigationTransition` for matched geometry effects, the custom
    ///   pull-to-dismiss gesture is automatically disabled to prevent conflicts with the
    ///   navigation transition animation.
    @ViewBuilder
    func fullScreenSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        self
            .fullScreenCover(item: item, onDismiss: onDismiss) { unwrappedItem in
                FullScreenSheetView {
                    content(unwrappedItem)
                }
            }
    }
}

// MARK: - Internal Sheet View

/// The internal view that powers the full-screen sheet with dismissal gesture handling.
///
/// This view manages the entire lifecycle of the sheet presentation, including:
/// - Tracking pan gestures to detect pull-to-dismiss interactions
/// - Temporarily disabling scroll when the user begins pulling down
/// - Animating the sheet's vertical offset during drag
/// - Determining whether to dismiss or snap back based on drag distance and velocity
/// - Synchronizing the background view's offset with the content
struct FullScreenSheetView<Content: View>: View {
    /// The content to display in the sheet.
    @ViewBuilder var content: () -> Content

    /// The dismiss action from the environment.
    @Environment(\.dismiss) var dismiss

    /// Controls whether scrolling is disabled during pull-to-dismiss gestures.
    @State var scrollDisabled = false

    /// The current vertical offset of the sheet during drag gestures.
    @State private var offset: CGFloat = .zero

    /// The custom background view set via preference key.
    @State private var backgroundView: SheetBackgroundPreferenceKey.Value = SheetBackgroundPreferenceKey.defaultValue

    var body: some View {
        content()
            .scrollDisabled(scrollDisabled)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
            .offset(y: offset)
            // Listen for background preference changes from child views
            .onPreferenceChange(SheetBackgroundPreferenceKey.self) { value in
                backgroundView = value
            }
            .gesture(
                CustomPanGesture{ gesture in
                    let state = gesture.state

                    // Calculate the dismiss threshold (half the screen height)
                    let halfHeight = windowSize.height / 2

                    // Clamp translation to [0, screen height] so the sheet can't be pulled up
                    let translation = min(max(gesture.translation(in: gesture.view).y, 0), windowSize.height)

                    // Scale velocity down and clamp it to [0, halfHeight]
                    let velocity = min(max(gesture.velocity(in: gesture.view).y / SheetConstants.velocityDampening, 0), halfHeight)

                    switch state {
                    case .began:
                        // Disable scrolling when the gesture starts to prevent conflicts
                        scrollDisabled = true
                        offset = translation

                    case .changed:
                        // Only update offset if scroll is disabled (gesture has priority)
                        guard scrollDisabled else { return }
                        offset = translation

                    case .ended, .cancelled, .failed:
                        // Prevent gesture from interfering with animations
                        gesture.isEnabled = false

                        // Decide whether to dismiss or snap back based on drag distance + velocity
                        if (translation + velocity) > halfHeight {
                            // User pulled far enough or fast enough - dismiss the sheet
                            dismiss()

                            // Small delay to allow dismiss animation to complete
                            Task{
                                try? await Task.sleep(for: .seconds(SheetConstants.animationDuration))
                            }
                        } else {
                            // User didn't pull far enough - snap back to original position
                            withAnimation(.snappy(duration: SheetConstants.animationDuration)){
                                offset = .zero
                            }

                            // Re-enable scrolling and gesture after snap-back animation
                            Task {
                                try? await Task.sleep(for: .seconds(SheetConstants.animationDuration))
                                scrollDisabled = false
                                gesture.isEnabled = true
                            }
                        }
                    default: ()
                    }
                }
            )
            .presentationBackground {
                Group {
                    if let view = backgroundView.view {
                        // Use custom background if provided
                        view
                            .offset(y: offset)
                    } else {
                        // Default to system background
                        Color(.systemBackground)
                            .offset(y: offset)
                    }
                }
            }
    }

    /// Gets the current window size for calculating dismiss thresholds.
    ///
    /// - Returns: The screen bounds size of the key window, or `.zero` if unavailable.
    private var windowSize: CGSize {
        if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow{
            return window.screen.bounds.size
        }

        return .zero
    }
}

// MARK: - Preview Examples
 
#Preview("List") {
    @Previewable @State var showSheet = false

    NavigationStack {
        Button("Show Sheet") {
            showSheet = true
        }
        .navigationTitle("Demo")
        .fullScreenSheet(isPresented: $showSheet) {
            List {
                ForEach(1...100, id: \.self) { index in
                    Text("Item \(index)")
                        .font(.title3)
                        .padding(.vertical, 8)
                }
            }
            .listStyle(.plain)
        }
    }
}
 
#Preview("ScrollView") {
    @Previewable @State var showSheet = false

    NavigationStack {
        Button("Show Sheet") {
            showSheet = true
        }
        .navigationTitle("Demo")
        .fullScreenSheet(isPresented: $showSheet) {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(1...50, id: \.self) { index in
                        Text("Row \(index)")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
    }
}
 
#Preview("ShapeStyle Background") {
    @Previewable @State var showSheet = false

    NavigationStack {
        Button("Show Sheet") {
            showSheet = true
        }
        .navigationTitle("Demo")
        .fullScreenSheet(isPresented: $showSheet) {
            Text("Hello!")
                .font(.largeTitle)
                .presentationFullScreenBackground(.purple.gradient)
        }
    }
}
 
#Preview("ViewBuilder Background") {
    @Previewable @State var showSheet = false

    NavigationStack {
        Button("Show Sheet") {
            showSheet = true
        }
        .navigationTitle("Demo")
        .fullScreenSheet(isPresented: $showSheet) {
            Text("Hello!")
                .font(.largeTitle)
                .presentationFullScreenBackground {
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
    }
}
 
#Preview("Alignment Background") {
    @Previewable @State var showSheet = false

    NavigationStack {
        Button("Show Sheet") {
            showSheet = true
        }
        .navigationTitle("Demo")
        .fullScreenSheet(isPresented: $showSheet) {
            Text("Hello!")
                .font(.largeTitle)
                .presentationFullScreenBackground(alignment: .topLeading) {
                    Image(systemName: "star.fill")
                        .resizable()
                        .foregroundStyle(.yellow.opacity(0.3))
                        .frame(width: 200, height: 200)
                }
        }
    }
}

@available(iOS 18.0, *)
#Preview("Navigation Transition") {
    @Previewable @State var showSheet = false
    @Previewable @Namespace var namespace

    NavigationStack {
        VStack(spacing: 20) {
            Circle()
                .fill(.blue.gradient)
                .frame(width: 100, height: 100)
                .matchedTransitionSource(id: "circle", in: namespace)
                .onTapGesture {
                    showSheet = true
                }

            Text("Tap the circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Transitions")
        .fullScreenSheet(isPresented: $showSheet) {
            VStack {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 200, height: 200)
                    .navigationTransition(.zoom(sourceID: "circle", in: namespace))
                    .padding(.top, 100)

                Text("Zoomed Circle")
                    .font(.title)
                    .padding()

                Spacer()
            }
            .presentationFullScreenBackground(.black)
        }
    }
}
