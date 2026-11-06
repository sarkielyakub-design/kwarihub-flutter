
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _blue = Color(0xFF0D5CC7);
const Color _navy = Color(0xFF102F4F);

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _openLink(
    BuildContext context,
    String url,
  ) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the link.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the link.')),
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
          'Help & Support',
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
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(height: 14),
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 23,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find answers to common questions or contact the KwariHub team.',
                  style: TextStyle(
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 12),
          const _FaqTile(
            question: 'What is KwariHub?',
            answer:
                'KwariHub is a digital textile marketplace that helps buyers '
                'discover textile products and connect with vendors.',
          ),
          const _FaqTile(
            question: 'How do I find textile products?',
            answer:
                'Open the Categories or Products section, browse available '
                'fabrics, and select a product to view its details.',
          ),
          const _FaqTile(
            question: 'How can I place an order?',
            answer:
                'Choose an available product, add it to your cart, and '
                'follow the checkout process displayed in the app.',
          ),
          const _FaqTile(
            question: 'How can I check my order?',
            answer:
                'Open My Orders from your profile or the app navigation '
                'to review orders available to your account.',
          ),
          const _FaqTile(
            question: 'How do I get help with a payment or order?',
            answer:
                'Contact KwariHub through the WhatsApp option below and '
                'provide your order reference if you have one. Never share '
                'your password or OTP.',
          ),
          const _FaqTile(
            question: 'How can I become a vendor?',
            answer:
                'Use the vendor options available in the app. If you need '
                'assistance accessing vendor features, contact our team.',
          ),
          const SizedBox(height: 22),
          const Text(
            'Contact KwariHub',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 12),
          _ContactCard(
            icon: Icons.chat_rounded,
            title: 'WhatsApp Support',
            subtitle: '0802 930 5961',
            onTap: () => _openLink(
              context,
              'https://wa.me/2348029305961',
            ),
          ),
          const SizedBox(height: 10),
          _ContactCard(
            icon: Icons.camera_alt_outlined,
            title: 'Instagram',
            subtitle: '@kwarihub_NG',
            onTap: () => _openLink(
              context,
              'https://www.instagram.com/kwarihub_NG/',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'For your security, never send your password, OTP, or complete payment-card details to anyone.',
            style: TextStyle(
              color: Colors.black54,
              height: 1.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF3)),
      ),
      child: ExpansionTile(
        iconColor: _blue,
        collapsedIconColor: _blue,
        title: Text(
          question,
          style: const TextStyle(
            color: _navy,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE2EAF3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: _blue, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new_rounded, color: _blue),
            ],
          ),
        ),
      ),
    );
  }
}
