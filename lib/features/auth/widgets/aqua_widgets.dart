import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:aqua_sort/core/theme/app_colors.dart';
import 'package:aqua_sort/features/profile/providers/settings_provider.dart';

/// Cyan-glowing pill button matching the Aqua-Cyber design.
class GlowButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final IconData? icon;
  final bool loading;
  final Color? glowColor;
  final List<Color>? gradientColors;

  const GlowButton({super.key, required this.label, required this.onTap,
      this.outlined = false, this.icon, this.loading = false,
      this.glowColor, this.gradientColors});

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
      onTapDown: (_) => widget.loading ? null : _ctrl.forward(),
      onTapUp:   (_) { 
        if (!widget.loading) {
          _ctrl.reverse(); 
          widget.onTap(); 
        }
      },
      onTapCancel: ()=> _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Opacity(
          opacity: widget.loading ? 0.8 : 1.0,
          child: Container(
            width: double.infinity, height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: widget.outlined
                  ? null
                  : LinearGradient(colors: widget.gradientColors ?? const [Color(0xFF006E7F), AppColors.tealAccent]),
              border: widget.outlined
                  ? Border.all(color: widget.glowColor ?? AppColors.tealAccent, width: 1.5) : null,
              boxShadow: [
                BoxShadow(
                  color: (widget.glowColor ?? AppColors.cyanGlow).withOpacity(widget.outlined ? 0.25 : 0.45),
                  blurRadius: 18, spreadRadius: 1, offset: const Offset(0, 3),
                )
              ],
            ),
            child: widget.loading 
              ? const Center(child: SizedBox(
                  width: 20, height: 20, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
class AquaHeader extends ConsumerWidget {
  final VoidCallback? onBack;
  final VoidCallback? onHome;
  const AquaHeader({super.key, this.onBack, this.onHome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(children: [
      if (onBack != null) ...[
        GestureDetector(
          onTap: onHome ?? () => context.go('/'),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: Colors.black26,
              border: Border.all(color: Colors.white12)
            ),
            child: const Icon(Icons.home_outlined, size: 16, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: AppColors.cyanGlow.withOpacity(0.1),
              border: Border.all(color: AppColors.cyanGlow.withOpacity(0.3))
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.white),
          ),
        ),
      ],
      const Spacer(),
      // Volume/Music Toggle Button
      const VolumeControlWidget(),
      const SizedBox(width: 12),
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cyanGlow.withOpacity(0.5)),
          color: AppColors.deepNavy,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset('assets/studio_logo_white.png', color: AppColors.cyanGlow),
        ),
      ),
      const SizedBox(width: 7),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('WebSpider', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
        Text('Studios',  style: GoogleFonts.outfit(fontSize: 10, color: AppColors.tealAccent.withOpacity(0.8))),
      ]),
    ]);
  }
}

class VolumeControlWidget extends ConsumerStatefulWidget {
  const VolumeControlWidget({super.key});

  @override
  ConsumerState<VolumeControlWidget> createState() => _VolumeControlWidgetState();
}

class _VolumeControlWidgetState extends ConsumerState<VolumeControlWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: 0.0, end: 110.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startCollapseTimer() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  void _handleTap() {
    if (_controller.isCompleted) {
      ref.read(settingsProvider.notifier).toggleMasterMute();
      _startCollapseTimer();
    } else {
      _controller.forward();
      _startCollapseTimer();
    }
  }

  IconData _getIcon(UserSettings settings) {
    if (settings.isMuted) {
      return Icons.volume_off_rounded;
    }
    if (settings.musicVolume == 0.0) {
      return Icons.volume_mute_rounded;
    }
    if (settings.musicVolume < 0.5) {
      return Icons.volume_down_rounded;
    }
    return Icons.volume_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _widthAnimation,
          builder: (context, child) {
            return Container(
              width: _widthAnimation.value,
              height: 36,
              child: ClipRect(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: 110,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: AppColors.cyanGlow,
                        inactiveTrackColor: Colors.white12,
                        thumbColor: AppColors.cyanGlow,
                        overlayColor: AppColors.cyanGlow.withOpacity(0.12),
                      ),
                      child: Slider(
                        value: settings.isMuted ? 0.0 : settings.musicVolume,
                        min: 0.0,
                        max: 1.0,
                        onChangeStart: (val) {
                          _collapseTimer?.cancel();
                        },
                        onChangeEnd: (val) {
                          _startCollapseTimer();
                        },
                        onChanged: (val) {
                          if (settings.isMuted) {
                            ref.read(settingsProvider.notifier).toggleMasterMute();
                          }
                          ref.read(settingsProvider.notifier).setMusicVolume(val);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        GestureDetector(
          onTap: _handleTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black26,
              border: Border.all(
                color: !settings.isMuted && settings.musicEnabled
                    ? AppColors.cyanGlow.withOpacity(0.4)
                    : Colors.white12,
              ),
            ),
            child: Icon(
              _getIcon(settings),
              size: 16,
              color: !settings.isMuted && settings.musicEnabled ? AppColors.cyanGlow : Colors.white54,
            ),
          ),
        ),
      ],
    );
  }
}

/// Styled input field matching the dark Aqua-Cyber form design.
class AquaField extends StatefulWidget {
  final String label;
  final String hint;
  final bool required;
  final bool obscure;
  final bool lockIcon;
  final Widget? suffix;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const AquaField({super.key,
    required this.label, required this.hint,
    this.required = true, this.obscure = false,
    this.lockIcon = false, this.suffix,
    this.controller, this.keyboardType = TextInputType.text,
    this.validator,
    this.enabled = true,
    this.onChanged});

  @override
  State<AquaField> createState() => _AquaFieldState();
}

class _AquaFieldState extends State<AquaField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(widget.label, style: GoogleFonts.outfit(
            fontSize: 12, fontWeight: FontWeight.w600, 
            color: widget.enabled ? AppColors.textSecondary : AppColors.textSecondary.withOpacity(0.3))),
        if (widget.required) Text(' *', style: TextStyle(color: widget.enabled ? AppColors.cyanGlow : AppColors.cyanGlow.withOpacity(0.3), fontSize: 12)),
        const Spacer(),
        if (widget.lockIcon) Icon(Icons.lock_outline, size: 13, color: widget.enabled ? AppColors.tealMid : AppColors.tealMid.withOpacity(0.3)),
      ]),
      const SizedBox(height: 5),
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 46,
        decoration: BoxDecoration(
          color: widget.enabled ? AppColors.inputBg : AppColors.inputBg.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.enabled ? AppColors.inputBorder : AppColors.inputBorder.withOpacity(0.2)),
          boxShadow: widget.enabled ? [] : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style: GoogleFonts.outfit(
            color: widget.enabled ? Colors.white : Colors.white24, 
            fontSize: 14
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.outfit(color: widget.enabled ? AppColors.textMuted : AppColors.textMuted.withOpacity(0.2), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            border: InputBorder.none,
            suffixIcon: widget.obscure 
              ? IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
                      size: 16, color: widget.enabled ? Colors.white54 : Colors.white12),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : widget.suffix,
          ),
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }
}
