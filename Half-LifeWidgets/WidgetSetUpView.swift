//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-LifeWidgets WidgetSetUpView
//

import SwiftUI

/// What both widgets show until onboarding is complete, or before the app has stored a snapshot. A tap opens the app.
@MainActor
struct WidgetSetUpView: View {
    /// The app's cup and the message.
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title3)
                .foregroundStyle(Color.textAccent)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
            Text("Finish setting up Half-Life")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
