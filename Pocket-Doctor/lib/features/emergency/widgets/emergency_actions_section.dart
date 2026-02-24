import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EmergencyActionsSection extends StatelessWidget {
  const EmergencyActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Immediate Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildActionItem(
          context,
          icon: Icons.phone_in_talk,
          title: 'Call Emergency Services (911)',
          subtitle: 'For life-threatening emergencies',
          isUrgent: true,
        ),
        
        const SizedBox(height: 12),
        
        _buildActionItem(
          context,
          icon: Icons.location_on_outlined,
          title: 'Share Your Location',
          subtitle: 'Help responders find you quickly',
        ),
        
        const SizedBox(height: 12),
        
        _buildActionItem(
          context,
          icon: Icons.people_outline,
          title: 'Contact Emergency Contact',
          subtitle: 'Notify your emergency contact',
        ),
        
        const SizedBox(height: 12),
        
        _buildActionItem(
          context,
          icon: Icons.local_hospital_outlined,
          title: 'Find Nearest Hospital',
          subtitle: 'Get directions to closest emergency room',
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isUrgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent 
            ? AppColors.error.withOpacity(0.1)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent 
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
              color: isUrgent 
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isUrgent 
                        ? AppColors.error 
                        : AppColors.textPrimaryLight,
                  ),
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
          
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}