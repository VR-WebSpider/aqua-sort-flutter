import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';

/// Cyan-glowing pill button matching the Aqua-Cyber design.
class GlowButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final IconData? icon;

  const GlowButton({super.key, required this.label, required this.onTap,
      this.outlined = false, this.icon});

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 90));
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.95).animate(_ctrl);

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp:   (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: ()=> _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: widget.outlined
                ? null
                : const LinearGradient(colors: [Color(0xFF006E7F), AppColors.tealAccent]),
            border: widget.outlined
                ? Border.all(color: AppColors.tealAccent, width: 1.5) : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanGlow.withOpacity(widget.outlined ? 0.25 : 0.45),
                blurRadius: 18, spreadRadius: 1, offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(widget.label,
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: Colors.white, letterSpacing: 0.6)),
          ]),
        ),
      ),
    );
  }
}

/// Shared dark underwater background gradient.
Widget aquaBackground({Widget? child}) => Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF030D1A), Color(0xFF051C2E), Color(0xFF0A2535), Color(0xFF041520)],
      stops: [0.0, 0.3, 0.62, 1.0],
    ),
  ),
  child: child,
);

/// WebSpider Studios top-bar header used on auth sub-screens.
class AquaHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onHome;
  const AquaHeader({super.key, this.onBack, this.onHome});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (onBack != null)
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 44, height: 44,
            color: Colors.transparent, // Ensures the entire area is hittable
            child: Center(
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.tealAccent.withOpacity(0.5)),
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      const Spacer(),
      if (onHome != null)
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: onHome,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.tealAccent.withOpacity(0.5)),
                color: Colors.white.withOpacity(0.05),
              ),
              child: const Icon(Icons.home_outlined, size: 16, color: Colors.white),
            ),
          ),
        ),
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cyanGlow.withOpacity(0.5)),
          color: AppColors.deepNavy,
        ),
        child: const Icon(Icons.hub_outlined, size: 15, color: AppColors.cyanGlow),
      ),
      const SizedBox(width: 7),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('WebSpider', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
        Text('Studios',  style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    ]);
  }
}

/// Styled input field matching the dark Aqua-Cyber form design.
class AquaField extends StatelessWidget {
  final String label;
  final String hint;
  final bool required;
  final bool obscure;
  final bool lockIcon;
  final Widget? suffix;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AquaField({super.key,
    required this.label, required this.hint,
    this.required = true, this.obscure = false,
    this.lockIcon = false, this.suffix,
    this.controller, this.keyboardType = TextInputType.text,
    this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: GoogleFonts.outfit(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        if (required) Text(' *', style: const TextStyle(color: AppColors.cyanGlow, fontSize: 12)),
        const Spacer(),
        if (lockIcon) const Icon(Icons.lock_outline, size: 13, color: AppColors.tealMid),
      ]),
      const SizedBox(height: 5),
      Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            border: InputBorder.none,
            suffixIcon: suffix,
          ),
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }
}
