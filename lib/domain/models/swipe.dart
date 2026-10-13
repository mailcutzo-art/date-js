enum SwipeAction { pass, like, superLike }

class SwipeOutcome {
  const SwipeOutcome({required this.matched, this.limitReached = false});

  final bool matched;

  /// A free account ran out of daily super likes.
  final bool limitReached;
}
