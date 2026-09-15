import 'dart:io';
import 'package:flutter/material.dart';
import '../../logic/domain/low_stock.dart';
import '../themes/app_palette.dart';
import '../themes/status_colors_extensions.dart';
import 'app_icon.dart';

export '../../logic/domain/low_stock.dart' show StockLevel, stockLevel;

const tabularFigures = [FontFeature.tabularFigures()];

/// A rounded, optionally bordered surface with an ink ripple.
class Tappable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final BorderSide border;
  final List<BoxShadow>? shadow;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  const Tappable({
    super.key,
    required this.child,
    this.onTap,
    this.color = Colors.transparent,
    this.radius = 20,
    this.border = BorderSide.none,
    this.shadow,
    this.height,
    this.width,
    this.padding,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Material(
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: border,
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(height: height, width: width, padding: padding, child: child),
      ),
    );
    if (shadow != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: shadow),
        child: content,
      );
    }
    if (semanticLabel != null) {
      content = Semantics(button: true, label: semanticLabel, child: content);
    }
    return content;
  }
}

/// Card surface with the subtle border used across the design.
class CardBox extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry padding;

  const CardBox({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Tappable(
      onTap: onTap,
      color: c.card,
      radius: radius,
      border: BorderSide(color: c.borderSubtle),
      padding: padding,
      child: child,
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? color;
  final Color background;
  final double strokeWidth;
  final String? tooltip;

  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 48,
    this.iconSize = 24,
    this.color,
    this.background = Colors.transparent,
    this.strokeWidth = 2,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Tappable(
      onTap: onTap,
      color: background,
      radius: size / 2,
      width: size,
      height: size,
      child: Center(
        child: AppIcon(
          icon,
          size: iconSize,
          color: color ?? context.palette.text,
          strokeWidth: strokeWidth,
          // Chevrons and arrows point the other way in Arabic.
          mirrorInRtl: icon == AppIcons.back || icon == AppIcons.arrowRight || icon == AppIcons.chevronRight,
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// 64px top bar: leading icon button, title, trailing actions.
class TopBar extends StatelessWidget {
  final String? leadingIcon;
  final VoidCallback? onLeading;
  final String? leadingTooltip;
  final Widget? title;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;
  final Color? foreground;

  const TopBar({
    super.key,
    this.leadingIcon,
    this.onLeading,
    this.leadingTooltip,
    this.title,
    this.actions = const [],
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.foreground,
  });

  static Widget titleText(String text) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: padding,
      child: Row(
        children: [
          if (leadingIcon != null)
            CircleIconButton(
              icon: leadingIcon!,
              color: foreground,
              tooltip: leadingTooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
              onTap: onLeading ?? () => Navigator.of(context).maybePop(),
            ),
          if (title != null) ...[
            const SizedBox(width: 4),
            Expanded(child: title!),
          ] else
            const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

/// Large page header used on the tab screens.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null) ...[
                  Text(subtitle!, style: TextStyle(fontSize: 14, color: c.textSecondary)),
                  const SizedBox(height: 2),
                ],
                Text(
                  title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.3),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Letter avatar tinted by product — or its photo once it has one.
class ProductAvatar extends StatelessWidget {
  final String uuid;
  final String name;
  final String? imageUrl;
  final double size;
  final double radius;
  final double fontSize;

  const ProductAvatar({
    super.key,
    required this.uuid,
    required this.name,
    this.imageUrl,
    this.size = 52,
    this.radius = 16,
    this.fontSize = 20,
  });

  static (Color, Color) tintFor(BuildContext context, String uuid) {
    final tints = context.palette.categoryTints;
    return tints[uuid.hashCode.abs() % tints.length];
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = tintFor(context, uuid);
    final image = productImageProvider(imageUrl);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        image: image == null ? null : DecorationImage(image: image, fit: BoxFit.cover),
      ),
      child: image != null
          ? null
          : Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              style: TextStyle(color: foreground, fontSize: fontSize, fontWeight: FontWeight.w600),
            ),
    );
  }
}

ImageProvider? productImageProvider(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return NetworkImage(url);
  return FileImage(File(url));
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double radius;

  const StatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: foreground),
      ),
    );
  }
}

class Dot extends StatelessWidget {
  final Color color;
  final double size;

  const Dot({super.key, required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const ProgressBar({super.key, required this.value, required this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return Container(
      height: height,
      decoration: BoxDecoration(color: context.palette.surfaceMuted, borderRadius: radius),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        heightFactor: 1,
        child: DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: radius)),
      ),
    );
  }
}

/// Muted track with a raised pill on the selected option.
class SegmentedTabs<T> extends StatelessWidget {
  final List<T> values;
  final Widget Function(T value, bool selected) labelBuilder;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;
  final double radius;

  const SegmentedTabs({
    super.key,
    required this.values,
    required this.labelBuilder,
    required this.selected,
    required this.onChanged,
    this.height = 54,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(radius)),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                selected: values[i] == selected,
                child: Tappable(
                  onTap: () => onChanged(values[i]),
                  color: values[i] == selected ? c.card : Colors.transparent,
                  radius: radius - 4,
                  shadow: values[i] == selected
                      ? const [BoxShadow(color: Color(0x1F502D14), blurRadius: 3, offset: Offset(0, 1))]
                      : null,
                  child: Center(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: values[i] == selected ? FontWeight.w600 : FontWeight.w500,
                        color: values[i] == selected ? c.text : c.textStrong,
                      ),
                      child: labelBuilder(values[i], values[i] == selected),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small centred message with an optional action, for empty and error states.
class MessageView extends StatelessWidget {
  final String title;
  final String? body;
  final String? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MessageView({
    super.key,
    required this.title,
    this.body,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
              child: AppIcon(icon!, size: 28, color: c.textStrong),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.4, color: c.textSecondary),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Colour for a stock number on a card surface.
Color stockNumberColor(BuildContext context, StockLevel level) {
  final status = StatusColors.of(context);
  return switch (level) {
    StockLevel.out => status.soldOutText,
    StockLevel.low => status.lowStockText,
    StockLevel.ok => context.palette.text,
  };
}

/// Text on a filled "received" (green) surface.
Color onReceivedFill(BuildContext context) =>
    context.palette.isDark ? const Color(0xFF0F2416) : const Color(0xFFF4FBF5);

/// Text on a filled "sold" (red) surface.
Color onSoldFill(BuildContext context) =>
    context.palette.isDark ? const Color(0xFF2A0F0B) : context.palette.onDark;
