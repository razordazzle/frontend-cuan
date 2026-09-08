import 'package:cuan_app/providers/info_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final p = context.watch<InfoProvider>();
    if (p.about == null && !p.loadingAbout && p.aboutError == null)
      p.fetchAbout();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'About Us',
          style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: p.loadingAbout
          ? const Center(child: CircularProgressIndicator())
          : p.aboutError != null
          ? Center(child: Text(p.aboutError!))
          : p.about == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // 'Tentang ${p.about!.company}',
                    'Tentang Cuan',
                    style: t.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    p.about!.description,
                    style: t.textTheme.bodyLarge?.copyWith(height: 1.6),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  // if (p.about!.logoUrl.isNotEmpty)
                  //   Center(
                  //     child: Image.network(
                  //       p.about!.logoUrl,
                  //       height: 60,
                  //       errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  //     ),
                  //   ),
                  // Center(
                  //   child: Image.asset('assets/icon/icon.png', height: 60),
                  // ),
                  Image.asset('assets/icon/icon.png', height: 60),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Email: ', style: t.textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => _launchEmail(p.about!.email),
                        child: Text(
                          p.about!.email,
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1),
                  const SizedBox(height: 8),
                  Text(
                    'Version ${p.about!.version}',
                    style: t.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}
