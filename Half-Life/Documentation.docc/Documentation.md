# ``Half_Life``

Record caffeine intake on device, with optional Apple Health integration.

## Overview

Half-Life is an iOS app built with SwiftUI and The Composable Architecture (TCA).

The principles every change must follow live in `constitution.md` at the repository root. This catalog documents how the app is actually built: its features, dependency clients, navigation, and data. Per constitution Article VIII, any change that alters the architecture updates this catalog in the same change.

## Topics

### Architecture

- <doc:Architecture>
- <doc:Logging>
- <doc:LanguageModel>

### Caffeine model

- <doc:CaffeineDecayModel>
- <doc:CaffeineCutoff>
- <doc:CutoffReminder>
- <doc:HalfLifeEstimator>

### Apple Health

- <doc:RestingHeartRate>
- <doc:SleepData>
- <doc:StepCount>

### Features

- <doc:DrinkComposer>
- <doc:OneTapLog>
- <doc:AppIntents>
- <doc:Widgets>
- <doc:TodayScreen>
- <doc:AppleHealthCard>
- <doc:Insights>
- <doc:Onboarding>
- <doc:Settings>
- <doc:AppLock>
- <doc:SplashScreen>

### Design

- <doc:DesignSystem>
