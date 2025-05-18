import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionInfo extends StatefulWidget {
  const VersionInfo({super.key});

  @override
  State<VersionInfo> createState() => _VersionInfoState();
}

class _VersionInfoState extends State<VersionInfo> {
  String _version = 'v1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = 'v${packageInfo.version}';
      });
    } catch (e) {
      // If there's an error, we'll keep the default version
      debugPrint('Error loading version info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      child: Text(
        _version,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
    );
  }
}
