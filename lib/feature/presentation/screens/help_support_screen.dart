import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String _phoneNumber = '08134351762';
  static const String _email = 'stephenejeh92@gmail.com';
  static const String _whatsappNumber = '2348134351762';

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri.parse('tel:$_phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri.parse(
      'mailto:$_email?subject=CampNest%20Support%20Request',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
      'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent("Hi! I need help with CampNest.")}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Contact Us Section ──
              _SectionTitle(
                title: 'Contact Us',
                icon: Icons.headset_mic_outlined,
              ),
              const SizedBox(height: 12),
              _ContactCard(
                icon: Icons.phone_outlined,
                title: 'Call Us',
                subtitle: _phoneNumber,
                color: Colors.green,
                onTap: () => _launchPhone(context),
              ),
              _ContactCard(
                icon: Icons.email_outlined,
                title: 'Email Us',
                subtitle: _email,
                color: Colors.blue,
                onTap: () => _launchEmail(context),
              ),
              _ContactCard(
                icon: Icons.chat_outlined,
                title: 'WhatsApp',
                subtitle: 'Chat with us on WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _launchWhatsApp(context),
              ),

              const SizedBox(height: 32),

              // ── How to Use the App Section ──
              _SectionTitle(
                title: 'How to Use CampNest',
                icon: Icons.menu_book_outlined,
              ),
              const SizedBox(height: 12),

              _HowToCard(
                step: '1',
                title: 'Create Your Account',
                description:
                    'Sign up with your school email, set your gender, age, and school. '
                    'Verify your email with the OTP code sent to you.',
                icon: Icons.person_add_outlined,
                color: primaryColor,
              ),
              _HowToCard(
                step: '2',
                title: 'Complete Your Profile',
                description:
                    'Add a profile picture and phone number. '
                    'This helps potential roommates and landlords trust you.',
                icon: Icons.edit_outlined,
                color: Colors.orange,
              ),
              _HowToCard(
                step: '3',
                title: 'Browse Room Listings',
                description:
                    'Explore available rooms posted by other students. '
                    'Use the search to filter by location, price, and gender preference.',
                icon: Icons.search_outlined,
                color: Colors.teal,
              ),
              _HowToCard(
                step: '4',
                title: 'Post a Room',
                description:
                    'Have a room to share? Tap the "+" button on the home screen to '
                    'create a listing with photos, price, amenities, and house rules.',
                icon: Icons.add_home_outlined,
                color: Colors.deepPurple,
              ),
              _HowToCard(
                step: '5',
                title: 'Find a Roommate',
                description:
                    'Take the compatibility quiz to get matched with people who share '
                    'your lifestyle — cleanliness, habits, sleep schedule, and interests. '
                    'The higher the score, the better the match!',
                icon: Icons.people_outlined,
                color: Colors.pink,
              ),
              _HowToCard(
                step: '6',
                title: 'Connect & Move In',
                description:
                    'Found a match or a room? Contact the owner directly via '
                    'phone or WhatsApp and arrange a visit. Welcome home! 🏠',
                icon: Icons.handshake_outlined,
                color: Colors.green,
              ),

              const SizedBox(height: 32),

              // ── FAQ Section ──
              _SectionTitle(
                title: 'Frequently Asked Questions',
                icon: Icons.quiz_outlined,
              ),
              const SizedBox(height: 12),

              _FaqTile(
                question: 'Is CampNest free to use?',
                answer:
                    'Yes! CampNest is completely free for students. '
                    'You can browse listings, post rooms, and find roommates at no cost.',
              ),
              _FaqTile(
                question: 'How does roommate matching work?',
                answer:
                    'After completing the compatibility quiz, our algorithm scores you '
                    'against other students based on cleanliness, habits (smoking/drinking), '
                    'interests, and sleep schedule. Matches are sorted by compatibility percentage.',
              ),
              _FaqTile(
                question: 'Can I retake the compatibility quiz?',
                answer:
                    'Yes! Go to your Profile and tap "Retake Compatibility Quiz". '
                    'Your matches will be recalculated based on your new answers.',
              ),
              _FaqTile(
                question: 'How do I report a suspicious listing?',
                answer:
                    'Open the listing details and tap the report icon (flag). '
                    'Select a reason and our team will review it within 24 hours.',
              ),
              _FaqTile(
                question: 'I\'m having issues with the app. What do I do?',
                answer:
                    'You can reach us via WhatsApp, email, or phone using the contact '
                    'options above. We typically respond within a few hours.',
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HowToCard extends StatelessWidget {
  final String step;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _HowToCard({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  step,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            question,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          children: [
            Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
