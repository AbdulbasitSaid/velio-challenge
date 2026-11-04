// X4 (UI design F-X4): not found, server error with retry, and "This link needs a newer version of
// the app" for deep-link paths the app doesn't know (S7 FR-005), with the browser as the fallback.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:velio_tokens/velio_tokens.dart';

import '../core/api.dart';
import '../ui/art.dart';
import '../ui/components.dart';

/// Pages the app doesn't have (activities, communities, hosting) live on the web (PRD W1).
Future<void> openInBrowser(String path) =>
    launchUrl(Uri.parse(path.startsWith('http') ? path : '$apiBaseUrl$path'), mode: LaunchMode.externalApplication);

enum ErrorKind { notFound, server, newerApp, offline }

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.kind, this.onRetry, this.browserUrl});
  final ErrorKind kind;
  final VoidCallback? onRetry;

  /// For [ErrorKind.newerApp]: the link to open in the browser instead.
  final String? browserUrl;

  @override
  Widget build(BuildContext context) {
    final (headline, body, icon) = switch (kind) {
      ErrorKind.notFound => (
        'We can’t find that.',
        'The link may be old or mistyped. Your plans and invites are where you left them.',
        'search',
      ),
      ErrorKind.server => ('Something went wrong on our side.', 'It’s not you. Try again in a moment.', 'alert'),
      ErrorKind.newerApp => (
        'This link needs a newer version of the app.',
        'Update Velio to open it, or open it in your browser now.',
        'refresh',
      ),
      // New copy, not in the deck (owner review): offline with nothing saved for this screen.
      ErrorKind.offline => (
        'You’re offline.',
        'Reconnect and try again. Saved invites and plans still open.',
        'offline',
      ),
    };
    return Scaffold(
      appBar: VAppBar(
        leading: VIconButton('close', label: 'Close', onPressed: () => context.go('/')),
      ),
      body: SafeArea(
        top: false,
        child: ScreenBody(
          gap: VelioSpace.s4,
          children: [
            const SizedBox(height: VelioSpace.s8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: VelioColors.surface, shape: BoxShape.circle),
                child: Center(child: VIcon(icon, size: 30)),
              ),
            ),
            Semantics(header: true, child: Text(headline, style: VelioText.title)),
            Text(body, style: VelioText.body.copyWith(color: VelioColors.muted)),
            if ((kind == ErrorKind.server || kind == ErrorKind.offline) && onRetry != null)
              VButton('Try again', block: true, onPressed: onRetry),
            if (kind == ErrorKind.newerApp) ...[
              // Not distributed through a store (S7 §12 Q2), so "Update" opens the same page in the browser.
              VButton(
                'Open in the browser instead',
                variant: ButtonVariant.secondary,
                block: true,
                onPressed: () {
                  openInBrowser(browserUrl ?? '/');
                },
              ),
            ],
            Center(
              child: VButton('My plans', variant: ButtonVariant.quiet, onPressed: () => context.go('/me/plans')),
            ),
          ],
        ),
      ),
    );
  }
}
