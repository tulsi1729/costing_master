import 'package:flutter/material.dart';

/// The user's business details, printed on every quote they share.
@immutable
class BusinessProfile {
  final String businessName;
  final String ownerName;
  final String phone;
  final String city;
  final String tagline;
  final String logoUrl;

  const BusinessProfile({
    this.businessName = '',
    this.ownerName = '',
    this.phone = '',
    this.city = '',
    this.tagline = '',
    this.logoUrl = '',
  });

  bool get isEmpty => businessName.trim().isEmpty;

  BusinessProfile copyWith({
    String? businessName,
    String? ownerName,
    String? phone,
    String? city,
    String? tagline,
    String? logoUrl,
  }) =>
      BusinessProfile(
        businessName: businessName ?? this.businessName,
        ownerName: ownerName ?? this.ownerName,
        phone: phone ?? this.phone,
        city: city ?? this.city,
        tagline: tagline ?? this.tagline,
        logoUrl: logoUrl ?? this.logoUrl,
      );

  Map<String, dynamic> toMap() => {
        'businessName': businessName,
        'ownerName': ownerName,
        'phone': phone,
        'city': city,
        'tagline': tagline,
        'logoUrl': logoUrl,
      };

  factory BusinessProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const BusinessProfile();
    String read(String key) => map[key] as String? ?? '';
    return BusinessProfile(
      businessName: read('businessName'),
      ownerName: read('ownerName'),
      phone: read('phone'),
      city: read('city'),
      tagline: read('tagline'),
      logoUrl: read('logoUrl'),
    );
  }
}

enum QuoteTemplate { royal, classic, minimal }

/// Trim colour of the royal quote template. Quotes are the user's document,
/// so they keep their own colours whatever the app theme is.
const quoteGold = Color(0xFFC9A227);

/// Accent colours a user can pick for their quote.
const quoteAccents = <Color>[
  Color(0xFF5B2A86), // plum
  Color(0xFF8E1B3A), // maroon
  Color(0xFF0F6B4F), // emerald
  Color(0xFF1E3A8A), // royal blue (default)
  Color(0xFFB4530A), // saffron
  Color(0xFF262626), // charcoal
];

@immutable
class QuoteStyle {
  final QuoteTemplate template;
  final int accentIndex;
  final bool showPhoto;
  final bool showItems;
  final bool showDate;
  final bool gujaratiDigits;
  final bool showFooter;

  const QuoteStyle({
    this.template = QuoteTemplate.royal,
    this.accentIndex = 3,
    this.showPhoto = true,
    this.showItems = true,
    this.showDate = true,
    this.gujaratiDigits = false,
    this.showFooter = true,
  });

  Color get accent =>
      quoteAccents[accentIndex.clamp(0, quoteAccents.length - 1)];

  QuoteStyle copyWith({
    QuoteTemplate? template,
    int? accentIndex,
    bool? showPhoto,
    bool? showItems,
    bool? showDate,
    bool? gujaratiDigits,
    bool? showFooter,
  }) =>
      QuoteStyle(
        template: template ?? this.template,
        accentIndex: accentIndex ?? this.accentIndex,
        showPhoto: showPhoto ?? this.showPhoto,
        showItems: showItems ?? this.showItems,
        showDate: showDate ?? this.showDate,
        gujaratiDigits: gujaratiDigits ?? this.gujaratiDigits,
        showFooter: showFooter ?? this.showFooter,
      );

  Map<String, dynamic> toMap() => {
        'template': template.name,
        'accentIndex': accentIndex,
        'showPhoto': showPhoto,
        'showItems': showItems,
        'showDate': showDate,
        'gujaratiDigits': gujaratiDigits,
        'showFooter': showFooter,
      };

  factory QuoteStyle.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const QuoteStyle();
    const defaults = QuoteStyle();
    bool read(String key, bool fallback) => map[key] as bool? ?? fallback;
    return QuoteStyle(
      template: QuoteTemplate.values.asNameMap()[map['template']] ??
          defaults.template,
      accentIndex:
          (map['accentIndex'] as num?)?.toInt() ?? defaults.accentIndex,
      showPhoto: read('showPhoto', defaults.showPhoto),
      showItems: read('showItems', defaults.showItems),
      showDate: read('showDate', defaults.showDate),
      gujaratiDigits: read('gujaratiDigits', defaults.gujaratiDigits),
      showFooter: read('showFooter', defaults.showFooter),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QuoteStyle &&
      other.template == template &&
      other.accentIndex == accentIndex &&
      other.showPhoto == showPhoto &&
      other.showItems == showItems &&
      other.showDate == showDate &&
      other.gujaratiDigits == gujaratiDigits &&
      other.showFooter == showFooter;

  @override
  int get hashCode => Object.hash(template, accentIndex, showPhoto, showItems,
      showDate, gujaratiDigits, showFooter);
}

/// The app's colour palette. [system] follows the phone's wallpaper colours
/// (Android 12+) and falls back to [navy].
enum AppColor {
  system(Color(0xFF1F3A5F)),
  navy(Color(0xFF1F3A5F)),
  teal(Color(0xFF00696B)),
  emerald(Color(0xFF1B6B45)),
  maroon(Color(0xFF8E1B3A)),
  graphite(Color(0xFF4A5560));

  const AppColor(this.seed);

  final Color seed;
}

@immutable
class AppSettings {
  final BusinessProfile profile;
  final QuoteStyle quoteStyle;
  final ThemeMode themeMode;
  final AppColor appColor;

  /// Whether we already asked the user to add their business name.
  final bool profilePrompted;

  const AppSettings({
    this.profile = const BusinessProfile(),
    this.quoteStyle = const QuoteStyle(),
    this.themeMode = ThemeMode.system,
    this.appColor = AppColor.system,
    this.profilePrompted = false,
  });

  AppSettings copyWith({
    BusinessProfile? profile,
    QuoteStyle? quoteStyle,
    ThemeMode? themeMode,
    AppColor? appColor,
    bool? profilePrompted,
  }) =>
      AppSettings(
        profile: profile ?? this.profile,
        quoteStyle: quoteStyle ?? this.quoteStyle,
        themeMode: themeMode ?? this.themeMode,
        appColor: appColor ?? this.appColor,
        profilePrompted: profilePrompted ?? this.profilePrompted,
      );

  /// Fields stored on the `users/{uid}` document, next to `name` and `uid`.
  Map<String, dynamic> toMap() => {
        'profile': profile.toMap(),
        'quoteStyle': quoteStyle.toMap(),
        'themeMode': themeMode.name,
        'appColor': appColor.name,
        'profilePrompted': profilePrompted,
      };

  factory AppSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AppSettings();
    Map<String, dynamic>? nested(String key) =>
        map[key] == null ? null : Map<String, dynamic>.from(map[key] as Map);
    return AppSettings(
      profile: BusinessProfile.fromMap(nested('profile')),
      quoteStyle: QuoteStyle.fromMap(nested('quoteStyle')),
      themeMode:
          ThemeMode.values.asNameMap()[map['themeMode']] ?? ThemeMode.system,
      appColor: AppColor.values.asNameMap()[map['appColor']] ?? AppColor.system,
      profilePrompted: map['profilePrompted'] as bool? ?? false,
    );
  }
}
