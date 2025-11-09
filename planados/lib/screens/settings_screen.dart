import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'login_screen.dart';

// Theme Provider
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  AppTheme _selectedTheme = AppTheme.light;

  ThemeMode get themeMode => _themeMode;
  AppTheme get selectedTheme => _selectedTheme;

  void setTheme(AppTheme theme) {
    _selectedTheme = theme;
    switch (theme) {
      case AppTheme.light:
        _themeMode = ThemeMode.light;
        break;
      case AppTheme.dark:
        _themeMode = ThemeMode.dark;
        break;
      case AppTheme.pink:
      case AppTheme.tropical:
        _themeMode = ThemeMode.light;
        break;
    }
    notifyListeners();
  }

  ThemeData getThemeData() {
    switch (_selectedTheme) {
      case AppTheme.light:
        return _lightTheme;
      case AppTheme.dark:
        return _darkTheme;
      case AppTheme.pink:
        return _pinkTheme;
      case AppTheme.tropical:
        return _tropicalTheme;
    }
  }
}

enum AppTheme { light, dark, pink, tropical }

// Light Theme
final ThemeData _lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
);

// Dark Theme
final ThemeData _darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
);

// Pink Theme
final ThemeData _pinkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.pink,
    brightness: Brightness.light,
    primary: const Color(0xFFE91E63),
    secondary: const Color(0xFFF48FB1),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Color(0xFFE91E63),
    foregroundColor: Colors.white,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFE91E63),
    foregroundColor: Colors.white,
  ),
);

// Tropical Theme
final ThemeData _tropicalTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF00BFA5),
    secondary: Color(0xFFFFD54F),
    tertiary: Color(0xFFFF6F00),
    surface: Color(0xFFFFF8E1),
    background: Color(0xFFFFF8E1),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Color(0xFF00BFA5),
    foregroundColor: Colors.white,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFFFD54F),
    foregroundColor: Color(0xFF1B5E20),
  ),
  cardTheme: const CardThemeData(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
);

// Settings Screen
class SettingsScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const SettingsScreen({super.key, required this.themeProvider});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailUpdates = false;
  String _currency = 'PHP';
  final _database = FirebaseDatabase.instance.ref();
  String? _userKey;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final usersSnapshot = await _database.child('users').get();

      if (usersSnapshot.exists) {
        final usersData = usersSnapshot.value as Map<dynamic, dynamic>;

        // Find the current user (first user for now - ideally store during login)
        usersData.forEach((key, value) {
          if (_userKey == null) {
            _userKey = key as String;
            final userData = value as Map<dynamic, dynamic>;

            setState(() {
              _emailUpdates = userData['settings']?['emailUpdates'] ?? false;
              _currency = userData['settings']?['currency'] ?? 'PHP';

              // Load theme setting
              final themeName = userData['settings']?['theme'] ?? 'light';
              AppTheme theme;
              switch (themeName) {
                case 'dark':
                  theme = AppTheme.dark;
                  break;
                case 'pink':
                  theme = AppTheme.pink;
                  break;
                case 'tropical':
                  theme = AppTheme.tropical;
                  break;
                default:
                  theme = AppTheme.light;
              }
              widget.themeProvider.setTheme(theme);

              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_userKey == null) return;

    try {
      String themeName;
      switch (widget.themeProvider.selectedTheme) {
        case AppTheme.dark:
          themeName = 'dark';
          break;
        case AppTheme.pink:
          themeName = 'pink';
          break;
        case AppTheme.tropical:
          themeName = 'tropical';
          break;
        default:
          themeName = 'light';
      }

      await _database.child('users').child(_userKey!).child('settings').set({
        'emailUpdates': _emailUpdates,
        'currency': _currency,
        'theme': themeName,
      });
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance', Icons.palette_outlined),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Column(
                children: [
                  _buildThemeOption(
                    title: 'Light Mode',
                    subtitle: 'Bright and clean interface',
                    icon: Icons.light_mode,
                    theme: AppTheme.light,
                    color: Colors.blue,
                  ),
                  const Divider(height: 1),
                  _buildThemeOption(
                    title: 'Dark Mode',
                    subtitle: 'Easy on the eyes',
                    icon: Icons.dark_mode,
                    theme: AppTheme.dark,
                    color: Colors.indigo,
                  ),
                  const Divider(height: 1),
                  _buildThemeOption(
                    title: 'Pink Theme',
                    subtitle: 'Vibrant and playful',
                    icon: Icons.favorite,
                    theme: AppTheme.pink,
                    color: const Color(0xFFE91E63),
                  ),
                  const Divider(height: 1),
                  _buildThemeOption(
                    title: 'Tropical Theme',
                    subtitle: 'Beach vibes and sunshine',
                    icon: Icons.beach_access,
                    theme: AppTheme.tropical,
                    color: const Color(0xFF00BFA5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Preferences Section
          _buildSectionHeader('Preferences', Icons.tune),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Email Updates'),
                  subtitle: const Text('Get travel tips and deals'),
                  secondary: const Icon(Icons.email_outlined),
                  value: _emailUpdates,
                  onChanged: (value) {
                    setState(() => _emailUpdates = value);
                    _saveSettings();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Currency'),
                  subtitle: Text('Current: $_currency'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showCurrencyDialog(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Account Section
          _buildSectionHeader('Account', Icons.person_outline),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showChangePasswordDialog();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: const Text('English'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Language selection coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Support Section
          _buildSectionHeader('Support', Icons.help_outline),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & FAQ'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help center coming soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showAboutDialog(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy policy coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required AppTheme theme,
    required Color color,
  }) {
    final isSelected = widget.themeProvider.selectedTheme == theme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: color)
          : Icon(Icons.circle_outlined, color: Colors.grey[400]),
      onTap: () {
        widget.themeProvider.setTheme(theme);
        _saveSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme changed to $title'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  void _showCurrencyDialog() {
    final currencies = ['PHP', 'USD', 'EUR', 'JPY', 'GBP', 'SGD'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) {
            return RadioListTile<String>(
              title: Text(currency),
              value: currency,
              groupValue: _currency,
              onChanged: (value) {
                setState(() => _currency = value!);
                _saveSettings();
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Min 8 characters',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isChanging ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isChanging
                  ? null
                  : () async {
                      final currentPassword = currentPasswordController.text;
                      final newPassword = newPasswordController.text;
                      final confirmPassword = confirmPasswordController.text;

                      // Validate inputs
                      if (currentPassword.isEmpty ||
                          newPassword.isEmpty ||
                          confirmPassword.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (newPassword.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'New password must be at least 8 characters',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (newPassword != confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isChanging = true);

                      try {
                        // Get current user's email from somewhere (you might need to store this during login)
                        // For now, we'll need to find the user in the database
                        final usersSnapshot = await _database
                            .child('users')
                            .get();

                        if (usersSnapshot.exists) {
                          final usersData =
                              usersSnapshot.value as Map<dynamic, dynamic>;
                          String? userKey;

                          // Find the current user (you might want to store the user key during login)
                          // For now, we'll verify the current password
                          final hashedCurrentPassword = _hashPassword(
                            currentPassword,
                          );

                          usersData.forEach((key, value) {
                            final userData = value as Map<dynamic, dynamic>;
                            if (userData['password'] == hashedCurrentPassword) {
                              userKey = key as String;
                            }
                          });

                          if (userKey == null) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Current password is incorrect'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setDialogState(() => isChanging = false);
                            return;
                          }

                          // Update password in database
                          final hashedNewPassword = _hashPassword(newPassword);
                          await _database.child('users').child(userKey!).update(
                            {'password': hashedNewPassword},
                          );

                          if (!context.mounted) return;

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to change password: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setDialogState(() => isChanging = false);
                      }
                    },
              child: isChanging
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Voyage Planner'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Voyage Planner helps you organize and plan your perfect trips with ease.',
            ),
            SizedBox(height: 16),
            Text('© 2024 Voyage Planner'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Close the dialog
              Navigator.pop(context);

              // Navigate back to login screen and clear all previous routes
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );

              // Show logout message
              Future.delayed(const Duration(milliseconds: 100), () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
