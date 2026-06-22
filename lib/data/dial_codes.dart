// Country dial codes (aligned with attached_assets profile_setup + child profile reference UIs).
class DialOption {
  const DialOption(this.label, this.dial);
  final String label;
  final String dial;
}

const List<DialOption> kDialOptions = [
  DialOption("🇵🇰 +92", "+92"),
  DialOption("🇺🇸 +1", "+1"),
  DialOption("🇬🇧 +44", "+44"),
  DialOption("🇮🇳 +91", "+91"),
  DialOption("🇦🇪 +971", "+971"),
  DialOption("🇸🇦 +966", "+966"),
  DialOption("🇨🇦 +1", "+1"), // Canada shares +1; label distinguishes US/CA in UI if needed
  DialOption("🇦🇺 +61", "+61"),
  DialOption("🇩🇪 +49", "+49"),
  DialOption("🇫🇷 +33", "+33"),
  DialOption("🇹🇷 +90", "+90"),
  DialOption("🇮🇩 +62", "+62"),
  DialOption("🇧🇩 +880", "+880"),
  DialOption("🇪🇬 +20", "+20"),
  DialOption("🇲🇾 +60", "+60"),
];
