import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MedditLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool lightOnDark;

  const MedditLogo({
    super.key,
    this.size = 56,
    this.showText = true,
    this.lightOnDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeBg = lightOnDark
        ? Colors.white
        : (isDark ? AppColors.darkPrimaryAccent : AppColors.primaryNavy);
    final iconColor = lightOnDark
        ? AppColors.primaryNavy
        : (isDark ? AppColors.darkBackground : Colors.white);
    final titleColor = lightOnDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryNavy.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.forum_rounded,
                size: size * 0.56,
                color: iconColor.withValues(alpha: 0.22),
              ),
              Text(
                'M',
                style: TextStyle(
                  color: iconColor,
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Meddit',
                style: TextStyle(
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: titleColor,
                ),
              ),
              Text(
                'MITS GWALIOR',
                style: TextStyle(
                  fontSize: size * 0.19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: lightOnDark
                      ? Colors.white.withValues(alpha: 0.8)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
