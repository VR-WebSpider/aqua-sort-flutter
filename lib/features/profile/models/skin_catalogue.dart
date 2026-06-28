import 'package:flutter/material.dart';

// ── Skin Tier ──────────────────────────────────────────────────────────────────
enum SkinTier { standard, premium, legendary }

extension SkinTierExt on SkinTier {
  String get label {
    switch (this) {
      case SkinTier.standard: return 'STANDARD';
      case SkinTier.premium: return 'PREMIUM';
      case SkinTier.legendary: return 'LEGENDARY';
    }
  }

  Color get color {
    switch (this) {
      case SkinTier.standard: return const Color(0xFF78909C);
      case SkinTier.premium: return const Color(0xFF00E5FF);
      case SkinTier.legendary: return const Color(0xFFFFD700);
    }
  }

  Color get bgColor {
    switch (this) {
      case SkinTier.standard: return const Color(0xFF1A2733);
      case SkinTier.premium: return const Color(0xFF00263A);
      case SkinTier.legendary: return const Color(0xFF2A1F00);
    }
  }
}

// ── Tube Skin Model ────────────────────────────────────────────────────────────
class TubeSkin {
  final String id;
  final String name;
  final SkinTier tier;
  final int price; // in Spider Gold Coins (0 = always owned)
  final List<Color> liquidColors; // colors for tube liquid segments
  final Color glowColor;          // border/glow color
  final Color borderColor;

  const TubeSkin({
    required this.id,
    required this.name,
    required this.tier,
    required this.price,
    required this.liquidColors,
    required this.glowColor,
    required this.borderColor,
  });
}

// ── Skin Catalogue ─────────────────────────────────────────────────────────────
class SkinCatalogue {
  SkinCatalogue._();

  // Skins ordered: default first, then standard, premium, legendary
  static const List<TubeSkin> all = [
    // ── Default (always owned, free) ──────────────────────────────────────────
    TubeSkin(
      id: 'default',
      name: 'Classic Glass',
      tier: SkinTier.standard,
      price: 0,
      liquidColors: [Color(0xFF00F5FF), Color(0xFF0066FF), Color(0xFF9DFF00), Color(0xFFBD00FF)],
      glowColor: Color(0xFF00E5FF),
      borderColor: Color(0xFF00B4CC),
    ),

    // ── Standard (500 Gold Coins) ─────────────────────────────────────────────
    TubeSkin(
      id: 'toxic_slime',
      name: 'Toxic Slime',
      tier: SkinTier.standard,
      price: 500,
      liquidColors: [Color(0xFF39FF14), Color(0xFF7CFC00), Color(0xFFADFF2F), Color(0xFF32CD32)],
      glowColor: Color(0xFF39FF14),
      borderColor: Color(0xFF7CFC00),
    ),
    TubeSkin(
      id: 'solar_flare',
      name: 'Solar Flare',
      tier: SkinTier.standard,
      price: 500,
      liquidColors: [Color(0xFFFF8C00), Color(0xFFFF4500), Color(0xFFFFD700), Color(0xFFFF6347)],
      glowColor: Color(0xFFFF8C00),
      borderColor: Color(0xFFFF6347),
    ),
    TubeSkin(
      id: 'arctic_frost',
      name: 'Arctic Frost',
      tier: SkinTier.standard,
      price: 500,
      liquidColors: [Color(0xFFB0E0FF), Color(0xFF87CEEB), Color(0xFFADD8E6), Color(0xFF00BFFF)],
      glowColor: Color(0xFFB0E0FF),
      borderColor: Color(0xFF87CEEB),
    ),
    TubeSkin(
      id: 'molten_core',
      name: 'Molten Core',
      tier: SkinTier.standard,
      price: 500,
      liquidColors: [Color(0xFFFF2400), Color(0xFFFF6000), Color(0xFFFFAA00), Color(0xFFFF3300)],
      glowColor: Color(0xFFFF2400),
      borderColor: Color(0xFFFF6000),
    ),

    // ── Premium (1000 Gold Coins) ─────────────────────────────────────────────
    TubeSkin(
      id: 'cyber_neon',
      name: 'Cyber Neon',
      tier: SkinTier.premium,
      price: 1000,
      liquidColors: [Color(0xFF00E5FF), Color(0xFF00B4CC), Color(0xFF18FFFF), Color(0xFF00FFFF)],
      glowColor: Color(0xFF00E5FF),
      borderColor: Color(0xFF00B4CC),
    ),
    TubeSkin(
      id: 'phantom_void',
      name: 'Phantom Void',
      tier: SkinTier.premium,
      price: 1000,
      liquidColors: [Color(0xFF7B00FF), Color(0xFFB000FF), Color(0xFF5500CC), Color(0xFF9900FF)],
      glowColor: Color(0xFFB000FF),
      borderColor: Color(0xFF7B00FF),
    ),
    TubeSkin(
      id: 'sakura',
      name: 'Sakura',
      tier: SkinTier.premium,
      price: 1000,
      liquidColors: [Color(0xFFFF69B4), Color(0xFFFF1493), Color(0xFFFFB6C1), Color(0xFFDB7093)],
      glowColor: Color(0xFFFF69B4),
      borderColor: Color(0xFFFF1493),
    ),
    TubeSkin(
      id: 'coral_reef',
      name: 'Coral Reef',
      tier: SkinTier.premium,
      price: 1000,
      liquidColors: [Color(0xFFFF7F50), Color(0xFF20B2AA), Color(0xFFFF6347), Color(0xFF48D1CC)],
      glowColor: Color(0xFFFF7F50),
      borderColor: Color(0xFF20B2AA),
    ),

    // ── Legendary (2500 Gold Coins) ───────────────────────────────────────────
    TubeSkin(
      id: 'dragon_fire',
      name: 'Dragon Fire',
      tier: SkinTier.legendary,
      price: 2500,
      liquidColors: [Color(0xFFFF0000), Color(0xFFFF6600), Color(0xFFFFCC00), Color(0xFFFF3300)],
      glowColor: Color(0xFFFFCC00),
      borderColor: Color(0xFFFF6600),
    ),
    TubeSkin(
      id: 'aurora',
      name: 'Aurora',
      tier: SkinTier.legendary,
      price: 2500,
      liquidColors: [Color(0xFF00FFAA), Color(0xFF00AAFF), Color(0xFFAA00FF), Color(0xFFFF00AA)],
      glowColor: Color(0xFF00FFAA),
      borderColor: Color(0xFF00AAFF),
    ),
    TubeSkin(
      id: 'obsidian_edge',
      name: 'Obsidian Edge',
      tier: SkinTier.legendary,
      price: 2500,
      liquidColors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460), Color(0xFF533483)],
      glowColor: Color(0xFF533483),
      borderColor: Color(0xFF0F3460),
    ),
    TubeSkin(
      id: 'celestial',
      name: 'Celestial',
      tier: SkinTier.legendary,
      price: 2500,
      liquidColors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFFF00), Color(0xFFDAA520)],
      glowColor: Color(0xFFFFD700),
      borderColor: Color(0xFFFFA500),
    ),
  ];

  static TubeSkin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);

  static List<TubeSkin> byTier(SkinTier tier) =>
      all.where((s) => s.tier == tier).toList();

  static Path getTubePath(String id, double w, double h, double lipH, double r) {
    final bodyH = h - lipH;
    
    switch (id) {
      case 'toxic_slime':
        // Bubble-ribbed organic tube
        return Path()
          ..moveTo(0, lipH)
          ..cubicTo(-w * 0.18, lipH + bodyH * 0.15, -w * 0.18, lipH + bodyH * 0.2, 0, lipH + bodyH * 0.32)
          ..cubicTo(-w * 0.18, lipH + bodyH * 0.47, -w * 0.18, lipH + bodyH * 0.52, 0, lipH + bodyH * 0.64)
          ..cubicTo(-w * 0.18, lipH + bodyH * 0.79, -w * 0.18, lipH + bodyH * 0.84, 0, h - r)
          ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r), clockwise: false)
          ..cubicTo(w + w * 0.18, lipH + bodyH * 0.84, w + w * 0.18, lipH + bodyH * 0.79, w, lipH + bodyH * 0.64)
          ..cubicTo(w + w * 0.18, lipH + bodyH * 0.52, w + w * 0.18, lipH + bodyH * 0.47, w, lipH + bodyH * 0.32)
          ..cubicTo(w + w * 0.18, lipH + bodyH * 0.2, w + w * 0.18, lipH + bodyH * 0.15, w, lipH)
          ..close();

      case 'solar_flare':
        // Conical beaker / Erlenmeyer flask
        final neckH = bodyH * 0.22;
        return Path()
          ..moveTo(w * 0.22, lipH)
          ..lineTo(w * 0.22, lipH + neckH)
          ..lineTo(w * 0.04, h - 8)
          ..quadraticBezierTo(0, h, 8, h)
          ..lineTo(w - 8, h)
          ..quadraticBezierTo(w, h, w - 0.04, h - 8)
          ..lineTo(w * 0.78, lipH + neckH)
          ..lineTo(w * 0.78, lipH)
          ..close();

      case 'arctic_frost':
        // Faceted octagonal cut
        return Path()
          ..moveTo(0, lipH)
          ..lineTo(0, h - 14)
          ..lineTo(w * 0.28, h)
          ..lineTo(w * 0.72, h)
          ..lineTo(w, h - 14)
          ..lineTo(w, lipH)
          ..close();

      case 'molten_core':
        // Heavy industrial recessed container
        return Path()
          ..moveTo(0, lipH)
          ..lineTo(0, lipH + bodyH * 0.1)
          ..lineTo(w * 0.08, lipH + bodyH * 0.14)
          ..lineTo(w * 0.08, h - bodyH * 0.14)
          ..lineTo(0, h - bodyH * 0.1)
          ..lineTo(0, h - 4)
          ..quadraticBezierTo(0, h, 4, h)
          ..lineTo(w - 4, h)
          ..quadraticBezierTo(w, h, w, h - 4)
          ..lineTo(w, h - bodyH * 0.1)
          ..lineTo(w * 0.92, h - bodyH * 0.14)
          ..lineTo(w * 0.92, lipH + bodyH * 0.14)
          ..lineTo(w, lipH + bodyH * 0.1)
          ..lineTo(w, lipH)
          ..close();

      case 'cyber_neon':
        // Beveled corner pod
        return Path()
          ..moveTo(0, lipH)
          ..lineTo(0, h - 10)
          ..lineTo(10, h)
          ..lineTo(w - 10, h)
          ..lineTo(w, h - 10)
          ..lineTo(w, lipH)
          ..close();

      case 'phantom_void':
        // Hourglass alchemist vial
        return Path()
          ..moveTo(0, lipH)
          ..cubicTo(w * 0.12, lipH + bodyH * 0.25, w * 0.32, lipH + bodyH * 0.45, w * 0.18, lipH + bodyH * 0.5)
          ..cubicTo(w * 0.32, lipH + bodyH * 0.55, w * 0.12, lipH + bodyH * 0.75, 0, h - r)
          ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r), clockwise: false)
          ..cubicTo(w * 0.88, h - bodyH * 0.25, w * 0.68, h - bodyH * 0.45, w * 0.82, lipH + bodyH * 0.5)
          ..cubicTo(w * 0.68, lipH + bodyH * 0.55, w * 0.88, lipH + bodyH * 0.25, w, lipH)
          ..close();

      case 'sakura':
        // Elegant teardrop vase
        return Path()
          ..moveTo(w * 0.22, lipH)
          ..lineTo(w * 0.22, lipH + bodyH * 0.25)
          ..cubicTo(-w * 0.15, lipH + bodyH * 0.5, -w * 0.1, h, w * 0.5, h)
          ..cubicTo(w + w * 0.1, h, w + w * 0.15, lipH + bodyH * 0.5, w * 0.78, lipH + bodyH * 0.25)
          ..lineTo(w * 0.78, lipH)
          ..close();

      case 'coral_reef':
        // Wavy organic kelp tube
        final path = Path()..moveTo(0, lipH);
        const waveCount = 3;
        final step = (h - lipH - r) / waveCount;
        for (int i = 0; i < waveCount; i++) {
          final y1 = lipH + i * step;
          final y2 = y1 + step;
          path.quadraticBezierTo(-w * 0.10, (y1 + y2) / 2, 0, y2);
        }
        path.arcToPoint(Offset(w, h - r), radius: Radius.circular(r), clockwise: false);
        for (int i = waveCount - 1; i >= 0; i--) {
          final y2 = lipH + i * step;
          final y1 = y2 + step;
          path.quadraticBezierTo(w + w * 0.10, (y1 + y2) / 2, w, y2);
        }
        return path..close();

      case 'dragon_fire':
        // Jagged spiked scale edges
        return Path()
          ..moveTo(w * 0.12, lipH)
          ..lineTo(0, lipH + bodyH * 0.25)
          ..lineTo(w * 0.15, lipH + bodyH * 0.25)
          ..lineTo(0, lipH + bodyH * 0.55)
          ..lineTo(w * 0.15, lipH + bodyH * 0.55)
          ..lineTo(0, h - r)
          ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r), clockwise: false)
          ..lineTo(w - w * 0.15, h - r)
          ..lineTo(w, lipH + bodyH * 0.55)
          ..lineTo(w - w * 0.15, lipH + bodyH * 0.55)
          ..lineTo(w, lipH + bodyH * 0.25)
          ..lineTo(w - w * 0.12, lipH)
          ..close();

      case 'aurora':
        // Curvy aurora twist
        return Path()
          ..moveTo(0, lipH)
          ..quadraticBezierTo(-w * 0.08, lipH + bodyH * 0.3, w * 0.1, lipH + bodyH * 0.5)
          ..quadraticBezierTo(w * 0.28, lipH + bodyH * 0.7, 0, h - r)
          ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r), clockwise: false)
          ..quadraticBezierTo(w * 0.72, h - bodyH * 0.3, w * 0.9, lipH + bodyH * 0.5)
          ..quadraticBezierTo(w + w * 0.08, lipH + bodyH * 0.3, w, lipH)
          ..close();

      case 'obsidian_edge':
        // Obsidian shard flask
        return Path()
          ..moveTo(w * 0.28, lipH)
          ..lineTo(w * 0.28, lipH + bodyH * 0.22)
          ..lineTo(0, h - 8)
          ..lineTo(8, h)
          ..lineTo(w - 8, h)
          ..lineTo(w, h - 8)
          ..lineTo(w * 0.72, lipH + bodyH * 0.22)
          ..lineTo(w * 0.72, lipH)
          ..close();

      case 'celestial':
        // Double bubble flask
        return Path()
          ..moveTo(w * 0.25, lipH)
          ..lineTo(w * 0.25, lipH + bodyH * 0.1)
          ..cubicTo(-w * 0.15, lipH + bodyH * 0.2, -w * 0.15, lipH + bodyH * 0.4, w * 0.25, lipH + bodyH * 0.5)
          ..lineTo(w * 0.25, lipH + bodyH * 0.55)
          ..cubicTo(-w * 0.25, lipH + bodyH * 0.7, -w * 0.2, h, w * 0.5, h)
          ..cubicTo(w + w * 0.2, h, w + w * 0.25, lipH + bodyH * 0.7, w * 0.75, lipH + bodyH * 0.55)
          ..lineTo(w * 0.75, lipH + bodyH * 0.5)
          ..cubicTo(w + w * 0.15, lipH + bodyH * 0.4, w + w * 0.15, lipH + bodyH * 0.2, w * 0.75, lipH + bodyH * 0.1)
          ..lineTo(w * 0.75, lipH)
          ..close();

      default:
        // Default U-tube shape
        return Path()
          ..moveTo(0, lipH)
          ..lineTo(0, h - r)
          ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r), clockwise: false)
          ..lineTo(w, lipH)
          ..close();
    }
  }

  static List<double> getTubeTopBounds(String id, double w) {
    switch (id) {
      case 'solar_flare':   return [w * 0.22, w * 0.78];
      case 'sakura':        return [w * 0.22, w * 0.78];
      case 'dragon_fire':   return [w * 0.12, w * 0.88];
      case 'obsidian_edge': return [w * 0.28, w * 0.72];
      case 'celestial':     return [w * 0.25, w * 0.75];
      default:              return [0.0, w];
    }
  }
}
