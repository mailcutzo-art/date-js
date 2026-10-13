# Animations and motion

All built with Flutter's own animation APIs; no animation packages and no Lottie. Every looping or
decorative animation stops when the system "remove animations" setting is on.

| Where | What | Timing | Implementation |
|---|---|---|---|
| Splash | Logo pops in, tagline fades up | 900 ms, `easeOutBack` then `easeOut` | `AnimationController`, `ScaleTransition`, `SlideTransition` |
| Welcome | Three tilted cards drift out of phase | 7 s loop, `easeInOut` | repeating controller; rests under reduced motion |
| Swipe deck | Card follows finger, tilts up to 0.35 rad | live | `GestureDetector` pan, `Transform` |
| Swipe deck | Commit past 30 % width, 20 % height (up) or 800 px/s fling; fly-off | 260 ms, `easeOutCubic` | unbounded controller, `animateTo` |
| Swipe deck | Spring back when released short | stiffness 300, damping 22 | `SpringSimulation` |
| Swipe deck | Cards behind scale and rise as the top leaves | tied to drag distance | computed from `_drag` |
| Swipe deck | LIKE / NOPE / SUPER LIKE stamps fade in | tied to drag distance | `Opacity` |
| Swipe deck | Haptic tick at the commit threshold, success/light on release | - | `SynkHapticsScope` |
| Action bar | Buttons shrink to 0.88 while pressed | 90 ms | `AnimatedScale` |
| Match overlay | Avatars slide together and tilt, heart pops, confetti, buttons fade | 1.4 s, `easeOutBack` / `elasticOut` | one controller with `Interval`s, design-system `Confetti` |
| OTP | Boxes shake on a wrong code | 380 ms, damped sine | controller + `Transform.translate` |
| Setup | Steps slide, progress bar fills | 260 ms `smooth` / 300 ms | `PageController`, `TweenAnimationBuilder` |
| Verification | Ring sweeps while scanning, turns green with a tick | 2.2 s | `CustomPainter` |
| Chat | Typing dots bounce in sequence | 1.1 s loop | controller; rests under reduced motion |
| Chat | Recording dot pulses | 0.8 s loop | controller; rests under reduced motion |
| Chat | Voice note waveform fills while playing | note length | controller |
| Nav bar | Selected pill grows and recolours | 200 ms `fastOutSlowIn` | `AnimatedContainer` |
| Premium | Hero gradient glides, crown pulses | 4 s loop | controller; rests under reduced motion |
| Routes | Pushed screens slide in, stages cross-fade, paywall rises | 260 / 220 ms / 260 ms | `CustomTransitionPage` (`transitions.dart`) |

The tuning numbers for the deck are constants on `SwipeDeck` (`commitFraction`, `flingVelocity`,
`maxTilt`, `flyDuration`, `spring`) and are covered by gesture tests.
