import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';
import 'package:aqua_sort/features/profile/models/skin_catalogue.dart';
import 'package:aqua_sort/features/profile/providers/skin_provider.dart';
import 'package:go_router/go_router.dart';

class PurityExchangeScreen extends ConsumerStatefulWidget {
  const PurityExchangeScreen({super.key});

  @override
  ConsumerState<PurityExchangeScreen> createState() =>
      _PurityExchangeScreenState();
}

class _PurityExchangeScreenState extends ConsumerState<PurityExchangeScreen>
    with SingleTickerProviderStateMixin {
  SkinTier? _filterTier; // null = All
  late final TabController _tabCtrl =
      TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<TubeSkin> get _filteredSkins {
    if (_filterTier == null) return SkinCatalogue.all;
    return SkinCatalogue.byTier(_filterTier!);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(levelProvider);
    final goldCoins = progress.spiderGoldCoins;

    return Scaffold(
      backgroundColor: const Color(0xFF030D1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PURITY EXCHANGE',
                          style: GoogleFonts.righteous(
                            fontSize: 22,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Spend coins. Unlock power.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gold coin balance
                  _CoinBadge(amount: goldCoins),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Filter tabs ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FilterTabs(
                selected: _filterTier,
                onSelect: (tier) => setState(() => _filterTier = tier),
              ),
            ),

            const SizedBox(height: 16),

            // ── Daily Resonance Boost banner ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _DailyBoostBanner(streak: progress.dailyStreakCount),
            ),

            const SizedBox(height: 16),

            // ── Skins grid ────────────────────────────────────────────────
            Expanded(
              child: _SkinsGrid(
                skins: _filteredSkins,
                filterTier: _filterTier,
                ownedIds: progress.ownedSkinIds,
                activeSkinId: progress.activeSkinId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coin Badge ─────────────────────────────────────────────────────────────────
class _CoinBadge extends StatelessWidget {
  final int amount;
  const _CoinBadge({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2500),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hexagon_rounded, color: Color(0xFFFFD700), size: 16),
          const SizedBox(width: 5),
          Text(
            '$amount',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Tabs ────────────────────────────────────────────────────────────────
class _FilterTabs extends StatelessWidget {
  final SkinTier? selected;
  final void Function(SkinTier?) onSelect;

  const _FilterTabs({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            active: selected == null,
            color: AppColors.tealAccent,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Standard',
            active: selected == SkinTier.standard,
            color: SkinTier.standard.color,
            onTap: () => onSelect(SkinTier.standard),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Premium',
            active: selected == SkinTier.premium,
            color: SkinTier.premium.color,
            onTap: () => onSelect(SkinTier.premium),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Legendary',
            active: selected == SkinTier.legendary,
            color: SkinTier.legendary.color,
            onTap: () => onSelect(SkinTier.legendary),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.18) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? color.withOpacity(0.7) : Colors.white12,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? color : Colors.white54,
          ),
        ),
      ),
    );
  }
}

// ── Daily Boost Banner ─────────────────────────────────────────────────────────
class _DailyBoostBanner extends StatelessWidget {
  final int streak;
  const _DailyBoostBanner({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2A1F00),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🎁', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Resonance Boost',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Current Streak: ${streak > 0 ? '$streak ${streak == 1 ? 'day' : 'days'}' : 'Start today!'}',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.tealAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tealAccent.withOpacity(0.5)),
              ),
              child: Text(
                'VIEW',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tealAccent,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skins Grid ─────────────────────────────────────────────────────────────────
class _SkinsGrid extends StatelessWidget {
  final List<TubeSkin> skins;
  final SkinTier? filterTier;
  final Set<String> ownedIds;
  final String activeSkinId;

  const _SkinsGrid({
    required this.skins,
    required this.filterTier,
    required this.ownedIds,
    required this.activeSkinId,
  });

  @override
  Widget build(BuildContext context) {
    // Group skins by tier for section headers
    final groups = <SkinTier, List<TubeSkin>>{};
    for (final skin in skins) {
      groups.putIfAbsent(skin.tier, () => []).add(skin);
    }

    final tierOrder = [SkinTier.standard, SkinTier.premium, SkinTier.legendary];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        for (final tier in tierOrder)
          if (groups.containsKey(tier)) ...[
            // Section header
            if (filterTier == null) ...[
              const SizedBox(height: 8),
              _SectionHeader(tier: tier),
              const SizedBox(height: 12),
            ],
            // Grid of 2 columns
            _buildGrid(context, groups[tier]!),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildGrid(BuildContext context, List<TubeSkin> tierSkins) {
    final rows = <Widget>[];
    for (int i = 0; i < tierSkins.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(
            child: _SkinCard(
              skin: tierSkins[i],
              isOwned: ownedIds.contains(tierSkins[i].id),
              isActive: activeSkinId == tierSkins[i].id,
            ),
          ),
          const SizedBox(width: 12),
          if (i + 1 < tierSkins.length)
            Expanded(
              child: _SkinCard(
                skin: tierSkins[i + 1],
                isOwned: ownedIds.contains(tierSkins[i + 1].id),
                isActive: activeSkinId == tierSkins[i + 1].id,
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ));
      rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

class _SectionHeader extends StatelessWidget {
  final SkinTier tier;
  const _SectionHeader({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: tier.bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tier.color.withOpacity(0.4)),
          ),
          child: Text(
            tier.label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: tier.color,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: tier.color.withOpacity(0.15), thickness: 1)),
      ],
    );
  }
}

// ── Skin Card ──────────────────────────────────────────────────────────────────
class _SkinCard extends StatelessWidget {
  final TubeSkin skin;
  final bool isOwned;
  final bool isActive;

  const _SkinCard({
    required this.skin,
    required this.isOwned,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/skin-detail', extra: skin),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: skin.tier.bgColor.withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? skin.glowColor.withOpacity(0.8)
                : skin.tier.color.withOpacity(0.2),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: skin.glowColor.withOpacity(0.2),
                    blurRadius: 14,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            // Tier badge
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: skin.tier.bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: skin.tier.color.withOpacity(0.4)),
                ),
                child: Text(
                  skin.tier.label,
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: skin.tier.color,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Tube preview
            MiniTubePreview(skin: skin, height: 90, width: 38),
            const SizedBox(height: 10),
            // Name
            Text(
              skin.name,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Price or Owned/Active badge
            if (isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.tealAccent.withOpacity(0.4)),
                ),
                child: Text(
                  '✓ EQUIPPED',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tealAccent,
                  ),
                ),
              )
            else if (isOwned)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  'OWNED',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38,
                  ),
                ),
              )
            else if (skin.price == 0)
              const SizedBox.shrink()
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A00),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hexagon_rounded,
                        color: Color(0xFFFFD700), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${skin.price}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Standalone screen wrapper — also exported as CustomizationScreen for the router
class CustomizationScreen extends StatelessWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) => const PurityExchangeScreen();
}
