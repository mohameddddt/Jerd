import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Line icons taken verbatim from the design files (24×24 viewBox).
abstract final class AppIcons {
  static const close = '<path d="M6 6l12 12M18 6L6 18"/>';
  static const back = '<path d="M15 5l-7 7 7 7"/>';
  static const chevronRight = '<path d="M9 5l7 7-7 7"/>';
  static const chevronDown = '<path d="M6 9l6 6 6-6"/>';
  static const plus = '<path d="M12 5v14M5 12h14"/>';
  static const minus = '<path d="M5 12h14"/>';
  static const check = '<path d="M5 12.5l4.5 4.5L19 7"/>';
  static const edit = '<path d="M4 20h4L19 9l-4-4L4 16z"/>';
  static const more =
      '<circle cx="12" cy="5" r="1.8" fill="#000" stroke="none"/><circle cx="12" cy="12" r="1.8" fill="#000" stroke="none"/><circle cx="12" cy="19" r="1.8" fill="#000" stroke="none"/>';
  static const mail =
      '<rect x="3.5" y="5.5" width="17" height="13" rx="2"/><path d="M4 7l8 6 8-6"/>';
  static const lock =
      '<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>';
  static const eye =
      '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/>';
  static const eyeOff =
      '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/><path d="M4 4l16 16"/>';
  static const offline =
      '<path d="M3 3l18 18"/><path d="M8 7.5A5.5 5.5 0 0 1 17.5 10H18a3.5 3.5 0 0 1 2.2 6.2M17 18H7a4 4 0 0 1-1.6-7.7"/>';
  static const search =
      '<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>';
  static const scan =
      '<path d="M4 7V5a1 1 0 0 1 1-1h2M17 4h2a1 1 0 0 1 1 1v2M20 17v2a1 1 0 0 1-1 1h-2M7 20H5a1 1 0 0 1-1-1v-2M8 8v8M10.5 8v8M13.5 8v8M16 8v8"/>';
  static const box =
      '<path d="M3.5 7.5L12 3l8.5 4.5v9L12 21l-8.5-4.5z"/><path d="M3.5 7.5L12 12l8.5-4.5M12 12v9"/>';
  static const clipboard =
      '<rect x="5" y="4.5" width="14" height="16.5" rx="2"/><path d="M9 3h6v3H9z"/><path d="M9 13.5l2 2 4-4"/>';
  static const bell =
      '<path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z"/><path d="M10 20a2 2 0 0 0 4 0"/>';
  static const sync =
      '<path d="M20 11a8 8 0 0 0-14.5-4.5L4 8"/><path d="M4 3v5h5"/><path d="M4 13a8 8 0 0 0 14.5 4.5L20 16"/><path d="M20 21v-5h-5"/>';
  static const sliders =
      '<path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="17" r="2"/>';
  static const flash = '<path d="M13 3L5 14h6l-1 7 8-11h-6z"/>';
  static const hash = '<path d="M5 9h15M4 15h15M10 4l-2 16M16 4l-2 16"/>';
  static const image =
      '<rect x="3.5" y="4.5" width="17" height="15" rx="2"/><circle cx="9" cy="10" r="1.8"/><path d="M20.5 16l-5-5L6 19.5"/>';
  static const camera =
      '<path d="M4 8h3l2-3h6l2 3h3v11H4z"/><circle cx="12" cy="13" r="3.5"/>';
  static const warning = '<path d="M12 4L2.5 20h19z"/><path d="M12 10v4M12 17.5v.5"/>';
  static const trash =
      '<path d="M4 7h16M9 7V4.5h6V7M6.5 7l1 13h9l1-13"/>';
  static const arrowRight = '<path d="M5 12h14M13 6l6 6-6 6"/>';
  static const clock =
      '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>';
  static const globe =
      '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.5 3.5 5.5 3.5 8.5s-1 6-3.5 8.5c-2.5-2.5-3.5-5.5-3.5-8.5s1-6 3.5-8.5z"/>';
  static const moon = '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/>';
  static const users =
      '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 4.8a3.5 3.5 0 0 1 0 6.4M18 14.5a6.5 6.5 0 0 1 3.5 5.5"/>';
  static const signOut =
      '<path d="M14 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4"/><path d="M10 16l-4-4 4-4M6 12h10"/>';
}

class AppIcon extends StatelessWidget {
  final String icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  /// Flip horizontally in right-to-left layouts (arrows, chevrons).
  final bool mirrorInRtl;

  const AppIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2,
    this.mirrorInRtl = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Colors.black;
    final picture = SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#000" stroke-width="$strokeWidth" stroke-linecap="round" '
      'stroke-linejoin="round">$icon</svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
    );
    if (mirrorInRtl && Directionality.of(context) == TextDirection.rtl) {
      return Transform.flip(flipX: true, child: picture);
    }
    return picture;
  }
}
