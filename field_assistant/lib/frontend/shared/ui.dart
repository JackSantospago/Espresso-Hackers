import 'package:flutter/material.dart';

/// Small building blocks shared by every page so they look like one product:
/// a big serif page title, quiet section labels, and grouped white cards with
/// hairline dividers. Icons are plain outlines; color is kept for actions.

/// Big serif title at the top of a page, with an optional one-line subtitle.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Text(title, style: t.headlineMedium)),
          ?trailing,
        ]),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
        ],
      ]),
    );
  }
}

/// Small grey label above a group, with an optional action on the right ("See all").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 6),
      child: Row(children: [
        Expanded(child: Text(text, style: t.labelLarge?.copyWith(color: c.onSurfaceVariant))),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: Text(action!),
          ),
      ]),
    );
  }
}

/// White card holding rows separated by hairlines.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 52),
            children[i],
          ],
        ]),
      );
}

/// One row in a [GroupCard]: outline icon, title, optional subtitle and trailing.
class RowTile extends StatelessWidget {
  const RowTile({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleStyle,
    this.iconColor,
  });
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextStyle? titleStyle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          if (icon != null) ...[
            Icon(icon, size: 21, color: iconColor ?? c.onSurfaceVariant),
            const SizedBox(width: 15),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: titleStyle ?? t.bodyLarge),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
          // Values on the right may wrap, never push the row off screen.
          if (trailing != null) ...[const SizedBox(width: 8), Flexible(child: trailing!)]
          else if (onTap != null) Icon(Icons.chevron_right_rounded, color: c.outline),
        ]),
      ),
    );
  }
}
