import 'package:flutter/material.dart';
import 'package:doomscrolling_guard/core/themes/app_colors.dart';

class PermissionGuideScreen extends StatefulWidget {
  const PermissionGuideScreen({super.key});

  @override
  State<PermissionGuideScreen> createState() => _PermissionGuideScreenState();
}

class _PermissionGuideScreenState extends State<PermissionGuideScreen> {
  // Mock states for UI checklist. Real implementation in next sub-task.
  final Map<String, bool> _permissionStatus = {
    'accessibility': false,
    'usage': false,
    'overlay': false,
    'battery': false,
  };

  void _pretendToGrant(String key) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Requesting permission...')),
    // );
    // For now we just toggle for UI demo
    setState(() {
      _permissionStatus[key] = true;
    });
  }

  bool get _allGranted {
    return _permissionStatus.values.every((v) => v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Permissions'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help us protect your time',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Doomscroll Guard needs these permissions to monitor usage and gently intervene when needed. We don\'t collect your personal data.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionItem(
                      icon: Icons.accessibility_new_rounded,
                      title: 'Accessibility Service',
                      description: 'Required to detect when you open target apps.',
                      key: 'accessibility',
                    ),
                    _buildPermissionItem(
                      icon: Icons.analytics_outlined,
                      title: 'Usage Access',
                      description: 'Required to measure your screen time accurately.',
                      key: 'usage',
                    ),
                    _buildPermissionItem(
                      icon: Icons.layers_outlined,
                      title: 'Display over other apps',
                      description: 'Required to show gentle reminders on screen.',
                      key: 'overlay',
                    ),
                    _buildPermissionItem(
                      icon: Icons.battery_charging_full_rounded,
                      title: 'Battery Optimization',
                      description: 'Ensure our worker isn\'t killed by the system.',
                      key: 'battery',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allGranted ? () {
                    // Navigate to dashboard
                  } : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Finish Setup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required String key,
  }) {
    final granted = _permissionStatus[key] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: granted ? AppColors.primaryAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: granted ? AppColors.primaryAccent : AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: granted ? Colors.white : AppColors.primaryAccent,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(description),
        ),
        trailing: granted
            ? const Icon(Icons.check_circle, color: AppColors.primaryAccent)
            : TextButton(
                onPressed: () => _pretendToGrant(key),
                child: const Text('Grant'),
              ),
      ),
    );
  }
}
