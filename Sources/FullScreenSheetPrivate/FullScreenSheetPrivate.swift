import SwiftUI

// MARK: - Presentation Full Screen Behavior

/// Defines the full-screen behavior for sheet presentations using private APIs.
///
/// This enum provides options to configure how a sheet behaves when presented in full-screen mode,
/// similar to Apple Music's player presentation.
public enum PresentationFullScreenBehavior {
    /// No special full-screen behavior (standard sheet presentation).
    case automatic

    /// Enables full-screen mode with interactive dismiss support.
    ///
    /// When applied, the sheet will:
    /// - Present in full-screen mode with the underlying view dimming/sinking effect
    /// - Allow swipe-to-dismiss gesture from the full-screen state
    ///
    /// - Warning: This uses private APIs (`_wantsFullScreen` and
    ///   `_allowsInteractiveDismissWhenFullScreen`) and may break in future iOS versions.
    case enabled
}

// MARK: - Sheet Configurator

/// A helper that configures a UISheetPresentationController with private APIs
private final class SheetConfiguratorViewController: UIViewController {
    var behavior: PresentationFullScreenBehavior = .automatic

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureSheet()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureSheet()
    }

    private func configureSheet() {
        guard behavior == .enabled else { return }

        guard let sheetController = sheetPresentationController else {
            // Try to find it through parent hierarchy
            var currentVC: UIViewController? = self.parent
            while let vc = currentVC {
                if let sheet = vc.sheetPresentationController {
                    applyPrivateAPI(to: sheet)
                    return
                }
                currentVC = vc.parent
            }
            return
        }
        applyPrivateAPI(to: sheetController)
    }

    private func applyPrivateAPI(to sheet: UISheetPresentationController) {
        sheet.setValue(true, forKey: "wantsFullScreen")
        sheet.setValue(true, forKey: "allowsInteractiveDismissWhenFullScreen")
    }
}

private struct SheetConfigurator: UIViewControllerRepresentable {
    let behavior: PresentationFullScreenBehavior

    func makeUIViewController(context: Context) -> SheetConfiguratorViewController {
        let controller = SheetConfiguratorViewController()
        controller.behavior = behavior
        return controller
    }

    func updateUIViewController(_ uiViewController: SheetConfiguratorViewController, context: Context) {
        uiViewController.behavior = behavior
    }
}

// MARK: - Preference Key

private struct PresentationFullScreenBehaviorKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: PresentationFullScreenBehavior = .automatic

    static func reduce(value: inout PresentationFullScreenBehavior, nextValue: () -> PresentationFullScreenBehavior) {
        value = nextValue()
    }
}

// MARK: - Public View Extension

public extension View {
    /// Configures the full-screen behavior for a sheet presentation using private APIs.
    ///
    /// Apply this modifier to the content **inside** your `.sheet()` modifier to control
    /// how the sheet behaves in full-screen mode.
    ///
    /// Example usage:
    /// ```swift
    /// .sheet(isPresented: $showSheet) {
    ///     Text("Hello")
    ///         .presentationFullScreen(.enabled)
    /// }
    /// ```
    ///
    /// - Parameter behavior: The full-screen behavior to apply. Use `.enabled` for Apple Music-style
    ///   presentation with interactive dismiss, or `.automatic` for standard behavior.
    ///
    /// - Warning: When using `.enabled`, this relies on private APIs that may break in future
    ///   iOS versions. Apple may reject apps using this approach.
    ///
    /// - Returns: A view configured with the specified full-screen presentation behavior.
    func presentationFullScreen(_ behavior: PresentationFullScreenBehavior) -> some View {
        self.background(SheetConfigurator(behavior: behavior))
    }
}
