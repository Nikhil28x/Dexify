import SwiftUI

struct LaunchScreenView: View {
    var onNameEntered: (String) -> Void
    @State private var enteredName: String = ""
    @State private var animate = false
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            DS.Gradients.pageBackground
                .ignoresSafeArea()

            // Background accent glow
            Circle()
                .fill(DS.Colors.accent.opacity(0.15))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(y: -80)
                .scaleEffect(glowPulse ? 1.1 : 0.95)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: glowPulse)

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: DS.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(DS.Colors.accent.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Image(uiImage: #imageLiteral(resourceName: "dexify"))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .opacity(animate ? 1 : 0)
                    .scaleEffect(animate ? 1 : 0.7)
                    .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1), value: animate)

                    VStack(spacing: DS.Spacing.xs) {
                        Text("Dexify")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(DS.Colors.textPrimary)
                        Text("Track what matters.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 16)
                    .animation(.easeOut(duration: 0.7).delay(0.3), value: animate)
                }

                Spacer()

                // Input card
                VStack(spacing: DS.Spacing.md) {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("What should we call you?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.Colors.textSecondary)
                        DexTextField(placeholder: "Your name", text: $enteredName)
                    }

                    DexPrimaryButton("Get Started", icon: "arrow.right", isDisabled: enteredName.trimmingCharacters(in: .whitespaces).isEmpty) {
                        onNameEntered(enteredName.trimmingCharacters(in: .whitespaces))
                    }
                }
                .padding(DS.Spacing.lg)
                .background(DS.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.xl)
                        .stroke(DS.Colors.border, lineWidth: 1)
                )
                .padding(.horizontal, DS.Spacing.md)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 30)
                .animation(.easeOut(duration: 0.7).delay(0.55), value: animate)

                Spacer().frame(height: DS.Spacing.xl)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            animate = true
            glowPulse = true
        }
    }
}
