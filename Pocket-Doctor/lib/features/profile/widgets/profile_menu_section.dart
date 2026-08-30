import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

import '../../settings/screens/api_key_settings_screen.dart';

class ProfileMenuSection extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final VoidCallback onChangePassword;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onTermsOfService;

  const ProfileMenuSection({
    super.key,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onChangePassword,
    required this.onPrivacyPolicy,
    required this.onTermsOfService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildMenuCard(
          context,
          items: [
            _MenuItemData(
              icon: Icons.key_outlined,
              title: 'Gemini API Key',
              subtitle: 'Add or manage custom API key',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApiKeySettingsScreen()),
              ),
            ),
            _MenuItemData(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: onChangePassword,
            ),
            _MenuItemData(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () => _showComingSoon(context),
            ),
            _MenuItemData(
              icon: Icons.language_outlined,
              title: 'Language',
              subtitle: 'English (US)',
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Support & Legal',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildMenuCard(
          context,
          items: [
            _MenuItemData(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () => _showComingSoon(context),
            ),
            _MenuItemData(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: onPrivacyPolicy,
            ),
            _MenuItemData(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Read our terms of service',
              onTap: onTermsOfService,
            ),
            _MenuItemData(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App version and information',
              onTap: () => _showAbout(context),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'Account Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildMenuCard(
          context,
          items: [
            _MenuItemData(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of your account',
              onTap: onLogout,
              isDestructive: false,
              textColor: AppColors.primary,
            ),
            _MenuItemData(
              icon: Icons.delete_forever_outlined,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              onTap: onDeleteAccount,
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, {required List<_MenuItemData> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;
            
            return Column(
              children: [
                _buildMenuItem(context, item),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItemData item) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (item.textColor ?? AppColors.primary).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          item.icon,
          color: item.isDestructive ? AppColors.error : (item.textColor ?? AppColors.primary),
          size: 20,
        ),
      ),
      title: Text(
        item.title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: item.isDestructive ? AppColors.error : (item.textColor ?? AppColors.textPrimaryLight),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: item.subtitle != null 
          ? Text(
              item.subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey.withOpacity(0.5),
      ),
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.local_hospital, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Pocket Doctor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your AI Health Companion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pocket Doctor provides AI-powered health information and guidance. Always consult healthcare professionals for medical advice.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final Color? textColor;

  _MenuItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
    this.textColor,
  });
}