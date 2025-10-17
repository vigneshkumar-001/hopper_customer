import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String url;
  const PaymentWebView({super.key, required this.url});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            print("Navigating to: ${request.url}");
            final uri = Uri.parse(request.url);


            if (request.url.startsWith(
              "https://hoppr-face-two-dbe557472d7f.herokuapp.com/api/customer/flutterwave/callback?status=successful",
            )) {
              final txRef = uri.queryParameters["tx_ref"];
              final transactionId = uri.queryParameters["transaction_id"];
              Navigator.pop(context, {
                "status": "success",
                "txRef": txRef,
                "transactionId": transactionId,
              });
              return NavigationDecision.prevent;
            }

            // ❌ Payment Failure
            if (request.url.contains("flutterwave/fail")) {
              Navigator.pop(context, {
                "status": "failure",
              });
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
