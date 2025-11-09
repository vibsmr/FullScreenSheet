import SwiftUI

// MARK: - Demo Examples

#Preview("Basic Sheet") {
    @Previewable @State var isPresented = false

    NavigationStack {
        Button("Show Apple Music Style Sheet") {
            isPresented = true
        }
        .navigationTitle("Private API Demo")
        .sheet(isPresented: $isPresented) {
            ZStack {
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Full-Screen Sheet")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Swipe down to dismiss")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer()
                }
                .padding(.top, 60)
            }
            .presentationFullScreen(.enabled)
        }
    }
}

#Preview("List Content") {
    @Previewable @State var isPresented = false

    NavigationStack {
        Button("Show List") {
            isPresented = true
        }
        .navigationTitle("Private API Demo")
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                List {
                    ForEach(1...100, id: \.self) { index in
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundStyle(.blue)
                            Text("Song \(index)")
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Now Playing")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .presentationFullScreen(.enabled)
        }
    }
}

#Preview("ScrollView Content") {
    @Previewable @State var isPresented = false

    NavigationStack {
        Button("Show ScrollView") {
            isPresented = true
        }
        .navigationTitle("Private API Demo")
        .sheet(isPresented: $isPresented) {
            ScrollView {
                VStack(spacing: 20) {
                    // Album artwork
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.gradient)
                        .frame(width: 300, height: 300)
                        .shadow(radius: 20)
                        .padding(.top, 60)

                    // Song info
                    VStack(spacing: 8) {
                        Text("Song Title")
                            .font(.title)
                            .fontWeight(.semibold)

                        Text("Artist Name")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Controls
                    HStack(spacing: 40) {
                        Button {} label: {
                            Image(systemName: "backward.fill")
                                .font(.title)
                        }

                        Button {} label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 50))
                        }

                        Button {} label: {
                            Image(systemName: "forward.fill")
                                .font(.title)
                        }
                    }
                    .padding(.top, 40)

                    // Up next section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Up Next")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)

                        ForEach(1...20, id: \.self) { index in
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upcoming Song \(index)")
                                        .font(.body)
                                    Text("Artist \(index)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 40)
                }
            }
            .presentationFullScreen(.enabled)
        }
    }
}
