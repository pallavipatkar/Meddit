import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/time_formatter.dart';

class VoteControl extends StatelessWidget {
  final int score;
  final int userVote; // 1 = upvoted, -1 = downvoted, 0 = none
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final bool compact;

  const VoteControl({
    super.key,
    required this.score,
    required this.userVote,
    required this.onUpvote,
    required this.onDownvote,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant;

    Color capsuleBg = defaultBg;
    Color textColor = Theme.of(context).colorScheme.onSurface;

    if (userVote == 1) {
      capsuleBg = isDark
          ? AppColors.upvoteOrange.withValues(alpha: 0.22)
          : AppColors.upvoteOrangeLight;
      textColor = AppColors.upvoteOrange;
    } else if (userVote == -1) {
      capsuleBg = isDark
          ? AppColors.darkPrimaryAccent.withValues(alpha: 0.22)
          : AppColors.downvoteBlueLight;
      textColor =
          isDark ? AppColors.darkPrimaryAccent : AppColors.downvoteBlue;
    }

    final iconSize = compact ? 17.0 : 19.0;
    final horizontalPad = compact ? 7.0 : 9.0;
    final verticalPad = compact ? 4.0 : 6.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: capsuleBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: userVote == 0
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.6)
              : textColor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: userVote == 1 ? 'Remove upvote' : 'Upvote',
            child: InkWell(
              onTap: onUpvote,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(24),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPad,
                  vertical: verticalPad,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: iconSize,
                  color: userVote == 1
                      ? AppColors.upvoteOrange
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              TimeFormatter.compactCount(score),
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          Tooltip(
            message: userVote == -1 ? 'Remove downvote' : 'Downvote',
            child: InkWell(
              onTap: onDownvote,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(24),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPad,
                  vertical: verticalPad,
                ),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: iconSize,
                  color: userVote == -1
                      ? (isDark
                          ? AppColors.darkPrimaryAccent
                          : AppColors.downvoteBlue)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
