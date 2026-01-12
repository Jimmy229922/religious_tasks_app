import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SurahKahfScreen extends StatefulWidget {
  const SurahKahfScreen({super.key});

  @override
  State<SurahKahfScreen> createState() => _SurahKahfScreenState();
}

class _SurahKahfScreenState extends State<SurahKahfScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
          const Color(0xFFF5F5F5)) // لون خلفية فاتح بدلاً من الشفاف
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) async {
            // حقن CSS فقط (أخف وأسرع)
            await _controller.runJavaScript("""
              var style = document.createElement('style');
              style.innerHTML = `
                /* إخفاء العناصر غير المرغوب فيها عبر CSS */
                footer, 
                a[href*='about-us'], a[href*='projects'], a[href*='donate'],
                div[class*='fundraising'],
                /* إخفاء المجتمع والخطط التعليمية */
                a[href*='community'], a[href*='learning-plans']
              ` + ` { display: none !important; } `;
              document.head.appendChild(style);

              // إخفاء إضافي للنصوص العربية بالبحث المباشر
              document.querySelectorAll('a, h3, span, div').forEach(el => {
                if(el.innerText && (el.innerText.includes('المجتمع') || el.innerText.includes('الخطط التعليمية'))) {
                   // تأكد فقط من إخفاء العناصر الفرعية/الأزرار وليس المحتوى الرئيسي
                   if(el.tagName === 'A' || el.className.includes('Card')) {
                      el.style.display = 'none';
                   }
                }
              });
            """);

            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}");
            // في حالة حدوث خطأ، نعرض الصفحة كما هي حتى لا يعلق المستخدم
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://quran.com/?locale=ar'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("القرآن الكريم"),
            backgroundColor: const Color(0xFF1E5128),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _controller.reload();
                },
              )
            ],
          ),
          body: Stack(
            children: [
              // إزالة Opacity للسماح برؤية المحتوى أثناء التحميل إذا لزم الأمر
              WebViewWidget(controller: _controller),

              // مؤشر التحميل يختفي بمجرد انتهاء التحميل
              if (_isLoading)
                Container(
                  color: Colors
                      .white, // خلفية بيضاء تغطي المحتوى أثناء التحميل النظيف
                  child: const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF1E5128))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- صفحة السبحة الإلكترونية (تخصيص تسبيح) --------------------
