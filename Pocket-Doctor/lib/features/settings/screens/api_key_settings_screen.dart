import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/api_key_service.dart';
import '../../../core/theme/app_theme.dart';

class ApiKeySettingsScreen extends StatefulWidget {
  const ApiKeySettingsScreen({super.key});

  @override
  State<ApiKeySettingsScreen> createState() => _ApiKeySettingsScreenState();
}

class _ApiKeySettingsScreenState extends State<ApiKeySettingsScreen> {
  final _keyController = TextEditingController();
  bool _useCustomKey = false;
  bool _obscureKey = true;
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final enabled = await ApiKeyService.isCustomKeyEnabled();
      final key = await ApiKeyService.getCustomApiKey();
      if (mounted) {
        setState(() {
          _useCustomKey = enabled;
          _keyController.text = key ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testKey() async {
    final keyToTest = _keyController.text.trim();
    if (keyToTest.isEmpty) {
      _showFeedback('Please enter an API Key to test.', isSuccess: false);
      return;
    }

    setState(() {
      _isTesting = true;
    });

    final isValid = await ApiKeyService.testApiKey(keyToTest);

    if (mounted) {
      setState(() {
        _isTesting = false;
      });
      if (isValid) {
        _showFeedback('✅ API Key verified successfully! It is active and working.', isSuccess: true);
      } else {
        _showFeedback('❌ API Key test failed. Please check the key and your network connection.', isSuccess: false);
      }
    }
  }

  Future<void> _saveSettings() async {
    final keyText = _keyController.text.trim();
    if (_useCustomKey && keyText.isEmpty) {
      _showFeedback('Please enter a valid API Key before enabling custom key usage.', isSuccess: false);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await ApiKeyService.setCustomKeyEnabled(_useCustomKey);
    await ApiKeyService.setCustomApiKey(keyText);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      _showFeedback(
        _useCustomKey
            ? 'Custom API key saved & activated!'
            : 'Saved! System default (.env) key will be used.',
        isSuccess: true,
      );
    }
  }

  void _showFeedback(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openGoogleAiStudio() async {
    final url = Uri.parse('https://aistudio.google.com/app/apikey');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Gemini API Key'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner card
                  _buildHeaderCard(),

                  const SizedBox(height: 24),

                  // Active status badge
                  _buildActiveStatusBadge(),

                  const SizedBox(height: 20),

                  // Toggle custom API key card
                  _buildToggleCard(),

                  const SizedBox(height: 20),

                  // Custom API key text input card
                  if (_useCustomKey) _buildKeyInputCard(),

                  const SizedBox(height: 28),

                  // Save & Test buttons
                  _buildActionButtons(),

                  const SizedBox(height: 24),

                  // Help link card
                  _buildGetApiKeyCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.vpn_key_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Gemini API Key',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'If the default system API key reaches its quota limit, you can toggle ON your own free Gemini API key to keep the AI Chat working smoothly without rebuilding the app.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveStatusBadge() {
    final isCustomActive = _useCustomKey && _keyController.text.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCustomActive
            ? AppColors.success.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCustomActive
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCustomActive ? Icons.check_circle : Icons.info_outline,
            color: isCustomActive ? AppColors.success : AppColors.textSecondaryLight,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCustomActive
                  ? 'Active: Custom User API Key'
                  : 'Active: System Default (.env) API Key',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCustomActive ? AppColors.success : AppColors.textSecondaryLight,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        value: _useCustomKey,
        activeThumbColor: AppColors.primary,
        title: Text(
          'Use Custom API Key',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
        ),
        subtitle: Text(
          'Override default .env system key with your personal key',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
        onChanged: (val) {
          setState(() {
            _useCustomKey = val;
          });
        },
      ),
    );
  }

  Widget _buildKeyInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Gemini API Key',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryLight,
                ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _keyController,
            obscureText: _obscureKey,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimaryLight,
                  fontFamily: 'monospace',
                ),
            decoration: InputDecoration(
              hintText: 'AIzaSy...',
              prefixIcon: const Icon(Icons.key, color: AppColors.primary),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textSecondaryLight,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureKey = !_obscureKey;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.paste_rounded, color: AppColors.primary),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        setState(() {
                          _keyController.text = data!.text!.trim();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_useCustomKey) ...[
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isTesting ? null : _testKey,
              icon: _isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.fact_check_outlined),
              label: Text(_isTesting ? 'Testing Key...' : 'Test API Key'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildGetApiKeyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'How to get a free Gemini API Key?',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1. Go to Google AI Studio (aistudio.google.com)\n2. Sign in with your Google account\n3. Click "Create API Key"\n4. Copy and paste your key above',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _openGoogleAiStudio,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Open Google AI Studio',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.open_in_new, color: AppColors.primary, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
