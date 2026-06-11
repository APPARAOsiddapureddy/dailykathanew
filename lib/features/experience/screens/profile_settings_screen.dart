import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../data/user_api_service.dart';
import '../models/app_user_models.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({
    super.key,
    required this.user,
    required this.userApi,
    required this.onUserUpdated,
    required this.onLogout,
  });

  final AppUser user;
  final UserApiService userApi;
  final ValueChanged<AppUser> onUserUpdated;
  final VoidCallback onLogout;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late AppUser _user = widget.user;
  bool _saving = false;
  String? _message;
  bool get _notificationsEnabled => _user.notificationPreference != 'OFF';

  Future<void> _editName() async {
    final updatedName = await showDialog<String>(
      context: context,
      builder: (context) => _EditNameDialog(initialName: _user.name ?? ''),
    );
    if (updatedName == null || updatedName.trim().isEmpty) return;
    await _saveUser(name: updatedName.trim());
  }

  Future<void> _toggleNotifications(bool enabled) async {
    await _saveUser(notificationPreference: enabled ? 'ALL' : 'OFF');
    if (!mounted || !enabled) return;

    if (kIsWeb) {
      setState(() {
        _message =
            'Notification preference saved. Phone settings open only on Android/iOS.';
      });
      return;
    }

    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message =
            'Notification preference saved. Open app settings manually if needed.';
      });
    }
  }

  Future<void> _saveUser({String? name, String? notificationPreference}) async {
    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      final updated = await widget.userApi.updateMe(
        name: name,
        notificationPreference: notificationPreference,
      );
      if (!mounted) return;
      setState(() {
        _user = updated;
        _message = 'Settings updated';
      });
      widget.onUserUpdated(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _user.name?.isNotEmpty == true
        ? _user.name!
        : 'Add name';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE7B3),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.deepSaffron,
                  ),
                ),
                title: Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: const Text('Name'),
                trailing: IconButton(
                  onPressed: _saving ? null : _editName,
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.deepSaffron,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                leading: const Icon(
                  Icons.phone_rounded,
                  color: AppColors.deepSaffron,
                ),
                title: Text(
                  _user.phoneNumber,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: const Text('Phone number'),
                trailing: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.border,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                secondary: const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.deepSaffron,
                ),
                title: const Text(
                  'Notifications',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: const Text('Enable or disable Daily Katha alerts'),
                value: _notificationsEnabled,
                activeThumbColor: AppColors.saffron,
                onChanged: _saving ? null : _toggleNotifications,
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _message == 'Settings updated'
                      ? AppColors.success
                      : AppColors.mutedBrown,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _saving ? null : widget.onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _controller.text.trim();

    return AlertDialog(
      title: const Text('Edit name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Name',
          prefixIcon: Icon(Icons.person_rounded),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (name.isNotEmpty) Navigator.of(context).pop(name);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: name.isEmpty
              ? null
              : () => Navigator.of(context).pop(name),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
