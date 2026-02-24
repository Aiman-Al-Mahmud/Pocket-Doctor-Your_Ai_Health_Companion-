import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class EmergencyContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String phoneNumber;
  final bool isPrimary;

  const EmergencyContactCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.phoneNumber,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _initiateCall(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary 
              ? AppColors.error.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary 
                ? AppColors.error.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPrimary 
                    ? AppColors.error 
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isPrimary 
                                ? AppColors.error 
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      Text(
                        phoneNumber,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPrimary 
                              ? AppColors.error 
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 2),
                  
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            Icon(
              Icons.phone,
              color: isPrimary 
                  ? AppColors.error 
                  : AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _initiateCall(BuildContext context) async {
    HapticFeedback.lightImpact();
    
    // Show confirmation dialog for important numbers
    if (isPrimary || phoneNumber == '911') {
      final shouldCall = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(icon, color: AppColors.error),
              const SizedBox(width: 8),
              Text('Call $title'),
            ],
          ),
          content: Text('This will call $phoneNumber. Proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary ? AppColors.error : AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.phone, size: 20),
              label: const Text('Call'),
            ),
          ],
        ),
      );

      if (shouldCall == true) {
        _makeCall(context);
      }
    } else {
      _makeCall(context);
    }
  }

  void _makeCall(BuildContext context) {
    // In a real app, this would use url_launcher to make the call
    // For demo purposes, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: isPrimary ? AppColors.error : AppColors.primary,
        action: SnackBarAction(
          label: 'Cancel',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}