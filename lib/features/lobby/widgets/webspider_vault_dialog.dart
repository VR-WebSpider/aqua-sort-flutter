import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/lobby/providers/level_provider.dart';

class CoinMeta {
  final String key;
  final String name;
  final String rarity;
  final Color color;
  final String description;
  final String assetPath;
  final String emoji;

  CoinMeta({
    required this.key,
    required this.name,
    required this.rarity,
    required this.color,
    required this.description,
    required this.assetPath,
    required this.emoji,
  });
}

class WebSpiderVaultDialog extends ConsumerStatefulWidget {
  const WebSpiderVaultDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'WebSpiderVault',
      barrierColor: Colors.black.withOpacity(0.85),
      pageBuilder: (context, _, __) => const WebSpiderVaultDialog(),
    );
  }

  @override
  ConsumerState<WebSpiderVaultDialog> createState() => _WebSpiderVaultDialogState();
}

class _WebSpiderVaultDialogState extends ConsumerState<WebSpiderVaultDialog> {
  final List<CoinMeta> _coins = [
    CoinMeta(
      key: 'copper',
      name: 'Copper Coin',
      rarity: 'COMMON',
      color: Colors.deepOrangeAccent,
      description: 'Used for standard level continues and basic cosmetics.',
      assetPath: 'assets/webspider_coins/CopperCoin.png',
      emoji: '🕸🟫',
    ),
    CoinMeta(
      key: 'brass',
      name: 'Brass Coin',
      rarity: 'COMMON',
      color: Colors.orange,
      description: 'Used for hints, undos, and gameplay modifiers.',
      assetPath: 'assets/webspider_coins/BrassCoin.png',
      emoji: '🕸🟨',
    ),
    CoinMeta(
      key: 'silver',
      name: 'Silver Coin',
      rarity: 'UNCOMMON',
      color: Colors.grey,
      description: 'Used for premium undos and standard cosmetics.',
      assetPath: 'assets/webspider_coins/SilverCoin.png',
      emoji: '🕸🥈',
    ),
    CoinMeta(
      key: 'gold',
      name: 'Gold Coin',
      rarity: 'RARE',
      color: Colors.amber,
      description: 'Used for game pause gates, revives, and premium skins.',
      assetPath: 'assets/webspider_coins/GoldCoin.png',
      emoji: '🕸🥇',
    ),
    CoinMeta(
      key: 'diamond',
      name: 'Diamond Coin',
      rarity: 'PREMIUM',
      color: Colors.pinkAccent,
      description: 'Used for season passes, VIP cosmetics, and cross-game unlocks.',
      assetPath: 'assets/webspider_coins/DiamondCoin.png',
      emoji: '🕸💎',
    ),
    CoinMeta(
      key: 'jade',
      name: 'Jade Coin',
      rarity: 'EVENT',
      color: Colors.greenAccent,
      description: 'Earned and spent in seasonal limited-time guild tournaments.',
      assetPath: 'assets/webspider_coins/JadeCoin.png',
      emoji: '🕸🟢',
    ),
    CoinMeta(
      key: 'obsidian',
      name: 'Obsidian Coin',
      rarity: 'ELITE',
      color: Colors.purpleAccent,
      description: 'Acquired only by completing extreme challenges. Unlocks master skins.',
      assetPath: 'assets/webspider_coins/ObsidianCoin.png',
      emoji: '🕸🖤',
    ),
  ];

  String _swapFrom = 'coins'; // Default source is regular coins
  String _swapTo = 'copper';   // Default target is copper
  final TextEditingController _amountController = TextEditingController();
  
  bool _swapping = false;
  String? _statusMessage;
  bool _statusSuccess = true;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Swap rates logic
  int _calculateToAmount(int fromAmount) {
    if (fromAmount <= 0) return 0;

    // Coins -> Copper: 5 -> 1
    if (_swapFrom == 'coins' && _swapTo == 'copper') return fromAmount ~/ 5;
    // Copper -> Brass: 10 -> 1
    if (_swapFrom == 'copper' && _swapTo == 'brass') return fromAmount ~/ 10;
    // Brass -> Silver: 5 -> 1
    if (_swapFrom == 'brass' && _swapTo == 'silver') return fromAmount ~/ 5;
    // Silver -> Gold: 5 -> 1
    if (_swapFrom == 'silver' && _swapTo == 'gold') return fromAmount ~/ 5;
    // Gold -> Diamond: 5 -> 1
    if (_swapFrom == 'gold' && _swapTo == 'diamond') return fromAmount ~/ 5;

    return 0; // Invalid swap direction
  }

  bool _isValidSwapPair() {
    if (_swapFrom == 'coins' && _swapTo == 'copper') return true;
    if (_swapFrom == 'copper' && _swapTo == 'brass') return true;
    if (_swapFrom == 'brass' && _swapTo == 'silver') return true;
    if (_swapFrom == 'silver' && _swapTo == 'gold') return true;
    if (_swapFrom == 'gold' && _swapTo == 'diamond') return true;
    return false;
  }

  String _getSwapRateText() {
    if (_swapFrom == 'coins' && _swapTo == 'copper') return 'Exchange Rate: 5 Coins 🪙 = 1 Copper 🕸🟫';
    if (_swapFrom == 'copper' && _swapTo == 'brass') return 'Exchange Rate: 10 Copper 🕸🟫 = 1 Brass 🕸🟨';
    if (_swapFrom == 'brass' && _swapTo == 'silver') return 'Exchange Rate: 5 Brass 🕸🟨 = 1 Silver 🕸🥈';
    if (_swapFrom == 'silver' && _swapTo == 'gold') return 'Exchange Rate: 5 Silver 🕸🥈 = 1 Gold 🕸🥇';
    if (_swapFrom == 'gold' && _swapTo == 'diamond') return 'Exchange Rate: 5 Gold 🕸🥇 = 1 Diamond 🕸💎';
    return 'Swap unavailable for this selection.';
  }

  Future<void> _performSwap() async {
    final fromAmount = int.tryParse(_amountController.text) ?? 0;
    if (fromAmount <= 0) {
      setState(() {
        _statusMessage = 'Enter a valid amount.';
        _statusSuccess = false;
      });
      return;
    }

    final toAmount = _calculateToAmount(fromAmount);
    if (toAmount <= 0) {
      setState(() {
        _statusMessage = 'Insufficient source amount for exchange.';
        _statusSuccess = false;
      });
      return;
    }

    setState(() {
      _swapping = true;
      _statusMessage = null;
    });

    final success = await ref.read(levelProvider.notifier).exchangeCurrency(
      fromType: _swapFrom,
      toType: _swapTo,
      fromAmount: fromAmount,
      toAmount: toAmount,
    );

    if (mounted) {
      setState(() {
        _swapping = false;
        if (success) {
          _statusMessage = 'Successfully exchanged $fromAmount for $toAmount ${_swapTo.toUpperCase()}!';
          _statusSuccess = true;
          _amountController.clear();
        } else {
          _statusMessage = 'Exchange failed. Insufficient funds or database error.';
          _statusSuccess = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(levelProvider);

    // Map keys to balances in state
    int getBalance(String key) {
      switch (key) {
        case 'brass': return progress.spiderBrassCoins;
        case 'copper': return progress.spiderCopperCoins;
        case 'silver': return progress.spiderSilverCoins;
        case 'gold': return progress.spiderGoldCoins;
        case 'diamond': return progress.spiderDiamondCoins;
        case 'jade': return progress.spiderJadeCoins;
        case 'obsidian': return progress.spiderObsidianCoins;
        default: return 0;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Tap background to close
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.deepNavy.withOpacity(0.96),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.12),
                    blurRadius: 40,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                children: [
                  // Title / Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.vpn_key_rounded, color: Colors.purpleAccent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WEBSPIDER VAULT',
                              style: GoogleFonts.righteous(
                                fontSize: 22,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Universal economy currency system',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Coins List
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Coins Display Grid
                        Text(
                          'YOUR BALANCES',
                          style: GoogleFonts.righteous(
                            color: Colors.purpleAccent,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.35,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _coins.length,
                          itemBuilder: (context, index) {
                            final coin = _coins[index];
                            final balance = getBalance(coin.key);
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    coin.assetPath,
                                    width: 44,
                                    height: 44,
                                    errorBuilder: (_, __, ___) => CircleAvatar(
                                      radius: 22,
                                      backgroundColor: coin.color.withOpacity(0.2),
                                      child: Text(coin.emoji.substring(coin.emoji.length - 2), style: const TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          coin.name,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(vertical: 2),
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: coin.color.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            coin.rarity,
                                            style: GoogleFonts.outfit(
                                              color: coin.color,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$balance',
                                          style: GoogleFonts.righteous(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Coin info/details
                        Text(
                          'CURRENCY DESCRIPTIONS',
                          style: GoogleFonts.righteous(
                            color: Colors.purpleAccent,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._coins.map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(c.emoji, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c.description,
                                      style: GoogleFonts.outfit(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 20),

                        // Exchange section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.withOpacity(0.15),
                                AppColors.deepNavy,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.swap_horizontal_circle_outlined, color: Colors.purpleAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SWAP STATION',
                                    style: GoogleFonts.righteous(
                                      color: Colors.white,
                                      fontSize: 14,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // From / To Dropdowns
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('From', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 10)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.black38,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.white10),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _swapFrom,
                                              dropdownColor: AppColors.deepNavy,
                                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                                              items: const [
                                                DropdownMenuItem(value: 'coins', child: Text('Coins 🪙')),
                                                DropdownMenuItem(value: 'copper', child: Text('Copper 🕸🟫')),
                                                DropdownMenuItem(value: 'brass', child: Text('Brass 🕸🟨')),
                                                DropdownMenuItem(value: 'silver', child: Text('Silver 🕸🥈')),
                                                DropdownMenuItem(value: 'gold', child: Text('Gold 🕸🥇')),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() {
                                                    _swapFrom = val;
                                                    _statusMessage = null;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0, right: 8.0, top: 12),
                                    child: Icon(Icons.arrow_forward_rounded, color: Colors.white30),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('To', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 10)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.black38,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.white10),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _swapTo,
                                              dropdownColor: AppColors.deepNavy,
                                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                                              items: const [
                                                DropdownMenuItem(value: 'copper', child: Text('Copper 🕸🟫')),
                                                DropdownMenuItem(value: 'brass', child: Text('Brass 🕸🟨')),
                                                DropdownMenuItem(value: 'silver', child: Text('Silver 🕸🥈')),
                                                DropdownMenuItem(value: 'gold', child: Text('Gold 🕸🥇')),
                                                DropdownMenuItem(value: 'diamond', child: Text('Diamond 🕸💎')),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() {
                                                    _swapTo = val;
                                                    _statusMessage = null;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Rate Info
                              Text(
                                _getSwapRateText(),
                                style: GoogleFonts.outfit(
                                  color: _isValidSwapPair() ? Colors.tealAccent : Colors.redAccent,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Amount input
                              if (_isValidSwapPair()) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 44,
                                        child: TextField(
                                          controller: _amountController,
                                          keyboardType: TextInputType.number,
                                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                                          decoration: InputDecoration(
                                            hintText: 'Source amount...',
                                            hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
                                            filled: true,
                                            fillColor: Colors.black26,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Colors.white10),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Colors.purpleAccent),
                                            ),
                                          ),
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      height: 44,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purpleAccent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: _swapping ? null : _performSwap,
                                        child: _swapping
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : Text(
                                                'SWAP',
                                                style: GoogleFonts.righteous(color: Colors.white, fontSize: 13),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Preview exchange
                                Builder(
                                  builder: (context) {
                                    final amt = int.tryParse(_amountController.text) ?? 0;
                                    final result = _calculateToAmount(amt);
                                    if (amt <= 0 || result <= 0) return const SizedBox.shrink();
                                    return Text(
                                      'You will receive: $result ${_swapTo.toUpperCase()}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    );
                                  },
                                ),
                              ],

                              if (_statusMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _statusMessage!,
                                  style: GoogleFonts.outfit(
                                    color: _statusSuccess ? Colors.tealAccent : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
