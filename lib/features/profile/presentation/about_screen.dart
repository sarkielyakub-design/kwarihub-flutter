
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _blue = Color(0xFF0D5CC7);
const Color _navy = Color(0xFF102F4F);
const Color _lightBlue = Color(0xFFF4F8FF);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openUrl(
    BuildContext context,
    String value,
  ) async {
    final uri = Uri.parse(value);

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this link.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'About KwariHub',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_blue, _navy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 37,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 42,
                    color: _blue,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'KwariHub',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your Textile Marketplace, Connected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Connecting textile buyers and vendors through technology.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _AboutSection(
            title: 'Who We Are',
            body:
                'KwariHub is a technology-driven textile marketplace '
                'designed to transform how textile materials are discovered, '
                'purchased, and sold across Nigeria. Inspired by the vibrant '
                'textile trading community of Kwari Market, Kano State, '
                'KwariHub bridges traditional textile commerce and modern '
                'digital innovation.',
          ),
          const _AboutSection(
            title: 'Our Mission',
            body:
                'To simplify textile trading through a reliable, accessible, '
                'technology-driven platform that connects buyers and sellers, '
                'expands business opportunities, and promotes the growth of '
                'Nigeria’s textile industry.',
          ),
          const _AboutSection(
            title: 'Our Vision',
            body:
                'To become one of Africa’s leading digital textile '
                'marketplaces, empowering textile businesses, supporting '
                'local commerce, and making textile shopping easier '
                'and more accessible nationwide.',
          ),
          const _AboutSection(
            title: 'What We Do',
            body:
                'KwariHub gives textile vendors a digital platform to '
                'showcase products and reach more customers. Buyers can '
                'explore textile products, discover vendors, compare '
                'available options, and make informed purchasing decisions.',
          ),
          _FeatureCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Digital Textile Shopping',
            description:
                'Discover Shadda, Atampa, Ankara, Wax prints, and other fabrics.',
          ),
          _FeatureCard(
            icon: Icons.storefront_outlined,
            title: 'Vendor Growth',
            description:
                'Help textile traders reach new customers and expand their market.',
          ),
          _FeatureCard(
            icon: Icons.phone_android_rounded,
            title: 'Convenience and Accessibility',
            description:
                'Explore textile products from your smartphone, wherever you are.',
          ),
          _FeatureCard(
            icon: Icons.verified_user_outlined,
            title: 'Trust and Transparency',
            description:
                'Promote clear product information, accountability, and responsible trading.',
          ),
          const _AboutSection(
            title: 'Our Commitment to Trust',
            body:
                'We believe trust is essential in every business transaction. '
                'We are committed to encouraging confidence, transparency, '
                'accountability, and responsible interactions between buyers '
                'and vendors.',
          ),
          const _AboutSection(
            title: 'Our Impact',
            body:
                'KwariHub aims to modernize textile commerce, create '
                'opportunities for businesses, encourage technology adoption, '
                'and strengthen Nigeria’s textile trading ecosystem.',
          ),
          const _AboutSection(
            title: 'The Future of Textile Trading',
            body:
                'We believe the future of textile commerce lies in connecting '
                'tradition with technology. We are building a more connected '
                'marketplace that makes textile products easier to discover '
                'and helps vendors expand their reach.',
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2EAF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connect With Us',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.chat_rounded,
                    color: _blue,
                  ),
                  title: const Text('WhatsApp'),
                  subtitle: const Text('0802 930 5961'),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => _openUrl(
                    context,
                    'https://wa.me/2348029305961',
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: _blue,
                  ),
                  title: const Text('Instagram'),
                  subtitle: const Text('@kwarihub_NG'),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => _openUrl(
                    context,
                    'https://www.instagram.com/kwarihub_NG/',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'KwariHub — Your Textile Marketplace, Connected.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final String body;

  const _AboutSection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _blue, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
