import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aqua_sort/core/providers/iap_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class IapStatusHud extends ConsumerWidget {
  const IapStatusHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iapState = ref.watch(iapServiceProvider);

    if (!iapState.isPurchasing && !iapState.isQuerying && iapState.errorMessage == null) {
      return const SizedBox.shrink(); // Nothing to show
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iapState.errorMessage != null) ...[
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Purchase Error',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    iapState.errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(iapServiceProvider.notifier).errorMessage = null;
                      ref.read(iapServiceProvider.notifier).notifyListeners();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    iapState.isQuerying ? 'Loading Store...' : 'Processing Purchase...',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait and do not close the app.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
