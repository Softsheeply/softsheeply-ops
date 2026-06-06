# ShiftRest — Google Play Release Checklist

## 1. Build signed release APK / AAB

```bash
# Generate a keystore (do this once, keep the file safe)
keytool -genkey -v -keystore shiftrest-release.jks \
  -alias shiftrest -keyalg RSA -keysize 2048 -validity 10000

# Add to android/key.properties (DO NOT commit this file):
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=shiftrest
storeFile=../../shiftrest-release.jks
```

Add to `android/app/build.gradle`:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

```bash
# Build the Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# Or build APK for direct distribution
flutter build apk --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 2. Add to .gitignore

```
# Signing keys — never commit
android/key.properties
*.jks
*.keystore
```

---

## 3. Google Play Console setup

### Create app
- [ ] Go to play.google.com/console
- [ ] Create new app → "ShiftRest"
- [ ] Set default language: English (United States)
- [ ] App or game: App
- [ ] Free or paid: Free

### App content
- [ ] Privacy policy URL: `https://softsheeply.com/shiftrest/privacy`
  - Host `store/privacy_policy.html` at that URL
- [ ] App category: Health & Fitness
- [ ] Contact email: hello@softsheeply.com
- [ ] Content rating questionnaire → fill out → rated Everyone

### Store listing
- [ ] App name: `ShiftRest: Sleep Planner for Shift Work`
- [ ] Short description: (from store_listing.md)
- [ ] Full description: (from store_listing.md)
- [ ] App icon: 512×512px PNG (high-res icon — deep navy bg, moon icon)
- [ ] Feature graphic: 1024×500px JPG/PNG
- [ ] Screenshots: minimum 2, ideally 5 (phone screenshots at 1080×1920 or 1080×2340)
- [ ] Promo video: optional YouTube link

### Minimum screenshot set (5 recommended)
1. Home screen (today's shift + sleep window)
2. Planner screen (sleep window cards)
3. Shift patterns screen
4. Sleep history (charts)
5. Tools screen (caffeine or melatonin tab)

---

## 4. App bundle / APK upload

- [ ] Upload `app-release.aab` to a new release in Internal Testing
- [ ] Add yourself as internal tester
- [ ] Install and smoke-test on a real Android device
- [ ] Promote to Production when ready

---

## 5. Pre-launch checklist

- [ ] Test onboarding flow end-to-end
- [ ] Add at least one shift and verify planner generates plans
- [ ] Log a sleep entry, verify it appears in history
- [ ] Test all 4 tools tabs
- [ ] Verify notifications schedule (requires real device or emulator with notifications enabled)
- [ ] Test "Clear all data" in settings
- [ ] Verify app works offline (no internet needed at all)
- [ ] Check dark mode looks correct on AMOLED screens
- [ ] Test on Android 7 (API 24) minimum if possible — minSdk is 21 but most users are on 8+

---

## 6. Post-launch

- [ ] Set up Google Play crash reporting (Play Console → Android Vitals)
- [ ] Monitor reviews and respond within 24–48 hours
- [ ] Consider adding Play In-App Review API for rating prompts after 3rd sleep log
- [ ] Plan v1.1: widget support (home screen sleep window widget)

---

## App version history

| Version | Build | Notes |
|---------|-------|-------|
| 1.0.0 | 1 | Initial release |
