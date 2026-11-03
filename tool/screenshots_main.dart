// The app with a realistic demo workshop, for Play Store screenshots:
//
//   flutter run --profile -t tool/screenshots_main.dart
//
// WARNING: replaces everything stored on the phone (and signs out) with the
// demo data. Never shipped: the real app starts from lib/main.dart.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:costing_master/common/enums.dart';
import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/firebase_options.dart';
import 'package:costing_master/main.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/diamond_costing.dart';
import 'package:costing_master/model/sagadi_costing.dart';
import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/storage/image_storage.dart';
import 'package:costing_master/storage/local_db.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.signOut();
  final localDb = await LocalDb.open();
  await LocalImages.init();
  await _seed(localDb);
  runApp(ProviderScope(
    overrides: [localDbProvider.overrideWithValue(localDb)],
    child: const CostingMasterApp(),
  ));
}

const _settings = AppSettings(
  profile: BusinessProfile(
    businessName: 'શ્રી રામ ફેશન',
    ownerName: 'અમિત વસાણી',
    phone: '95371 74465',
    city: 'સુરત',
    tagline: 'હેન્ડવર્ક અને ડાયમંડ વર્ક સ્પેશિયાલિસ્ટ',
  ),
  appColor: AppColor.navy,
  themeMode: ThemeMode.light,
  profilePrompted: true,
);

/// (name, city, phone)
const _clients = [
  ('લક્ષ્મી સાડી સેન્ટર', 'સુરત', '98251 23456'),
  ('રાધે ફેશન', 'અમદાવાદ', '97234 56789'),
  ('ઓમ સાઈ સારીઝ', 'વડોદરા', ''),
  ('પટેલ ક્રિએશન', 'સુરત', '99090 11223'),
  ('શિવમ ટેક્સટાઇલ્સ', 'રાજકોટ', ''),
];

/// One design: client index, name, design no., days ago, photo palette and
/// a scale for its work (bigger designs carry more diamonds and labour).
typedef _Design = (int, String, int, int, (Color, Color), double);

const _designs = <_Design>[
  (0, 'રાની પટોળા', 108, 0, (Color(0xFF7A1530), Color(0xFFD4A537)), 1.0),
  (0, 'પીકોક પલ્લુ', 112, 2, (Color(0xFF0E4D5C), Color(0xFFE2C26B)), 1.3),
  (0, 'બાંધણી ગોલ્ડ', 97, 9, (Color(0xFFB0301C), Color(0xFFF1D27A)), 0.8),
  (1, 'કાંજીવરમ બુટા', 121, 1, (Color(0xFF1F3A73), Color(0xFFDDB75A)), 1.5),
  (1, 'ગુલાબી જાળ', 118, 4, (Color(0xFFB03A6E), Color(0xFFF3D9A0)), 0.9),
  (2, 'ઓરેન્જ લહેરિયા', 87, 6, (Color(0xFFC9581A), Color(0xFFF6E1A6)), 0.7),
  (2, 'રોયલ બ્લૂ બોર્ડર', 90, 14, (Color(0xFF16307A), Color(0xFFCFAE55)), 1.1),
  (3, 'મરૂન ઝરી', 131, 3, (Color(0xFF5E1020), Color(0xFFE0B654)), 1.2),
  (3, 'ગ્રીન બનારસી', 129, 11, (Color(0xFF1C5B3A), Color(0xFFE5C76E)), 1.0),
  (4, 'પર્પલ ડાયમંડ', 76, 20, (Color(0xFF4A2367), Color(0xFFE3C46A)), 0.9),
];

Future<void> _seed(LocalDb local) async {
  await local.clear();
  await LocalImages.clear();
  await local.settings
      .record(LocalDb.settingsKey)
      .put(local.db, _settings.toMap());

  final now = DateTime.now();
  final clients = [
    for (final (name, city, phone) in _clients)
      Client(name: name, city: city, phone: phone, createdBy: ''),
  ];
  for (final client in clients) {
    await local.clients.record(client.guid).put(local.db, client.toMap());
  }

  final temp = await getTemporaryDirectory();
  for (final (i, (clientIndex, name, designNo, daysAgo, palette, scale))
      in _designs.indexed) {
    final png = await _designPhoto(palette, seed: i);
    final file = await File('${temp.path}/demo_$i.png').writeAsBytes(png);
    final photo = await LocalImages.save(file, 'demo_$i');
    final costing = _costing(
      clientGuid: clients[clientIndex].guid,
      name: name,
      designNo: designNo,
      photo: photo,
      scale: scale,
      savedAt: now.subtract(Duration(days: daysAgo, hours: i)),
    );
    await local.costings.record(costing.guid).put(local.db, costing.toMap());
  }
}

Costing _costing({
  required String clientGuid,
  required String name,
  required int designNo,
  required String photo,
  required double scale,
  required DateTime savedAt,
}) {
  int count(num base) => (base * scale).round();
  DiamondCosting diamond(PartType part, DiamondType type, int perPart,
          double parts, double ratePer100) =>
      DiamondCosting(
        diamondType: type,
        partType: part,
        diamondsPerPart: count(perPart),
        numbersOfPartsPerSari: parts,
        diamondRate: ratePer100 / diamondRateUnit,
      );

  return CostingCalculator.withTotals(Costing(
    guid: 'demo-$designNo',
    createdBy: '',
    clientGuid: clientGuid,
    designNo: designNo,
    sariName: name,
    imageUrl: photo,
    sheetBharvana: 60,
    lessFiting: 25,
    reniyaCutting: 10,
    fusing: 12,
    dieKapvana: scale > 1 ? 15 : 0,
    otherCost: 8,
    vatavPercentage: 2,
    profitPercentage: 15,
    totalExpense: 0,
    totalChargesPlusVatavAmount: 0,
    totalChargesPlusVatavPlusProfit: 0,
    updatedAt: savedAt.millisecondsSinceEpoch,
    diamondCostingsMap: {
      PartType.patti: {
        DiamondType.shadow:
            diamond(PartType.patti, DiamondType.shadow, 40, 12, 45),
        DiamondType.jarkan:
            diamond(PartType.patti, DiamondType.jarkan, 18, 12, 60),
      },
      PartType.buta: {
        DiamondType.dmc: diamond(PartType.buta, DiamondType.dmc, 8, 60, 30),
      },
    },
    sagadiCostingsMap: {
      SagadiItemType.buta: SagadiCosting(
          itemType: SagadiItemType.buta,
          itemsCount: count(60).toDouble(),
          chargePerItem: 1.5),
      SagadiItemType.less: SagadiCosting(
          itemType: SagadiItemType.less, itemsCount: 2, chargePerItem: 25),
    },
  ));
}

/// A saree-like swatch: a rich ground, a gold border band and rows of
/// small embroidered butas.
Future<List<int>> _designPhoto((Color, Color) palette,
    {required int seed}) async {
  const width = 720.0, height = 960.0;
  final (ground, gold) = palette;
  final random = math.Random(seed);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(width, height),
        [
          Color.lerp(ground, Colors.white, 0.08)!,
          Color.lerp(ground, Colors.black, 0.25)!
        ],
      ),
  );

  // Pallu band with a diamond chain.
  const band = 190.0;
  const bandTop = height - band;
  canvas.drawRect(const Rect.fromLTWH(0, bandTop, width, band),
      Paint()..color = Color.lerp(ground, Colors.black, 0.35)!);
  final goldPaint = Paint()..color = gold;
  final line = Paint()
    ..color = gold
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  canvas
    ..drawLine(
        const Offset(0, bandTop + 14), const Offset(width, bandTop + 14), line)
    ..drawLine(
        const Offset(0, height - 14), const Offset(width, height - 14), line);
  for (var x = 30.0; x < width; x += 60) {
    final c = Offset(x, bandTop + band / 2);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - 34)
        ..lineTo(c.dx + 22, c.dy)
        ..lineTo(c.dx, c.dy + 34)
        ..lineTo(c.dx - 22, c.dy)
        ..close(),
      line,
    );
    canvas.drawCircle(c, 7, goldPaint);
  }

  // Butas: a ring of petals around a stone, staggered rows.
  final shine = Paint()..color = Colors.white.withValues(alpha: 0.85);
  final petalSize = 10 + random.nextDouble() * 6;
  for (var row = 0; row * 120.0 + 80 < bandTop - 30; row++) {
    for (var col = 0; col < 7; col++) {
      final c = Offset(col * 120.0 + (row.isOdd ? 60 : 0), row * 120.0 + 80);
      if (c.dx > width + 20) continue;
      for (var p = 0; p < 6; p++) {
        final angle = p * math.pi / 3;
        canvas.drawCircle(
            c + Offset(math.cos(angle), math.sin(angle)) * (petalSize * 1.6),
            petalSize * 0.7,
            goldPaint);
      }
      canvas
        ..drawCircle(c, petalSize * 0.8, shine)
        ..drawCircle(c, petalSize * 0.45, goldPaint);
    }
  }

  final image =
      await recorder.endRecording().toImage(width.toInt(), height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
