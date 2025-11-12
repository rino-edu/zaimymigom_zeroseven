import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:easy_localization/easy_localization.dart';
import '../../utils/locale_keys.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  String? _text;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    try {
      final txt = await rootBundle.loadString('assets/policy.txt');
      if (!mounted) return;
      setState(() {
        _text = txt;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _text = tr('messages.no_data');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.aboutPrivacyPolicy.tr())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  _text ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
    );
  }
}


