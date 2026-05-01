import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إرسال ملاحظات'),
        ),
        body: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              const Icon(
                Icons.feedback,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'إذا كانت لديك أي مقترحات أو تحسينات للتطبيق، يمكنك التواصل معنا من هنا.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildContactCard(context),
              const Spacer(),
              Text(
                'نحن نقدر آراءكم وملاحظاتكم',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'اختر طريقة التواصل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildContactOption(
            context: context,
            icon: Icons.chat,
            title: 'واتساب',
            subtitle: '[redacted]',
            color: Colors.green,
            onTap: _openWhatsApp,
          ),
          const Divider(height: 1),
          _buildContactOption(
            context: context,
            icon: Icons.email,
            title: 'بريد إلكتروني',
            subtitle: 'tahakadhim00@gmail.com',
            color: Colors.red,
            onTap: _openGmail,
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6)),
      ),
      trailing: Icon(Icons.arrow_back_ios, color: cs.onSurface.withValues(alpha: 0.4), size: 16),
      onTap: onTap,
    );
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/[redacted]?text=مرحباً، لدي ملاحظات حول تطبيق سجل الزيارات');
    
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _openGmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'tahakadhim00@gmail.com',
      query: 'subject=ملاحظات حول تطبيق سجل الزيارات&body=مرحباً،%0A%0Aلدي الملاحظات التالية حول التطبيق:%0A%0A',
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      // Handle error silently
    }
  }
}