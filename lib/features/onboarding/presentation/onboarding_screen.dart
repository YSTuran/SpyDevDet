import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    this.onCompleted,
    this.reviewMode = false,
    super.key,
  });

  final Future<void> Function()? onCompleted;
  final bool reviewMode;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;
  var _saving = false;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.radar,
      title: 'Yerel ağı görünür hâle getir',
      description:
          'SpyDevDet, bağlı olduğun özel IPv4 ağındaki cihazları ve servis '
          'duyurularını gözlemler. Hiçbir cihaza giriş yapmaz veya ayarlarını '
          'değiştirmez.',
      bullets: [
        'Tarama yalnız kullanıcı başlattığında çalışır.',
        'Veriler bir hesaba veya sunucuya gönderilmez.',
        'Sonuçlar bir cihazın casus olduğunu kanıtlamaz.',
      ],
    ),
    _OnboardingPage(
      icon: Icons.tune,
      title: 'Doğru tarama modunu seç',
      description:
          'Hızlı mod temel erişilebilirlik ve seçili portları kontrol eder. '
          'Ayrıntılı mod mDNS, SSDP, WS-Discovery ve NetBIOS yanıtlarını da dinler.',
      bullets: [
        'Hızlı mod kısa kontrol içindir.',
        'Referans ve geçmiş karşılaştırması için ayrıntılı modu kullan.',
        'Uyuyan veya izole edilen cihazlar görünmeyebilir.',
      ],
    ),
    _OnboardingPage(
      icon: Icons.phone_android,
      title: 'Android sınırlamalarını bil',
      description:
          'Android 10 ve üzeri, komşu tablosundaki MAC adreslerini '
          'uygulamalardan gizleyebilir. Bu bir izin hatası değildir.',
      bullets: [
        'MAC yoksa servis kimliği ve IP kanıtları kullanılmaya devam eder.',
        'Misafir ağı veya istemci izolasyonu cihazları birbirinden gizleyebilir.',
        'Modem arayüzündeki bağlı cihaz listesiyle karşılaştırma yapabilirsin.',
      ],
    ),
    _OnboardingPage(
      icon: Icons.compare_arrows,
      title: 'Değişiklikleri karşılaştır',
      description:
          'Tam kapsamlı bir taramayı ağ referansı seçebilir veya geçmişten '
          'iki uygun taramayı elle karşılaştırabilirsin.',
      bullets: [
        'Eklenen, görülmeyen ve bilgisi değişen cihazlar ayrı gösterilir.',
        'Kamera adayı etiketi yalnız gözlemlenen ağ kanıtlarına dayanır.',
        'Rapor paylaşırken gizlilik korumalı seçeneği tercih et.',
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastPage = _page == _pages.length - 1;
    return Scaffold(
      appBar: widget.reviewMode
          ? AppBar(title: const Text('Kullanım rehberi'))
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemBuilder: (context, index) =>
                        _OnboardingPageView(page: _pages[index]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      Semantics(
                        label: '${_page + 1}/${_pages.length} rehber sayfası',
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var index = 0; index < _pages.length; index++)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: index == _page ? 28 : 9,
                                height: 9,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: index == _page
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          if (_page > 0)
                            TextButton(
                              onPressed: _saving ? null : _previous,
                              child: const Text('Geri'),
                            )
                          else
                            const Spacer(),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _saving
                                ? null
                                : lastPage
                                ? _finish
                                : _next,
                            icon: Icon(
                              lastPage ? Icons.check : Icons.arrow_forward,
                            ),
                            label: Text(
                              lastPage
                                  ? widget.reviewMode
                                        ? 'Kapat'
                                        : 'Uygulamaya başla'
                                  : 'İleri',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _next() => _controller.nextPage(
    duration: const Duration(milliseconds: 240),
    curve: Curves.easeOut,
  );

  void _previous() => _controller.previousPage(
    duration: const Duration(milliseconds: 240),
    curve: Curves.easeOut,
  );

  Future<void> _finish() async {
    if (widget.reviewMode) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onCompleted?.call();
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rehber tercihi kaydedilemedi')),
        );
      }
    }
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
    child: Column(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Icon(page.icon, size: 46),
        ),
        const SizedBox(height: 28),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),
        Text(
          page.description,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final bullet in page.bullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(bullet)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
