import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../browser_state.dart';

/// Веб-страница одной вкладки.
class TabWebView extends StatefulWidget {
  const TabWebView({super.key, required this.tab, required this.state});

  final BrowserTab tab;
  final BrowserState state;

  @override
  State<TabWebView> createState() => _TabWebViewState();
}

class _TabWebViewState extends State<TabWebView> {
  PullToRefreshController? _pullToRefresh;

  static const _allowedSchemes = {
    'http', 'https', 'about', 'data', 'blob', 'javascript', 'file',
  };

  BrowserTab get tab => widget.tab;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      _pullToRefresh = PullToRefreshController(
        onRefresh: () async => tab.controller?.reload(),
      );
    }
  }

  Future<void> _syncNavigation(InAppWebViewController c) async {
    tab.canGoBack = await c.canGoBack();
    tab.canGoForward = await c.canGoForward();
    widget.state.touch();
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(tab.url!)),
      initialSettings: InAppWebViewSettings(
        isInspectable: kDebugMode,
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        allowsBackForwardNavigationGestures: true,
        useShouldOverrideUrlLoading: true,
        incognito: tab.incognito,
        cacheEnabled: !tab.incognito,
        supportZoom: true,
      ),
      pullToRefreshController: _pullToRefresh,
      onWebViewCreated: (c) => tab.controller = c,
      onLoadStart: (c, url) {
        if (url != null) tab.url = url.toString();
        tab.progress = 0;
        widget.state.touch();
      },
      onProgressChanged: (c, progress) {
        tab.progress = progress;
        if (progress == 100) _pullToRefresh?.endRefreshing();
        widget.state.touch();
      },
      onLoadStop: (c, url) async {
        _pullToRefresh?.endRefreshing();
        tab.progress = 100;
        final title = await c.getTitle();
        if (title != null && title.isNotEmpty) tab.title = title;
        widget.state.recordVisit(tab, title, url?.toString());
        await _syncNavigation(c);
      },
      onReceivedError: (c, request, error) {
        if (request.isForMainFrame ?? false) _pullToRefresh?.endRefreshing();
      },
      onTitleChanged: (c, title) {
        if (title != null && title.isNotEmpty) {
          tab.title = title;
          widget.state.touch();
        }
      },
      onUpdateVisitedHistory: (c, url, isReload) async {
        if (url != null) tab.url = url.toString();
        await _syncNavigation(c);
      },
      shouldOverrideUrlLoading: (c, action) async {
        final scheme = action.request.url?.scheme.toLowerCase() ?? '';
        return _allowedSchemes.contains(scheme)
            ? NavigationActionPolicy.ALLOW
            : NavigationActionPolicy.CANCEL;
      },
    );
  }
}
