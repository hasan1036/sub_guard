/// Popular services for one-tap adding. Prices are NOT pre-filled on purpose:
/// they differ by country and change often, so the user types what they pay.
class CatalogItem {
  final String name;
  final String category;
  final int color;
  final String? cancelUrl;

  const CatalogItem(this.name, this.category, this.color, [this.cancelUrl]);
}

const categories = [
  'Streaming',
  'Music',
  'AI tools',
  'Finance & trading',
  'Design & creative',
  'Mobile apps',
  'Software',
  'Developer tools',
  'Cloud storage',
  'VPN & security',
  'Social',
  'Gaming',
  'News & reading',
  'Education',
  'Fitness & health',
  'Dating',
  'Shopping & delivery',
  'Phone & internet',
  'Other',
];

/// Cancel link meaning "the subscriptions page of the phone's app store"
/// (Google Play on Android, App Store on iPhone). Used for apps whose
/// premium plan is normally bought inside the app.
const storeSubscriptions = 'store:subscriptions';

/// Palette for custom subscriptions.
const palette = [
  0xFF1E88E5, 0xFF43A047, 0xFFE53935, 0xFF8E24AA, 0xFFFB8C00,
  0xFF00897B, 0xFF3949AB, 0xFFD81B60, 0xFF6D4C41, 0xFF546E7A,
];

// TODO: check every cancel link before launch; companies move these pages.
// Services without a link fall back to a web search for "how to cancel X".
const catalog = <CatalogItem>[
  // ── Streaming ──────────────────────────────────────────────
  CatalogItem('Netflix', 'Streaming', 0xFFE50914, 'https://www.netflix.com/cancelplan'),
  CatalogItem('YouTube Premium', 'Streaming', 0xFFFF0000, 'https://www.youtube.com/paid_memberships'),
  CatalogItem('Amazon Prime', 'Streaming', 0xFF00A8E1, 'https://www.amazon.com/mc'),
  CatalogItem('Disney+', 'Streaming', 0xFF113CCF, 'https://www.disneyplus.com/account'),
  CatalogItem('Max', 'Streaming', 0xFF002BE7),
  CatalogItem('Hulu', 'Streaming', 0xFF1CE783, 'https://secure.hulu.com/account'),
  CatalogItem('Apple TV+', 'Streaming', 0xFF000000, 'https://apps.apple.com/account/subscriptions'),
  CatalogItem('Paramount+', 'Streaming', 0xFF0064FF),
  CatalogItem('Peacock', 'Streaming', 0xFF000000),
  CatalogItem('Crunchyroll', 'Streaming', 0xFFF47521),
  CatalogItem('JioHotstar', 'Streaming', 0xFF0F1F5C),
  CatalogItem('Zee5', 'Streaming', 0xFF8230C6),
  CatalogItem('SonyLIV', 'Streaming', 0xFF1F1F1F),
  CatalogItem('Hoichoi', 'Streaming', 0xFFE2231A),
  CatalogItem('Chorki', 'Streaming', 0xFFE8282B),
  CatalogItem('Bongo', 'Streaming', 0xFFE21F26),
  CatalogItem('Toffee', 'Streaming', 0xFFE6007E),
  CatalogItem('Binge', 'Streaming', 0xFF00A651),
  CatalogItem('MUBI', 'Streaming', 0xFF001489),
  CatalogItem('DAZN', 'Streaming', 0xFF1C1C1C),

  // ── Music ──────────────────────────────────────────────────
  CatalogItem('Spotify', 'Music', 0xFF1DB954, 'https://www.spotify.com/account/subscription/'),
  CatalogItem('Apple Music', 'Music', 0xFFFA243C, 'https://apps.apple.com/account/subscriptions'),
  CatalogItem('YouTube Music', 'Music', 0xFFFF0000, 'https://www.youtube.com/paid_memberships'),
  CatalogItem('Amazon Music Unlimited', 'Music', 0xFF25D1DA),
  CatalogItem('Tidal', 'Music', 0xFF000000),
  CatalogItem('Deezer', 'Music', 0xFFA238FF),
  CatalogItem('SoundCloud Go', 'Music', 0xFFFF5500),

  // ── AI tools ───────────────────────────────────────────────
  CatalogItem('ChatGPT Plus', 'AI tools', 0xFF10A37F),
  CatalogItem('Claude Pro', 'AI tools', 0xFFD97757, 'https://claude.ai/settings/billing'),
  CatalogItem('Google Gemini / Google One', 'AI tools', 0xFF4285F4, 'https://one.google.com/settings'),
  CatalogItem('Perplexity Pro', 'AI tools', 0xFF20808D),
  CatalogItem('Microsoft Copilot Pro', 'AI tools', 0xFF0078D4, 'https://account.microsoft.com/services'),
  CatalogItem('SuperGrok', 'AI tools', 0xFF000000),
  CatalogItem('Midjourney', 'AI tools', 0xFF000000, 'https://www.midjourney.com/account'),
  CatalogItem('ElevenLabs', 'AI tools', 0xFF000000),
  CatalogItem('Runway', 'AI tools', 0xFF000000),
  CatalogItem('Leonardo AI', 'AI tools', 0xFF7B3FE4),
  CatalogItem('Character.AI+', 'AI tools', 0xFF1E1E1E),
  CatalogItem('Poe', 'AI tools', 0xFF5D5CDE),

  // ── Finance & trading ──────────────────────────────────────
  CatalogItem('TradingView', 'Finance & trading', 0xFF131722),
  CatalogItem('Seeking Alpha', 'Finance & trading', 0xFFFF7200),
  CatalogItem('Morningstar', 'Finance & trading', 0xFFE31B23),
  CatalogItem('Koyfin', 'Finance & trading', 0xFF2962FF),
  CatalogItem('Bloomberg', 'Finance & trading', 0xFF000000),
  CatalogItem('The Wall Street Journal', 'Finance & trading', 0xFF111111),
  CatalogItem('Financial Times', 'Finance & trading', 0xFFFCD0B1),
  CatalogItem('YNAB', 'Finance & trading', 0xFF3B5EDA),
  CatalogItem('Monarch Money', 'Finance & trading', 0xFFFF692D),

  // ── Design & creative ──────────────────────────────────────
  CatalogItem('Adobe Creative Cloud', 'Design & creative', 0xFFFF0000, 'https://account.adobe.com/plans'),
  CatalogItem('Adobe Photoshop', 'Design & creative', 0xFF31A8FF, 'https://account.adobe.com/plans'),
  CatalogItem('Adobe Lightroom', 'Design & creative', 0xFF31A8FF, 'https://account.adobe.com/plans'),
  CatalogItem('Canva Pro', 'Design & creative', 0xFF00C4CC, 'https://www.canva.com/settings/billing-and-teams'),
  CatalogItem('Figma', 'Design & creative', 0xFFA259FF),
  CatalogItem('CapCut Pro', 'Design & creative', 0xFF000000),
  CatalogItem('Envato Elements', 'Design & creative', 0xFF81B441),
  CatalogItem('Freepik', 'Design & creative', 0xFF1273EB),
  CatalogItem('Shutterstock', 'Design & creative', 0xFFEE2B24),
  CatalogItem('Picsart', 'Design & creative', 0xFFC209C1),

  // ── Mobile apps (premium bought inside the app, via the app store) ──────
  CatalogItem('CamScanner', 'Mobile apps', 0xFF19BC9C, storeSubscriptions),
  CatalogItem('Adobe Scan', 'Mobile apps', 0xFFFA0F00, storeSubscriptions),
  CatalogItem('Truecaller Premium', 'Mobile apps', 0xFF0087FF, storeSubscriptions),
  CatalogItem('Remini', 'Mobile apps', 0xFF7B2FF7, storeSubscriptions),
  CatalogItem('Lensa', 'Mobile apps', 0xFF111111, storeSubscriptions),
  CatalogItem('Photoroom', 'Mobile apps', 0xFF6B4DFF, storeSubscriptions),
  CatalogItem('Facetune', 'Mobile apps', 0xFF3D3DFF, storeSubscriptions),
  CatalogItem('Meitu', 'Mobile apps', 0xFFFF4F7B, storeSubscriptions),
  CatalogItem('BeautyPlus', 'Mobile apps', 0xFFFF6FA5, storeSubscriptions),
  CatalogItem('VSCO', 'Mobile apps', 0xFF000000, storeSubscriptions),
  CatalogItem('InShot Pro', 'Mobile apps', 0xFFFF3B5C, storeSubscriptions),
  CatalogItem('KineMaster', 'Mobile apps', 0xFFE8313B, storeSubscriptions),
  CatalogItem('Filmora', 'Mobile apps', 0xFF07B2A0, storeSubscriptions),
  CatalogItem('PowerDirector', 'Mobile apps', 0xFF1E3A8A, storeSubscriptions),
  CatalogItem('Speechify', 'Mobile apps', 0xFF2F43FA, storeSubscriptions),
  CatalogItem('Otter.ai', 'Mobile apps', 0xFF1F5BFF, storeSubscriptions),
  CatalogItem('Life360', 'Mobile apps', 0xFF8C52FF, storeSubscriptions),
  CatalogItem('Flo', 'Mobile apps', 0xFFFF6F91, storeSubscriptions),
  CatalogItem('Noom', 'Mobile apps', 0xFFF9A825, storeSubscriptions),
  CatalogItem('Wattpad Premium', 'Mobile apps', 0xFFFF500A, storeSubscriptions),
  CatalogItem('AccuWeather Premium', 'Mobile apps', 0xFFF15A24, storeSubscriptions),
  CatalogItem('Shazam / other app', 'Mobile apps', 0xFF546E7A, storeSubscriptions),

  // ── Software & productivity ────────────────────────────────
  CatalogItem('Microsoft 365', 'Software', 0xFFD83B01, 'https://account.microsoft.com/services'),
  CatalogItem('Google Workspace', 'Software', 0xFF4285F4),
  CatalogItem('Notion', 'Software', 0xFF000000),
  CatalogItem('Grammarly', 'Software', 0xFF15C39A, 'https://account.grammarly.com/subscription'),
  CatalogItem('Zoom', 'Software', 0xFF0B5CFF),
  CatalogItem('Slack', 'Software', 0xFF4A154B),
  CatalogItem('Todoist', 'Software', 0xFFE44332),
  CatalogItem('Evernote', 'Software', 0xFF00A82D),
  CatalogItem('Calendly', 'Software', 0xFF006BFF),
  CatalogItem('Loom', 'Software', 0xFF625DF5),

  // ── Developer tools ────────────────────────────────────────
  CatalogItem('GitHub Copilot', 'Developer tools', 0xFF24292F, 'https://github.com/settings/billing'),
  CatalogItem('Cursor', 'Developer tools', 0xFF000000),
  CatalogItem('JetBrains', 'Developer tools', 0xFF000000),
  CatalogItem('Replit', 'Developer tools', 0xFFF26207),
  CatalogItem('Vercel', 'Developer tools', 0xFF000000),
  CatalogItem('Netlify', 'Developer tools', 0xFF00C7B7),
  CatalogItem('DigitalOcean', 'Developer tools', 0xFF0080FF),
  CatalogItem('AWS', 'Developer tools', 0xFFFF9900),
  CatalogItem('Domain / hosting', 'Developer tools', 0xFF546E7A),

  // ── Cloud storage ──────────────────────────────────────────
  CatalogItem('iCloud+', 'Cloud storage', 0xFF3693F3, 'https://apps.apple.com/account/subscriptions'),
  CatalogItem('Dropbox', 'Cloud storage', 0xFF0061FF, 'https://www.dropbox.com/account/plan'),
  CatalogItem('OneDrive', 'Cloud storage', 0xFF0078D4, 'https://account.microsoft.com/services'),
  CatalogItem('pCloud', 'Cloud storage', 0xFF17BED0),
  CatalogItem('MEGA', 'Cloud storage', 0xFFD9272E),

  // ── VPN & security ─────────────────────────────────────────
  CatalogItem('NordVPN', 'VPN & security', 0xFF4687FF),
  CatalogItem('ExpressVPN', 'VPN & security', 0xFFDA3940),
  CatalogItem('Surfshark', 'VPN & security', 0xFF178A9E),
  CatalogItem('Proton VPN / Mail', 'VPN & security', 0xFF6D4AFF),
  CatalogItem('1Password', 'VPN & security', 0xFF0572EC),
  CatalogItem('Bitwarden', 'VPN & security', 0xFF175DDC),
  CatalogItem('Norton', 'VPN & security', 0xFFFFC300),
  CatalogItem('McAfee', 'VPN & security', 0xFFC01818),
  CatalogItem('Avast', 'VPN & security', 0xFFFF7800),
  CatalogItem('Kaspersky', 'VPN & security', 0xFF006D5C),
  CatalogItem('Other VPN', 'VPN & security', 0xFF546E7A),

  // ── Social ─────────────────────────────────────────────────
  CatalogItem('X Premium', 'Social', 0xFF000000),
  CatalogItem('LinkedIn Premium', 'Social', 0xFF0A66C2, 'https://www.linkedin.com/premium/manage/'),
  CatalogItem('Telegram Premium', 'Social', 0xFF27A7E7),
  CatalogItem('Discord Nitro', 'Social', 0xFF5865F2),
  CatalogItem('Snapchat+', 'Social', 0xFFFFCC00),
  CatalogItem('Meta Verified', 'Social', 0xFF0866FF),
  CatalogItem('Patreon', 'Social', 0xFF000000),

  // ── Gaming ─────────────────────────────────────────────────
  CatalogItem('Xbox Game Pass', 'Gaming', 0xFF107C10, 'https://account.microsoft.com/services'),
  CatalogItem('PlayStation Plus', 'Gaming', 0xFF003791),
  CatalogItem('Nintendo Switch Online', 'Gaming', 0xFFE60012),
  CatalogItem('EA Play', 'Gaming', 0xFFFF4747),
  CatalogItem('Ubisoft+', 'Gaming', 0xFF000000),
  CatalogItem('Apple Arcade', 'Gaming', 0xFFFF2D55, 'https://apps.apple.com/account/subscriptions'),
  CatalogItem('Google Play Pass', 'Gaming', 0xFF34A853, 'https://play.google.com/store/account/subscriptions'),

  // ── News & reading ─────────────────────────────────────────
  CatalogItem('Audible', 'News & reading', 0xFFF8991C),
  CatalogItem('Kindle Unlimited', 'News & reading', 0xFFFF9900, 'https://www.amazon.com/kindle-dbs/ku/ku-central'),
  CatalogItem('Medium', 'News & reading', 0xFF000000, 'https://medium.com/me/settings/membership'),
  CatalogItem('The New York Times', 'News & reading', 0xFF000000),
  CatalogItem('The Economist', 'News & reading', 0xFFE3120B),
  CatalogItem('Everand (Scribd)', 'News & reading', 0xFF1E7B85),
  CatalogItem('Blinkist', 'News & reading', 0xFF2CE080),

  // ── Education ──────────────────────────────────────────────
  CatalogItem('Duolingo Super', 'Education', 0xFF58CC02),
  CatalogItem('Coursera Plus', 'Education', 0xFF0056D2),
  CatalogItem('LinkedIn Learning', 'Education', 0xFF0A66C2),
  CatalogItem('Skillshare', 'Education', 0xFF00FF84),
  CatalogItem('MasterClass', 'Education', 0xFF000000),
  CatalogItem('Brilliant', 'Education', 0xFF000000),
  CatalogItem('Babbel', 'Education', 0xFFFF7300),
  CatalogItem('10 Minute School', 'Education', 0xFFE5262A),

  // ── Fitness & health ───────────────────────────────────────
  CatalogItem('Gym membership', 'Fitness & health', 0xFFFB8C00),
  CatalogItem('Strava', 'Fitness & health', 0xFFFC4C02),
  CatalogItem('Calm', 'Fitness & health', 0xFF3D7DCA),
  CatalogItem('Headspace', 'Fitness & health', 0xFFFF7E1D),
  CatalogItem('MyFitnessPal', 'Fitness & health', 0xFF0066EE),
  CatalogItem('Fitbit Premium', 'Fitness & health', 0xFF00B0B9),

  // ── Dating ─────────────────────────────────────────────────
  CatalogItem('Tinder', 'Dating', 0xFFFE3C72),
  CatalogItem('Bumble', 'Dating', 0xFFFFC629),
  CatalogItem('Hinge', 'Dating', 0xFF000000),

  // ── Shopping & delivery ────────────────────────────────────
  CatalogItem('foodpanda pro', 'Shopping & delivery', 0xFFD70F64),
  CatalogItem('Uber One', 'Shopping & delivery', 0xFF000000),
  CatalogItem('DoorDash DashPass', 'Shopping & delivery', 0xFFFF3008),
  CatalogItem('Walmart+', 'Shopping & delivery', 0xFF0071DC),

  // ── Phone & internet ───────────────────────────────────────
  CatalogItem('Phone plan', 'Phone & internet', 0xFF3949AB),
  CatalogItem('Internet / Wi-Fi', 'Phone & internet', 0xFF00897B),
  CatalogItem('Mobile data pack', 'Phone & internet', 0xFF5E35B1),

  // ── Other ──────────────────────────────────────────────────
  CatalogItem('Google Play subscriptions', 'Other', 0xFF34A853, storeSubscriptions),
  CatalogItem('App Store subscriptions', 'Other', 0xFF0D96F6, 'https://apps.apple.com/account/subscriptions'),
];
