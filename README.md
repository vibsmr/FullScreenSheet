<div align="center">
  <h1><b>FullScreenSheet</b></h1>
  <p>
    A SwiftUI full-screen sheet with pull-to-dismiss gesture support that works seamlessly with scrollable content.
  </p>
</div>

<p align="center">
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-18%2B-purple.svg" alt="iOS 18+"></a>
  <a href="https://swift.org/"><img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6.0"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"></a>
</p>

---

## Why FullScreenSheet?

SwiftUI's native `.fullScreenCover` doesn't support interactive dismissal gestures. While `.sheet` has pull-to-dismiss built-in, it doesn't offer a true full-screen presentation. FullScreenSheet bridges this gap by providing:

- **Pull-to-dismiss gesture** that feels native and responsive
- **Seamless scroll integration** - works with `List`, `ScrollView`, and `UICollectionView`
- **Smart gesture coordination** - only activates when scrolled to the top and pulling down
- **Custom backgrounds** that move in sync with the dismissal gesture
- **Velocity-aware dismissal** - accounts for both drag distance and swipe speed

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

## Usage

### Basic Usage

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

### Custom Backgrounds

**Important:** You must use `presentationFullScreenBackground` instead of the standard `.presentationBackground` modifier. This is required because the background needs to move in sync with the sheet during the pull-to-dismiss gesture. The standard modifier doesn't support this animation coordination.

### Navigation Transitions

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

## How It Works

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
