<div align="center">
  <h1><b>FullScreenSheet</b></h1>
  <p>
    A SwiftUI full-screen sheet with pull-to-dismiss gesture support that works seamlessly with scrollable content.
  </p>
</div>

<p align="center">
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-18%2B-purple.svg" alt="iOS 18+"></a>
  <a href="https://swift.org/"><img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6.2"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"></a>
</p>

https://github.com/user-attachments/assets/73627b5d-e0e0-495c-b263-6ea05b626102

---

## Why FullScreenSheet?

SwiftUI's native `.fullScreenCover` doesn't support interactive dismissal gestures. While `.sheet` has pull-to-dismiss built-in, it doesn't offer a true full-screen presentation. FullScreenSheet bridges this gap by providing **two implementation options**:

### FullScreenSheet (Public API)
- **Pull-to-dismiss gesture** that feels native and responsive, a recreation of what's availble privately
- **Seamless scroll integration** - works with `List`, `ScrollView`, and `UICollectionView`
- **Smart gesture coordination** - only activates when scrolled to the top and pulling down
- **Custom backgrounds** that move in sync with the dismissal gesture
- **Velocity-aware dismissal** - accounts for both drag distance and swipe speed
- **100% App Store safe** - uses only public APIs

### FullScreenSheetPrivate (Private API)
- **Apple Music-style presentation** - identical to the native Music app
- **True full-screen with dimming effect** - underlying view sinks/dims during presentation (iOS 18<)
- **Simpler integration** - works with standard `.sheet()` modifier
- **Obfuscated private APIs** - reduces detection risk (but see warnings below)

## Installation

### Swift Package Manager

Add FullScreenSheet to your project via Xcode:

1. Go to **File → Add Package Dependencies...**
2. Enter the repository URL
3. Select the version you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aeastr/FullScreenSheet.git", from: "1.0.0")
]
```

Then add the target you want to use:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "FullScreenSheet", package: "FullScreenSheet"),
        // OR
        .product(name: "FullScreenSheetPrivate", package: "FullScreenSheet")
    ]
)
```

## Usage

### Option 1: FullScreenSheet (Public API - Recommended)

Safe for App Store submission and uses only public APIs.

#### Basic Usage

```swift
import SwiftUI
import FullScreenSheet

struct ContentView: View {
    @State private var showSheet = false

    var body: some View {
        Button("Show Sheet") {
            showSheet = true
        }
        .fullScreenSheet(isPresented: $showSheet) {
            ScrollView {
                // Your content here
            }
        }
    }
}
```

#### With onDismiss Callback

```swift
.fullScreenSheet(isPresented: $showSheet, onDismiss: {
    print("Sheet was dismissed")
}) {
    Text("Hello")
}
```

#### Item-Based Presentation

```swift
struct Item: Identifiable {
    let id = UUID()
    let name: String
}

struct ContentView: View {
    @State private var selectedItem: Item?

    var body: some View {
        Button("Show Item") {
            selectedItem = Item(name: "Example")
        }
        .fullScreenSheet(item: $selectedItem) { item in
            Text("Showing: \(item.name)")
        }
    }
}
```

#### All API Variants

```swift
// Boolean binding
.fullScreenSheet(isPresented: $showSheet) { }

// Boolean binding with onDismiss
.fullScreenSheet(isPresented: $showSheet, onDismiss: { }) { }

// Item-based
.fullScreenSheet(item: $selectedItem) { item in }

// Item-based with onDismiss
.fullScreenSheet(item: $selectedItem, onDismiss: { }) { item in }
```

### Option 2: FullScreenSheetPrivate (Private API - Use at Your Own Risk)

Provides Apple Music-style presentation using private APIs.

```swift
import SwiftUI
import FullScreenSheetPrivate

struct ContentView: View {
    @State private var showSheet = false

    var body: some View {
        Button("Show Sheet") {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            ScrollView {
                // Your content here
            }
            .presentationFullScreen(.enabled)
        }
    }
}
```

#### PresentationFullScreenBehavior Options

- `.automatic` - Standard sheet behavior (default)
- `.enabled` - Apple Music-style full-screen with interactive dismiss

### Custom Backgrounds (FullScreenSheet only)

**Important:** You must use `presentationFullScreenBackground` instead of the standard `.presentationBackground` modifier. This is required because the background needs to move in sync with the sheet during the pull-to-dismiss gesture. The standard modifier doesn't support this animation coordination.

**Note:** This only applies to the public `FullScreenSheet` target. When using `FullScreenSheetPrivate`, use standard SwiftUI presentation modifiers like `.presentationBackground()`.

### Navigation Transitions (FullScreenSheet only)

When using `.navigationTransition` with matched geometry effects (like `.zoom`), the custom pull-to-dismiss gesture is automatically disabled. This prevents conflicts between the gesture system and the navigation transition animations, allowing the matched geometry effect to work properly.

```swift
@Namespace var namespace

// Source view
Circle()
    .matchedTransitionSource(id: "circle", in: namespace)

// In fullScreenSheet
.fullScreenSheet(isPresented: $showSheet) {
    Circle()
        .navigationTransition(.zoom(sourceID: "circle", in: namespace))
    // Pull-to-dismiss is automatically disabled here
}
```

#### Using a ShapeStyle

```swift
.fullScreenSheet(isPresented: $showSheet) {
    Text("Hello!")
        .presentationFullScreenBackground(.purple.gradient)
}
```

#### Using a Custom View

```swift
.fullScreenSheet(isPresented: $showSheet) {
    Text("Hello!")
        .presentationFullScreenBackground {
            LinearGradient(
                colors: [.orange, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
}
```

#### Using a Custom View with Alignment

```swift
.fullScreenSheet(isPresented: $showSheet) {
    Text("Hello!")
        .presentationFullScreenBackground(alignment: .topLeading) {
            Image(systemName: "star.fill")
                .resizable()
                .frame(width: 200, height: 200)
                .foregroundStyle(.yellow.opacity(0.3))
        }
}
```

## About Private APIs (FullScreenSheetPrivate)

The `FullScreenSheetPrivate` target uses private APIs to achieve Apple Music-style presentation behavior.

### Implementation Details

This target uses the following private APIs on `UISheetPresentationController`:
- `_wantsFullScreen` - Enables true full-screen presentation mode with dimming effect
- `_allowsInteractiveDismissWhenFullScreen` - Allows swipe-to-dismiss from full-screen state

### Obfuscation

The private API strings are **obfuscated at compile-time** using the [Obfuscate](https://github.com/Aeastr/Obfuscate) macro. This converts the strings to base64-encoded byte arrays, reducing visibility during static analysis.

### Important Notes

1. **App Store Review** - Private API usage may be detected during App Store review, even with obfuscation
2. **No Guarantees** - Obfuscation cannot guarantee successful App Store submission
3. **Breaking Changes** - Private APIs can change or be removed in any iOS update without warning
4. **Use at Your Own Risk** - You are responsible for any consequences of using this in your applications

### Choose What Works for You

- **FullScreenSheet** - Public API implementation, safe for all use cases
- **FullScreenSheetPrivate** - Private API implementation with Apple Music-style presentation

Both targets are provided so you can choose the approach that best fits your needs.

## How It Works (FullScreenSheet - Public API)

FullScreenSheet uses a sophisticated gesture coordination system to provide smooth, native-feeling interactions:

### Gesture Coordination

1. **Custom Pan Gesture** - A UIKit-backed pan gesture recognizer integrates with SwiftUI's gesture system
2. **Simultaneous Recognition** - The gesture works alongside scroll view gestures by implementing `UIGestureRecognizerDelegate`
3. **Smart Activation** - Only activates when the scroll view is at the top (within 1 point) and the user is pulling downward

### Dismissal Logic

The sheet determines whether to dismiss or snap back based on two factors:

- **Translation distance** - How far the user pulled down
- **Velocity** - How fast the user was pulling (scaled down by 5x and clamped)

If `(translation + velocity) > halfHeight`, the sheet dismisses. Otherwise, it animates back to position.

### State Management

During a pull-to-dismiss gesture:

1. **Began** - Scrolling is disabled, offset starts tracking finger position
2. **Changed** - Offset updates in real-time as the user drags
3. **Ended** - Gesture is disabled, sheet either dismisses or snaps back with animation
4. **Snap-back** - If not dismissing, scroll is re-enabled after a 0.3s animation

### Background Synchronization

The custom background system uses SwiftUI's preference key mechanism:

1. Child views set a background preference using `presentationFullScreenBackground`
2. The preference propagates up the view hierarchy
3. The sheet view listens for changes via `onPreferenceChange`
4. Both content and background apply the same vertical offset during drag
5. This creates a cohesive, unified dismissal animation

## License

FullScreenSheet is available under the MIT license. See the LICENSE file for more info.
