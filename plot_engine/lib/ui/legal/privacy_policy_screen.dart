import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Policy',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: November 29, 2025',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 32),
                _buildSection(
                  context,
                  'Introduction',
                  '''PlotEngine ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our creative writing application and related services.

By using PlotEngine, you agree to the collection and use of information in accordance with this policy.''',
                ),
                _buildSection(
                  context,
                  'Information We Collect',
                  '''We collect information that you provide directly to us:

• Account Information: When you sign in with Google, we receive your name, email address, and profile picture from your Google account.

• Writing Content: Your stories, chapters, characters, locations, and other creative content you create within PlotEngine.

• Entity Data: Information about characters, locations, objects, and events you create or that our AI features identify in your writing.

• Usage Data: Information about how you interact with our application, including features used and preferences set.

We automatically collect certain information:

• Device Information: Browser type, operating system, and device identifiers.

• Log Data: Access times, pages viewed, and actions taken within the application.

• Cookies: We use cookies and similar technologies to maintain your session and preferences.''',
                ),
                _buildSection(
                  context,
                  'How We Use Your Information',
                  '''We use the information we collect to:

• Provide and maintain our service, including cloud storage of your projects
• Process your writing through AI features (entity recognition, consistency checking, suggestions)
• Improve and personalize your experience
• Communicate with you about updates, features, and support
• Monitor and analyze usage patterns to improve our service
• Protect against unauthorized access and ensure security
• Comply with legal obligations''',
                ),
                _buildSection(
                  context,
                  'AI Features and Data Processing',
                  '''PlotEngine uses artificial intelligence to enhance your writing experience:

• Entity Recognition: Our AI analyzes your text to identify and track characters, locations, objects, and events.

• Consistency Checking: We process your content to identify potential plot inconsistencies.

• Suggestions: AI may suggest improvements or identify foreshadowing opportunities.

Your content is processed by third-party AI providers (such as OpenAI and Anthropic) to power these features. These providers process your data according to their respective privacy policies and data processing agreements. We do not use your creative content to train AI models.''',
                ),
                _buildSection(
                  context,
                  'Data Storage and Security',
                  '''Your data is stored securely:

• Cloud Storage: Projects are stored on secure cloud servers with encryption at rest and in transit.

• Local Storage: Desktop versions may store data locally on your device.

• Access Controls: Only you can access your projects unless you explicitly share them.

We implement industry-standard security measures including:

• HTTPS encryption for all data transmission
• Secure authentication via OAuth 2.0
• Regular security audits and updates
• Access logging and monitoring''',
                ),
                _buildSection(
                  context,
                  'Data Sharing',
                  '''We do not sell your personal information. We may share information with:

• Service Providers: Third parties who assist in operating our service (cloud hosting, AI processing, analytics).

• Legal Requirements: When required by law, court order, or government request.

• Business Transfers: In connection with a merger, acquisition, or sale of assets.

• With Your Consent: When you explicitly agree to share information.''',
                ),
                _buildSection(
                  context,
                  'Your Rights and Choices',
                  '''You have the following rights regarding your data:

• Access: Request a copy of your personal data.

• Correction: Update or correct inaccurate information.

• Deletion: Request deletion of your account and associated data.

• Export: Download your projects and content.

• Opt-out: Disable certain AI features or analytics.

To exercise these rights, contact us at support@plotengine.app or use the settings within the application.''',
                ),
                _buildSection(
                  context,
                  'Data Retention',
                  '''We retain your data for as long as your account is active or as needed to provide services. After account deletion:

• Personal information is deleted within 30 days
• Backups may retain data for up to 90 days
• Anonymized analytics data may be retained indefinitely''',
                ),
                _buildSection(
                  context,
                  'Children\'s Privacy',
                  '''PlotEngine is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.''',
                ),
                _buildSection(
                  context,
                  'International Data Transfers',
                  '''Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place for such transfers in compliance with applicable data protection laws.''',
                ),
                _buildSection(
                  context,
                  'Changes to This Policy',
                  '''We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last updated" date. Continued use of PlotEngine after changes constitutes acceptance of the revised policy.''',
                ),
                _buildSection(
                  context,
                  'Contact Us',
                  '''If you have questions about this Privacy Policy or our data practices, please contact us:

Email: support@plotengine.app

We will respond to your inquiry within 30 days.''',
                ),
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    '© 2025 PlotEngine. All rights reserved.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
