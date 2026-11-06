
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _blue = Color(0xFF0D5CC7);
const Color _navy = Color(0xFF102F4F);

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const String _preferenceKey = 'kwarihub_language';

  final List<_LanguageOption> _languages = const [
    _LanguageOption(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇬🇧',
    ),
    _LanguageOption(
      code: 'ha',
      name: 'Hausa',
      nativeName: 'Hausa',
      flag: '🇳🇬',
    ),
    _LanguageOption(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
  ];

  String _selectedLanguage = 'en';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_preferenceKey);

      if (saved != null &&
          _languages.any((language) => language.code == saved)) {
        _selectedLanguage = saved;
      }
    } catch (_) {
      // Keep English as the default if preferences cannot be read.
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveLanguage(String code) async {
    if (_saving || code == _selectedLanguage) return;

    setState(() => _saving = true);

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_preferenceKey, code);

      if (!mounted) return;

      setState(() {
        _selectedLanguage = code;
        _saving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Language preference saved. Full app translation requires localization setup.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save your language preference.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'Language',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _blue),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE2EAF3),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.translate_rounded,
                        color: _blue,
                        size: 34,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Choose your language',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Select your preferred language for KwariHub.',
                        style: TextStyle(
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                for (final language in _languages)
                  _LanguageTile(
                    language: language,
                    selected: _selectedLanguage == language.code,
                    enabled: !_saving,
                    onTap: () => _saveLanguage(language.code),
                  ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(color: _blue),
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Your selection is saved on this device. To translate every screen, the app must also be configured with Flutter localization.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
            ),
    );
  }
}

class _LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const _LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

class _LanguageTile extends StatelessWidget {
  final _LanguageOption language;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? _blue : const Color(0xFFE2EAF3),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        enabled: enabled,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 5,
        ),
        leading: Text(
          language.flag,
          style: const TextStyle(fontSize: 28),
        ),
        title: Text(
          language.name,
          style: const TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(language.nativeName),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded, color: _blue)
            : const Icon(
                Icons.radio_button_unchecked_rounded,
                color: Colors.grey,
              ),
      ),
    );
  }
}
