import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';

/// Where "Cancel" sends the user, best option first:
/// 1. the link the user saved on the subscription,
/// 2. the known cancel page for that service (from the catalog),
/// 3. a web search for "how to cancel <name> subscription".
///
/// Opened as an external link, so if the service's app is installed
/// (Netflix, Spotify, YouTube...) Android usually opens the app directly.
/// The phone's own app-store subscriptions page.
Uri _storePage() => Platform.isIOS
    ? Uri.parse('https://apps.apple.com/account/subscriptions')
    : Uri.parse('https://play.google.com/store/account/subscriptions');

Uri _resolve(String url) =>
    url == storeSubscriptions ? _storePage() : Uri.parse(url);

({Uri uri, bool isDirect}) cancelTarget(Subscription s) {
  final own = s.cancelUrl?.trim();
  if (own == storeSubscriptions) return (uri: _storePage(), isDirect: true);
  if (own != null && own.isNotEmpty) {
    final uri = Uri.tryParse(own.startsWith('http') ? own : 'https://$own');
    if (uri != null) return (uri: uri, isDirect: true);
  }

  final name = s.name.trim().toLowerCase();
  for (final item in catalog) {
    if (item.cancelUrl != null && item.name.toLowerCase() == name) {
      return (uri: _resolve(item.cancelUrl!), isDirect: true);
    }
  }

  return (
    uri: Uri.https('www.google.com', '/search',
        {'q': 'how to cancel ${s.name} subscription'}),
    isDirect: false,
  );
}

/// Opens the cancel page. Returns false if nothing could be opened.
Future<bool> openCancelPage(Subscription s) async {
  try {
    return await launchUrl(cancelTarget(s).uri,
        mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// "claude.ai" from "https://claude.ai/settings/billing"
String cancelHost(Subscription s) =>
    cancelTarget(s).uri.host.replaceFirst('www.', '');
