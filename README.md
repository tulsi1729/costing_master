# કોસ્ટિંગ માસ્ટર · Costing Master

Saree embroidery costing for Gujarati workshops: enter diamonds, sagadi and
labour on one screen, see the final price update live, then share a branded
quote on WhatsApp.

## Flow

1. **Clients**: search, add (duplicate names are rejected).
2. **Designs**: a photo grid per client with search, sort and the final price.
3. **Calculator**: one screen with the photo, name and design number, then collapsible
   sections (Patti and Buta diamonds, Sagadi, Labour, Vatav and Profit) and a sticky
   total bar.
4. **Quote**: a shareable image in two modes:
   - *ગ્રાહક માટે* (customer): vatav and profit are folded into each line, so the
     lines add up to the final price and the margins never show.
   - *મારા માટે* (internal): the full breakdown with vatav and profit.
5. **મારો બિઝનેસ**: business name, logo and contact details, quote template
   (Royal, Classic, Minimal), accent colour, Gujarati numerals and app theme, with a
   live preview.

## Architecture

- `lib/domain/costing_calculator.dart` holds all costing arithmetic. The
  calculator, the quote and save all use it, and it is covered by
  `test/costing_calculator_test.dart`.
- State is managed with Riverpod 3. The calculator draft is a family notifier, and
  each row watches only its own slice (`select`), so typing rebuilds a single row
  and the total bar.
- The Firestore schema is unchanged. The only additions are `updatedAt` on
  costings and `profile`, `quoteStyle` and `themeMode` on `users/{uid}`.
- Images are uploaded as `costings/<uid>_<costingGuid>_<timestamp>.jpg`. They are
  downscaled on pick (1600px, quality 75).

## Development

```sh
flutter pub get
flutter analyze
flutter test
```

Release build (smaller and obfuscated):

```sh
flutter build appbundle --obfuscate --split-debug-info=build/symbols
```

Launcher icons are rendered from `lib/widgets/brand_mark.dart` into
`assets/icon/`. Regenerate the platform icons with `dart run flutter_launcher_icons`.

## Toolchain versions

See [VERSIONS.md](VERSIONS.md) for the exact Flutter, Java, Gradle, AGP and Kotlin versions this project builds with.

## Store screenshots and icons

- `screenshots/` holds the Play Store screenshots (1080×2408). To retake them, run the demo build, which **replaces the phone's data** with a sample workshop: `flutter run --profile -t tool/screenshots_main.dart`. Turn off the phone's eye-comfort / blue-light filter first.
- Launcher icons are drawn from `lib/widgets/brand_mark.dart`: `flutter test tool/render_icons_test.dart && dart run flutter_launcher_icons`.
