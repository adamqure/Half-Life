//  _______  __   __  ___   ___      ___      _______  __    _  _______
// |       ||  | |  ||   | |   |    |   |    |   _   ||  |  | ||       |
// |   _   ||  | |  ||   | |   |    |   |    |  |_|  ||   |_| ||   _   |
// |  | |  ||  |_|  ||   | |   |    |   |    |       ||       ||  | |  |
// |  |_|  ||       ||   | |   |___ |   |___ |       ||  _    ||  |_|  |
// |      | |       ||   | |       ||       ||   _   || | |   ||      |
// |____||_||_______||___| |_______||_______||__| |__||_|  |__||____||_|
//
// Half-Life AboutYouSettingsView
//

import ComposableArchitecture
import SwiftUI

/// Settings' About you screen: the user's first name and age, as onboarding's About you step asks them.
///
/// The name field wraps, so Return types a newline, which commits the name, as leaving the field does. Once the name
/// is committed, the field lets go of the keyboard, which would otherwise stay up over the tab bar. The age is a
/// wheel, which passes the accessibility audit where iOS's menu picker didn't. See the Settings article.
@MainActor
struct AboutYouSettingsView: View {
    /// The screen's store.
    @Bindable var store: StoreOf<ProfileSettingsFeature>

    @FocusState private var isNameFocused: Bool

    /// The name field and the age wheel.
    var body: some View {
        SettingsScreen(title: Text("About you"), screenIdentifier: AboutYouSettingsViewAccessibilityID.screen) {
            VStack(alignment: .leading, spacing: Spacing.sectionHeaderGap) {
                Text("First name")
                    .font(.footnote)
                    .foregroundStyle(Color.textPrimary)
                TextField(text: $store.name, prompt: Text("Your first name"), axis: .vertical) {
                    Text("First name")
                }
                .lineLimit(1...3)
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isNameFocused)
                .onSubmit { store.send(.nameCommitted) }
                .font(.body)
                .foregroundStyle(Color.textPrimary)
                .padding(.horizontal, Spacing.cardPaddingCompact)
                .padding(.vertical, Spacing.itemGap)
                .frame(minHeight: Sizing.chipHeight)
                .background(
                    Color.surfaceControl, in: RoundedRectangle(cornerRadius: CornerRadius.small, style: .continuous)
                )
                .accessibilityIdentifier(AboutYouSettingsViewAccessibilityID.nameField)
                Text("Age")
                    .font(.footnote)
                    .foregroundStyle(Color.textPrimary)
                    .padding(.top, Spacing.itemGap)
                Picker(selection: $store.age) {
                    Text("Prefer not to say").tag(Int?.none)
                    ForEach(AboutYouFeature.ages, id: \.self) { age in
                        Text(age.formatted()).tag(Int?.some(age))
                    }
                } label: {
                    Text("Age")
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .background(
                    Color.surfaceCard, in: RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous)
                )
                .accessibilityIdentifier(AboutYouSettingsViewAccessibilityID.agePicker)
            }
        }
        .onChange(of: isNameFocused) { _, isFocused in
            if !isFocused {
                store.send(.nameCommitted)
            }
        }
        // Once the name is committed, by a newline or by choosing an age, the field lets go of the keyboard.
        .onChange(of: store.isEditingName) { wasEditing, isEditing in
            if wasEditing && !isEditing {
                isNameFocused = false
            }
        }
        .task { await store.send(.task).finish() }
    }
}
