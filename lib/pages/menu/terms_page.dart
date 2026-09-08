// lib/pages/menu/terms_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:cuan_app/providers/info_provider.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        // Gunakan Consumer di dalam title jika ingin title-nya dinamis mengikuti database
        title: Consumer<InfoProvider>(
          builder: (_, p, __) => Text(
            p.termsTitle ?? 'Syarat & Ketentuan',
            style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<InfoProvider>().fetchTerms(force: true),
        child: Consumer<InfoProvider>(
          builder: (_, p, __) {
            if (p.termsMd == null && !p.loadingTerms && p.termsError == null) {
              // Pakai Future.microtask agar tidak nabrak proses build
              Future.microtask(() => p.fetchTerms());
            }
            if (p.loadingTerms && p.termsMd == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (p.termsError != null) {
              return ListView(
                children: [
                  const SizedBox(height: 40),
                  Center(child: Text(p.termsError!, style: TextStyle(color: cs.error))),
                  const SizedBox(height: 8),
                  Center(child: OutlinedButton(
                    onPressed: () => p.fetchTerms(force: true),
                    child: const Text('Coba lagi'),
                  )),
                ],
              );
            }

            return Markdown(
              data: p.termsMd!,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              styleSheet: MarkdownStyleSheet.fromTheme(t).copyWith(
                h2: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                p: t.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            );
          },
        ),
      ),
    );
  }
}
