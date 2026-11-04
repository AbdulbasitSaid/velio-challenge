// Design-system components for Flutter, ported from the approved bundle (spec/2026-11-03_10-34_
// complete-ui-design, ds/velio/components) with the shared tokens. Touch targets ≥ 44 (UX NFR-001).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/format.dart';
import 'art.dart';

/// A progress ring that stands still when the system asks for reduced motion (UX NFR-002).
class Spinner extends StatelessWidget {
  const Spinner({super.key, this.size = 18, this.stroke = 2, required this.color});
  final double size;
  final double stroke;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(
      strokeWidth: stroke,
      color: color,
      value: MediaQuery.disableAnimationsOf(context) ? 0.7 : null,
    ),
  );
}

// ---- Buttons ----

enum ButtonVariant { primary, secondary, quiet }

class VButton extends StatelessWidget {
  const VButton(
    this.label, {
    super.key,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.block = false,
    this.loading = false,
    this.icon,
    this.small = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool block;
  final bool loading;
  final String? icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final primary = variant == ButtonVariant.primary;
    final secondary = variant == ButtonVariant.secondary;
    final bg = primary
        ? (loading ? VelioColors.limePress : (enabled ? VelioColors.lime : VelioColors.disabled))
        : Colors.transparent;
    final fg = enabled || loading ? VelioColors.forest : VelioColors.muted;
    final height = small || variant == ButtonVariant.quiet
        ? VelioSize.touchMin
        : (secondary ? 48.0 : VelioSize.buttonHeight);
    final text = Text(
      label,
      textAlign: TextAlign.center,
      style: VelioText.button.copyWith(
        color: fg,
        fontSize: small ? 15 : 17,
        decoration: variant == ButtonVariant.quiet ? TextDecoration.underline : null,
        decorationColor: fg,
      ),
    );
    final content = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          Spinner(color: fg),
          const SizedBox(width: VelioSpace.s2),
        ] else if (icon != null) ...[
          VIcon(icon!, color: fg),
          const SizedBox(width: VelioSpace.s2),
        ],
        Flexible(child: text),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? label : null,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: secondary
              ? BorderSide(color: enabled ? VelioColors.forest : VelioColors.disabled, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: enabled ? onPressed : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height, minWidth: VelioSize.touchMin),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: variant == ButtonVariant.quiet ? VelioSpace.s3 : (small ? VelioSpace.s4 : VelioSpace.s6),
                vertical: VelioSpace.s2,
              ),
              child: Center(widthFactor: block ? null : 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}

class VIconButton extends StatelessWidget {
  const VIconButton(this.icon, {super.key, required this.label, this.onPressed});
  final String icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkResponse(
      onTap: onPressed,
      radius: 22,
      child: SizedBox.square(
        dimension: VelioSize.touchMin,
        child: Center(child: VIcon(icon, size: 24)),
      ),
    ),
  );
}

// ---- App bar ----

class VAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VAppBar({super.key, this.leading, this.title, this.trailing, this.wordmark = false});
  final Widget? leading;
  final String? title;
  final Widget? trailing;
  final bool wordmark;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) => Material(
    color: VelioColors.cream,
    child: SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: EdgeInsets.fromLTRB(wordmark ? VelioSpace.s5 : VelioSpace.s3, 6, VelioSpace.s3, 6),
          // The bar's height is fixed, so its text stops growing at 150%; every screen repeats the title
          // or the state below it at full size (UI-D5).
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.5,
            child: Row(
              children: [
                if (wordmark)
                  Expanded(
                    child: Semantics(
                      header: true,
                      label: 'Velio',
                      child: ExcludeSemantics(
                        child: Text(
                          'velio',
                          style: VelioText.heading.copyWith(color: VelioColors.forest, letterSpacing: -0.5),
                        ),
                      ),
                    ),
                  )
                else ...[
                  leading ?? const SizedBox(width: VelioSize.touchMin),
                  Expanded(
                    flex: 3,
                    child: Text(
                      title ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: VelioText.subheading,
                    ),
                  ),
                ],
                if (trailing != null)
                  Flexible(
                    flex: 2,
                    child: Align(alignment: Alignment.centerRight, child: trailing),
                  )
                else if (!wordmark)
                  const SizedBox(width: VelioSize.touchMin),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ---- Spots and live state ----

enum SpotsState { live, changed, stale }

/// Five states (UX FR-003). Changes are announced by the screen, throttled, not by the badge.
class SpotsBadge extends StatelessWidget {
  const SpotsBadge({super.key, required this.spots, this.state = SpotsState.live, this.staleLabel});
  final int spots;
  final SpotsState state;
  final String? staleLabel;

  @override
  Widget build(BuildContext context) {
    var bg = VelioColors.surface;
    var fg = VelioColors.forest;
    var dot = true;
    String text;
    if (state == SpotsState.stale) {
      bg = VelioColors.disabled;
      fg = VelioColors.muted;
      text = staleLabel ?? 'Reconnecting…';
      dot = false;
    } else if (spots <= 0) {
      bg = VelioColors.ink;
      fg = VelioColors.cream;
      text = 'Sold out';
      dot = false;
    } else if (spots <= 2) {
      bg = VelioColors.forest;
      fg = VelioColors.lime;
      text = spots == 1 ? 'Last spot' : 'Last 2 spots';
      dot = false;
    } else {
      text = '$spots spots left';
      if (state == SpotsState.changed) bg = VelioColors.lime;
    }
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(VelioRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: VelioColors.live, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              style: VelioText.bodyStrong.copyWith(
                fontSize: 14,
                height: 18 / 14,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum LiveStatus { live, reconnecting, offline }

class LivePill extends StatelessWidget {
  const LivePill({super.key, required this.status, this.minutes});
  final LiveStatus status;
  final int? minutes;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, text) = switch (status) {
      LiveStatus.live => (VelioColors.surface, VelioColors.forest, 'Live'),
      LiveStatus.reconnecting => (VelioColors.disabled, VelioColors.muted, 'Reconnecting…'),
      LiveStatus.offline => (
        VelioColors.ink,
        VelioColors.cream,
        minutes == null ? 'Offline' : 'Offline · updated $minutes min ago',
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(VelioRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == LiveStatus.live)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: VelioColors.live, shape: BoxShape.circle),
              )
            else if (status == LiveStatus.offline)
              VIcon('offline', size: 14, color: VelioColors.lime)
            else
              Spinner(size: 10, stroke: 1.5, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VelioText.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- People ----

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.seed, this.size = 40, this.plus});
  final String name;
  final String? seed;
  final double size;
  final int? plus;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: plus != null ? VelioColors.surface : VelioColors.avatar[avatarIndex(seed ?? name)],
    ),
    child: Text(
      plus != null ? '+$plus' : initials(name),
      textScaler: TextScaler.noScaling,
      style: VelioText.bodyStrong.copyWith(fontSize: (size * 0.36).roundToDouble(), color: VelioColors.forest),
    ),
  );
}

class StackPerson {
  const StackPerson(this.name, [this.seed]);
  final String name;
  final String? seed;
}

/// "Tunde A. and Imani K. are going" (the web's defaultGoing).
String goingLabel(List<StackPerson> shown, int extra) {
  if (shown.isEmpty) return 'Be the first to book';
  if (shown.length == 1 && extra <= 0) return '${shown.first.name} is going';
  final names = shown.take(2).map((p) => p.name).join(', ');
  final rest = extra + (shown.length > 2 ? shown.length - 2 : 0);
  return rest > 0
      ? '$names and $rest other${rest == 1 ? '' : 's'} are going'
      : '${shown.map((p) => p.name).join(' and ')} are going';
}

class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.people, this.total, this.max = 3, this.size = 34, this.label});
  final List<StackPerson> people;
  final int? total;
  final int max;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(max).toList();
    final extra = (total ?? people.length) - shown.length;
    final faces = [
      for (final p in shown) Avatar(name: p.name, seed: p.seed, size: size),
      if (extra > 0) Avatar(name: '', plus: extra, size: size),
    ];
    return Row(
      children: [
        if (faces.isNotEmpty)
          ExcludeSemantics(
            child: SizedBox(
              width: size + (faces.length - 1) * (size - 10) + 4,
              height: size + 4,
              child: Stack(
                children: [
                  for (var i = 0; i < faces.length; i++)
                    Positioned(
                      left: i * (size - 10),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: VelioColors.cream, width: 2),
                        ),
                        child: faces[i],
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (faces.isNotEmpty) const SizedBox(width: VelioSpace.s3),
        Expanded(
          child: Text(
            label ?? goingLabel(shown, extra),
            style: VelioText.body.copyWith(fontSize: 14, height: 20 / 14, color: VelioColors.forest),
          ),
        ),
      ],
    );
  }
}

// ---- Chips, banners, rows ----

enum ChipTone { neutral, lime, sky, forest, outline, danger }

class VChip extends StatelessWidget {
  const VChip(this.text, {super.key, this.tone = ChipTone.neutral, this.icon});
  final String text;
  final ChipTone tone;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ChipTone.neutral => (VelioColors.line, VelioColors.forest),
      ChipTone.lime => (VelioColors.lime, VelioColors.forest),
      ChipTone.sky => (VelioColors.sky, VelioColors.forest),
      ChipTone.forest => (VelioColors.forest, VelioColors.lime),
      ChipTone.outline => (VelioColors.surface, VelioColors.forest),
      ChipTone.danger => (VelioColors.surface, VelioColors.danger),
    };
    final border = tone == ChipTone.outline
        ? Border.all(color: VelioColors.forest, width: 1.5)
        : tone == ChipTone.danger
        ? Border.all(color: VelioColors.danger, width: 1.5)
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, border: border, borderRadius: BorderRadius.circular(VelioRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[VIcon(icon!, size: 16, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              text,
              style: VelioText.caption.copyWith(fontWeight: FontWeight.w700, color: fg, height: 16 / 13),
            ),
          ),
        ],
      ),
    );
  }
}

enum BannerTone { info, offline, error }

class VBanner extends StatelessWidget {
  const VBanner({super.key, required this.title, this.body, this.tone = BannerTone.info, this.action});
  final String title;
  final String? body;
  final BannerTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, iconColor, icon) = switch (tone) {
      BannerTone.info => (VelioColors.info, VelioColors.ink, VelioColors.forest, 'info'),
      BannerTone.offline => (VelioColors.ink, VelioColors.cream, VelioColors.lime, 'offline'),
      BannerTone.error => (VelioColors.surface, VelioColors.ink, VelioColors.danger, 'alert'),
    };
    return Semantics(
      container: true,
      liveRegion: tone != BannerTone.info,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: VelioSpace.s3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(VelioRadius.field),
          border: tone == BannerTone.error ? Border.all(color: VelioColors.danger, width: 1.5) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: VIcon(icon, color: iconColor),
            ),
            const SizedBox(width: VelioSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VelioText.bodyStrong.copyWith(fontSize: 14, height: 20 / 14, color: fg),
                  ),
                  if (body != null)
                    Text(
                      body!,
                      style: VelioText.body.copyWith(fontSize: 14, height: 20 / 14, color: fg),
                    ),
                  if (action != null) ...[const SizedBox(height: VelioSpace.s2), action!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailRow {
  const DetailRow(this.icon, this.value, [this.sub]);
  final String icon;
  final String value;
  final String? sub;
}

class DetailRows extends StatelessWidget {
  const DetailRows(this.rows, {super.key});
  final List<DetailRow> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 1), child: VIcon(r.icon)),
              const SizedBox(width: VelioSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.value, style: VelioText.bodyStrong),
                    if (r.sub != null) Text(r.sub!, style: VelioText.caption.copyWith(color: VelioColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class VList extends StatelessWidget {
  const VList(this.children, {super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: VelioColors.surface, borderRadius: BorderRadius.circular(VelioRadius.card)),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, thickness: 1, color: VelioColors.line),
          children[i],
        ],
      ],
    ),
  );
}

/// A member or invite row (UX FR-005): avatar, name, meta, and a source or status chip.
class MemberRow extends StatelessWidget {
  const MemberRow({
    super.key,
    required this.name,
    this.seed,
    this.meta,
    this.chip,
    this.you = false,
    this.pending = false,
  });
  final String name;
  final String? seed;
  final String? meta;
  final Widget? chip;
  final bool you;
  final bool pending;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: VelioSpace.s3),
        child: Row(
          children: [
            pending
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: VelioColors.line, shape: BoxShape.circle),
                    child: const Center(child: VIcon('ticket', size: 18)),
                  )
                : Avatar(name: name, seed: seed),
            const SizedBox(width: VelioSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(you ? '$name (you)' : name, style: VelioText.bodyStrong),
                  if (meta != null) Text(meta!, style: VelioText.caption.copyWith(color: VelioColors.muted)),
                ],
              ),
            ),
            if (chip != null) ...[
              const SizedBox(width: VelioSpace.s2),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 130), child: chip),
            ],
          ],
        ),
      ),
    ),
  );
}

/// The booking reference with its dashed border (UX: shown at the door).
class BookingRef extends StatelessWidget {
  const BookingRef(this.code, {super.key, this.label = 'Booking ref', this.note});
  final String code;
  final String label;
  final String? note;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedBorder(),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: VelioSpace.s3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: VelioText.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.72,
              color: VelioColors.muted,
            ),
          ),
          SelectableText(code, style: VelioText.code.copyWith(color: VelioColors.forest)),
          if (note != null) Text(note!, style: VelioText.caption.copyWith(color: VelioColors.muted)),
        ],
      ),
    ),
  );
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(VelioRadius.field));
    canvas.drawRRect(rrect, Paint()..color = VelioColors.cream);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = VelioColors.forest;
    for (final metric in (Path()..addRRect(rrect.deflate(0.75))).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => false;
}

// ---- Fields ----

class VTextField extends StatelessWidget {
  const VTextField({
    super.key,
    required this.label,
    this.controller,
    this.help,
    this.error,
    this.placeholder,
    this.code = false,
    this.enabled = true,
    this.keyboardType,
    this.maxLength,
    this.multiline = false,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.textInputAction,
  });
  final String label;
  final TextEditingController? controller;
  final String? help;
  final String? error;
  final String? placeholder;
  final bool code;
  final bool enabled;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool multiline;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(VelioRadius.field),
      borderSide: BorderSide(color: c, width: w),
    );
    final hasError = error != null;
    final style = code
        ? VelioText.code.copyWith(fontSize: 20, height: 1.2, letterSpacing: 4)
        : VelioText.body.copyWith(fontSize: 16, height: 22 / 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: VelioText.bodyStrong.copyWith(fontSize: 14, height: 18 / 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textAlign: code ? TextAlign.center : TextAlign.start,
          textCapitalization: code ? TextCapitalization.characters : TextCapitalization.none,
          autocorrect: !code,
          enableSuggestions: !code,
          maxLength: maxLength,
          maxLines: multiline ? 4 : 1,
          minLines: multiline ? 3 : 1,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          style: style,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: style.copyWith(color: VelioColors.muted),
            counterText: '',
            filled: true,
            fillColor: enabled ? VelioColors.surface : VelioColors.disabled,
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: 15),
            enabledBorder: border(hasError ? VelioColors.danger : VelioColors.fieldBorder, hasError ? 2 : 1.5),
            disabledBorder: border(VelioColors.disabled, 1.5),
            focusedBorder: border(hasError ? VelioColors.danger : VelioColors.forest, 2),
          ),
        ),
        if (hasError || help != null) const SizedBox(height: 6),
        if (hasError)
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: VIcon('alert', size: 16, color: VelioColors.danger),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(error!, style: VelioText.caption.copyWith(color: VelioColors.danger)),
                ),
              ],
            ),
          )
        else if (help != null)
          Text(help!, style: VelioText.caption.copyWith(color: VelioColors.muted)),
      ],
    );
  }
}

class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    container: true,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: VelioColors.line, borderRadius: BorderRadius.circular(VelioRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in options.entries)
            Flexible(
              child: Semantics(
                button: true,
                selected: e.key == value,
                child: GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: VelioSize.touchMin),
                    padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: e.key == value ? VelioColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(VelioRadius.pill),
                    ),
                    child: Text(
                      e.value,
                      textAlign: TextAlign.center,
                      style: VelioText.bodyStrong.copyWith(
                        fontSize: 14,
                        color: e.key == value ? VelioColors.forest : VelioColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ---- Cards and lists ----

class NextStep {
  const NextStep({required this.title, this.meta, this.icon, this.photoUrl, this.scene = Scene.lake, this.onTap});
  final String title;
  final String? meta;
  final String? icon;
  final String? photoUrl;
  final Scene scene;
  final VoidCallback? onTap;
}

/// "What you can do", "{Host}'s other dates", "More in {Community}" (UX FR-007).
class NextStepList extends StatelessWidget {
  const NextStepList(this.items, {super.key});
  final List<NextStep> items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final it in items)
        Padding(
          padding: const EdgeInsets.only(bottom: VelioSpace.s2),
          child: Material(
            color: VelioColors.surface,
            borderRadius: BorderRadius.circular(VelioRadius.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(VelioRadius.card),
              onTap: it.onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s4, vertical: VelioSpace.s3),
                  child: Row(
                    children: [
                      it.icon != null
                          ? Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: VelioColors.lime,
                                borderRadius: BorderRadius.circular(VelioRadius.small),
                              ),
                              child: Center(child: VIcon(it.icon!)),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(VelioRadius.small),
                              child: SizedBox.square(
                                dimension: 44,
                                child: Photo(url: it.photoUrl, small: true, scene: it.scene),
                              ),
                            ),
                      const SizedBox(width: VelioSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.title, style: VelioText.bodyStrong),
                            if (it.meta != null)
                              Text(it.meta!, style: VelioText.caption.copyWith(color: VelioColors.muted)),
                          ],
                        ),
                      ),
                      if (it.onTap != null) const VIcon('chevron'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.title,
    required this.meta,
    this.photoUrl,
    this.members = const [],
    this.memberTotal,
    this.code,
    this.trailing,
    this.past = false,
    this.onTap,
  });
  final String title;
  final String meta;
  final String? photoUrl;
  final List<StackPerson> members;
  final int? memberTotal;
  final String? code;
  final Widget? trailing;
  final bool past;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: past ? 0.78 : 1,
    child: Material(
      color: VelioColors.surface,
      borderRadius: BorderRadius.circular(VelioRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(VelioRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(VelioSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(VelioRadius.small),
                child: SizedBox.square(dimension: 72, child: Photo(url: photoUrl, small: true)),
              ),
              const SizedBox(width: VelioSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: VelioText.bodyStrong.copyWith(fontSize: 16, height: 22 / 16)),
                    const SizedBox(height: 4),
                    Text(meta, style: VelioText.caption.copyWith(color: VelioColors.muted)),
                    const SizedBox(height: 8),
                    if (members.isNotEmpty) AvatarStack(people: members, total: memberTotal, size: 28),
                    if (code != null || trailing != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: VelioSpace.s2,
                        runSpacing: VelioSpace.s2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [if (code != null) VChip(code!), ?trailing],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body});
  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: VelioSpace.s5, vertical: VelioSpace.s8),
    decoration: BoxDecoration(color: VelioColors.surface, borderRadius: BorderRadius.circular(VelioRadius.card)),
    child: Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(color: VelioColors.lime, shape: BoxShape.circle),
          child: Center(child: VIcon(icon, size: 26)),
        ),
        const SizedBox(height: VelioSpace.s4),
        Text(title, textAlign: TextAlign.center, style: VelioText.heading.copyWith(fontSize: 20)),
        const SizedBox(height: VelioSpace.s2),
        Text(
          body,
          textAlign: TextAlign.center,
          style: VelioText.body.copyWith(color: VelioColors.muted),
        ),
      ],
    ),
  );
}

/// Grey shimmer blocks shaped like the screen (PRD M3); static when animations are reduced.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = VelioRadius.small, this.circle = false});
  final double height;
  final double? width;
  final double radius;
  final bool circle;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.circle ? null : BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * _c.value - 1, 0),
            end: Alignment(1 + 2 * _c.value - 1, 0),
            colors: const [VelioColors.line, VelioColors.cream, VelioColors.line],
          ),
        ),
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(header: true, child: Text(text, style: VelioText.heading));
}

/// Screen padding and a centred phone-width column (tablets show the phone layout: UI-D5).
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children, this.gap = VelioSpace.s5});
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(VelioSpace.s5, VelioSpace.s2, VelioSpace.s5, VelioSpace.s8),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
          ],
        ),
      ),
    ),
  );
}
