import SwiftUI

@available(iOS 26.0, *)
#Preview("Demo") {
    @Previewable @State var showSheet = false

    NavigationStack {
        VStack {
            Spacer()

            Button {
                showSheet = true
            } label: {
                Text("Show Sheet")
            }
            .buttonStyle(.glassProminent)
            .tint(.black.mix(with: .teal, by: 0.6))
            .controlSize(.extraLarge)
            .padding(.horizontal, 40)

            Spacer()
        }
        .navigationTitle("FullScreenSheet")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenSheet(isPresented: $showSheet) {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(1...30, id: \.self) { index in
                        HStack {
                            Image(systemName: "\(index).circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.9))

                            Text("Item \(index)")
                                .font(.title3)
                                .foregroundStyle(.white)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding()
                        .background(.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .presentationFullScreenBackground{
                ConcentricRectangle()
                    .fill(LinearGradient(
                        colors: [.teal, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
        }
    }
}
