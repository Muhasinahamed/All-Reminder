import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common/glass_background.dart';
import '../widgets/common/glass_container.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _shareApp() async {
    const text = 'Check out this amazing Prayer Reminder App developed by Muhasin Bin Muthalif! It helps you calculate accurate local prayer times and plays beautiful Azan alerts. Download now! https://play.google.com/store/apps/details?id=in.inhomex.all_reminder';
    // ignore: deprecated_member_use
    await Share.share(text);
  }

  Future<void> _rateUs() async {
    final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=in.inhomex.all_reminder');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch review url');
    }
  }

  Future<void> _contactEmail() async {
    final Uri url = Uri.parse('mailto:support@inhomex.in');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'About App',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: textColor),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textColor),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Circular Glowing Icon
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
                        : const Color(0xFF0094FF).withValues(alpha: 0.15),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFF00F0FF).withValues(alpha: 0.4)
                            : const Color(0xFF0094FF).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 3,
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.notifications_active_outlined,
                      size: 55,
                      color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // App Title
                Text(
                  'Prayer Reminder App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Main Description Glass Card
                GlassContainer(
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(20),
                  blur: 20,
                  opacity: isDark ? 0.07 : 0.60,
                  borderColor: isDark ? const Color(0xFF00FF87).withValues(alpha: 0.3) : const Color(0xFF10B981).withValues(alpha: 0.4),
                  child: Column(
                    children: [
                      Text(
                        'அனைத்து புகழும் அகிலத்தை படைத்து பரிபாலித்துக் கொண்டிருக்கும் அல்லாஹ் ஒருவனுக்கே! எங்கள் அன்றாட வாழ்வில் தொழுகை மிகவும் முக்கியமானது. இந்த செயலி உங்களின் தொழுகை நேரங்களைச் சரியாக நினைவூட்டி, உரிய நேரத்தில் தொழுகையை நிறைவேற்ற உதவும் ஒரு சிறந்த துணையாகும்.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'முக்கிய அம்சங்கள்:\n• 🕌 தொழுகை நேர நினைவூட்டல் (Prayer Planner) – உங்கள் இருப்பிடத்தின் அடிப்படையில் துல்லியமான தொழுகை நேரங்களைக் கணக்கிடுகிறது.\n • 📢 பாங்கு ஒலியுடன் நினைவூட்டல் – ஒவ்வொரு தொழுகை நேரத்திலும் பாங்கு ஒலியுடன் நினைவூட்டலை வழங்குகிறது.\n • 🗓️ வாராந்திர செய்திகள் – சுழற்சி முறையிலான வாராந்திர இஸ்லாமிய செய்திகள் மற்றும் வெள்ளிக்கிழமை ஜும்ஆ சிறப்பு நினைவூட்டலை வழங்குகிறது.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Forgiveness Note Glass Card
                GlassContainer(
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(16),
                  opacity: isDark ? 0.05 : 0.45,
                  borderColor: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
                  child: Text(
                    'if i lacked in any feature or meaning of this application, i sincerely ask forgiveness from ALLAH(SWT)\n இந்த செயலியில் ஏதேனும் குறைகள், தவறுகள் அல்லது விடுபாடுகள் இருந்தால், அதற்காக எல்லாம் வல்ல அல்லாஹ்விடம் (ﷻ) மனப்பூர்வமாக மன்னிப்புக் கோருகிறேன்.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Developer name & contact link
                Text(
                  'App developed by\nMuhasin Bin Muthalif',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _contactEmail,
                  child: Text(
                    'Contact: support@inhomex.in',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                      decoration: TextDecoration.underline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Please write review and share with your friends and relatives!',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // Action Buttons (Share & Rate Us)
                Row(
                  children: [
                    Expanded(
                      child: GlassContainer(
                        borderRadius: BorderRadius.circular(20),
                        padding: EdgeInsets.zero,
                        borderColor: isDark ? const Color(0xFF00F0FF).withValues(alpha: 0.4) : const Color(0xFF0094FF).withValues(alpha: 0.5),
                        onTap: _shareApp,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isDark
                                ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
                                : const Color(0xFF0094FF).withValues(alpha: 0.15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share_rounded, color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Share App',
                                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GlassContainer(
                        borderRadius: BorderRadius.circular(20),
                        padding: EdgeInsets.zero,
                        borderColor: isDark ? const Color(0xFF00FF87).withValues(alpha: 0.4) : const Color(0xFF10B981).withValues(alpha: 0.5),
                        onTap: _rateUs,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isDark
                                ? const Color(0xFF00FF87).withValues(alpha: 0.15)
                                : const Color(0xFF10B981).withValues(alpha: 0.15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded, color: isDark ? const Color(0xFF00FF87) : const Color(0xFF10B981), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Rate Us',
                                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF00FF87) : const Color(0xFF10B981)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
