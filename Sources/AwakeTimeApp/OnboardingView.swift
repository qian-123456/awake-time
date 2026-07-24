import AwakeTimeKit
import SwiftUI

struct OnboardingView: View {
  @EnvironmentObject private var appState: AppState
  @State private var launchAtLogin = true

  private var language: AppLanguage { appState.language }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Image(systemName: "sun.horizon.fill")
        .font(.system(size: 30))
        .foregroundStyle(.orange)

      VStack(alignment: .leading, spacing: 6) {
        Text(L10n.text("onboarding.title", language))
          .font(.title2.weight(.semibold))
        Text(L10n.text("onboarding.body", language))
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Toggle(isOn: $launchAtLogin) {
        VStack(alignment: .leading, spacing: 3) {
          Text(L10n.text("onboarding.login", language))
          Text(L10n.text("onboarding.loginBody", language))
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .toggleStyle(.switch)

      Button {
        appState.completeOnboarding(launchAtLogin: launchAtLogin)
      } label: {
        Text(L10n.text("onboarding.continue", language))
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
    }
    .padding(20)
    .frame(width: 360)
  }
}
