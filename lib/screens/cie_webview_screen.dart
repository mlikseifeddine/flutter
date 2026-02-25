import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/cie_auth_service.dart';

/// Schermata WebView per l'autenticazione CIE
/// Funziona sia su Android che iOS, emulatore e dispositivo fisico
class CieWebViewScreen extends StatefulWidget {
  final String? serviceProviderUrl;

  const CieWebViewScreen({
    super.key,
    this.serviceProviderUrl,
  });

  @override
  State<CieWebViewScreen> createState() => _CieWebViewScreenState();
}

class _CieWebViewScreenState extends State<CieWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0;
  String _currentUrl = '';

  String get _spUrl => widget.serviceProviderUrl ?? CieConfig.currentSpUrl;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            debugPrint('📄 Page started: $url');
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            debugPrint('✅ Page finished: $url');
          },
          onProgress: (int progress) {
            setState(() => _loadingProgress = progress / 100);
          },
          onNavigationRequest: (NavigationRequest request) {
            return _handleNavigationRequest(request);
          },
          onWebResourceError: (WebResourceError error) {
            _handleWebError(error);
          },
        ),
      )
      ..loadRequest(Uri.parse(_spUrl));

    debugPrint('🚀 Loading SP URL: $_spUrl');
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final url = request.url;
    debugPrint('🔗 Navigation request: $url');

    // 1. Prima controlla se è un URL per aprire l'app CieID
    //    Questo succede su DISPOSITIVO FISICO quando l'utente clicca "Entra con CIE"
    if (_shouldOpenCieIdApp(url)) {
      debugPrint('📱 Intercepted CieID app URL');
      _openCieIdApp(url);
      return NavigationDecision.prevent;
    }

    // 2. Poi controlla se è il callback finale di autenticazione riuscita
    if (_isAuthenticationCallback(url)) {
      debugPrint('🎉 Authentication callback detected');
      _handleAuthenticationCallback(url);
      return NavigationDecision.prevent;
    }

    // 3. Altrimenti lascia navigare normalmente (mostra la pagina)
    return NavigationDecision.navigate;
  }

  /// Determina se l'URL deve aprire l'app CieID
  /// Questo URL viene generato dal server CIE quando l'utente clicca "Entra con CIE"
  bool _shouldOpenCieIdApp(String url) {
    // Pattern specifici che indicano "apri l'app CieID"
    // Questi URL vengono generati SOLO quando serve l'app CieID
    
    final urlLower = url.toLowerCase();
    
    // Schema URL diretto per CieID
    if (urlLower.startsWith('cieid://')) {
      return true;
    }
    
    // URL con /OpenApp indica che il server vuole aprire l'app CieID
    if (url.contains('/OpenApp')) {
      return true;
    }
    
    // URL intent Android per CieID
    if (url.contains('intent://') && url.contains('it.ipzs.cieid')) {
      return true;
    }
    
    return false;
  }

  /// Determina se l'URL è il callback finale dopo autenticazione riuscita
  bool _isAuthenticationCallback(String url) {
    // Il callback finale arriva dal TUO Service Provider (demo.ecivis.it)
    // NON dal server CIE (preproduzione.oidc.idserver...)
    
    // Ignora tutte le pagine del server CIE - non sono callback
    if (url.contains('idserver.servizicie.interno.gov.it')) {
      return false;
    }
    if (url.contains('preproduzione')) {
      return false;
    }
    
    // Il vero callback è quando il Service Provider riceve il codice di autorizzazione
    // e redirige l'utente alla pagina di successo
    
    // Callback OIDC standard: redirect_uri con code=
    if (url.contains('demo.ecivis.it') && url.contains('code=')) {
      return true;
    }
    
    // Pagina di successo del Service Provider
    if (url.contains('demo.ecivis.it') && 
        (url.contains('/success') || 
         url.contains('/logged') || 
         url.contains('/profile') ||
         url.contains('/authenticated'))) {
      return true;
    }
    
    return false;
  }

  /// Gestisce il callback di autenticazione riuscita
  void _handleAuthenticationCallback(String url) {
    debugPrint('✅ Processing authentication callback: $url');

    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    final userData = <String, dynamic>{};

    // Estrai tutti i parametri utili
    final possibleParams = [
      'code', 'token', 'access_token', 'id_token',
      'fiscal_code', 'fiscalCode', 'cf',
      'name', 'nome', 'given_name',
      'surname', 'cognome', 'family_name',
      'email', 'sub',
      'birthDate', 'dataNascita', 'date_of_birth',
      'birthPlace', 'luogoNascita', 'place_of_birth',
    ];

    for (final param in possibleParams) {
      if (params.containsKey(param) && params[param]!.isNotEmpty) {
        userData[param] = params[param];
      }
    }

    Navigator.pop(context, {
      'success': true,
      'userData': userData,
      'callbackUrl': url,
    });
  }

  /// Apre l'app CieID per l'autenticazione con NFC
  Future<void> _openCieIdApp(String url) async {
    debugPrint('📱 Opening CieID app with URL: $url');

    // Verifica se CieID è installata
    final isInstalled = await CieAuthService.isCieIdAppInstalled();

    if (!isInstalled) {
      // CieID non installata (normale su emulatore)
      if (mounted) {
        _showCieIdNotAvailableDialog();
      }
      return;
    }

    // Mostra dialog di conferma
    final shouldContinue = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.contactless, color: Color(0xFF0066CC)),
            ),
            const SizedBox(width: 12),
            const Text('Autenticazione CIE'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Verrai reindirizzato all\'app CieID.'),
            const SizedBox(height: 16),
            _buildCheckItem('Tieni pronta la tua CIE'),
            const SizedBox(height: 8),
            _buildCheckItem('Ricorda il PIN (8 cifre)'),
            const SizedBox(height: 8),
            _buildCheckItem('Attiva NFC sul dispositivo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.nfc, size: 18),
            label: const Text('Apri CieID'),
          ),
        ],
      ),
    );

    if (shouldContinue != true) return;

    // Apri l'app CieID
    final opened = await CieAuthService.openCieIdApp(url);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire l\'app CieID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCieIdNotAvailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.phone_android, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('App CieID richiesta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Per completare l\'autenticazione serve l\'app CieID con un dispositivo fisico dotato di NFC.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Su emulatore puoi vedere la pagina di login ma non completare l\'autenticazione.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              CieAuthService.openCieIdStore();
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Scarica CieID'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  void _handleWebError(WebResourceError error) {
    debugPrint('❌ WebView error: ${error.description}');
    if (!mounted) return;
    if (error.isForMainFrame == false) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Errore: ${error.description}'),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  void _cancelAuthentication() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annullare?'),
        content: const Text('Vuoi interrompere l\'autenticazione?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(this.context, {
                'success': false,
                'error': 'Autenticazione annullata',
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sì, annulla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticazione CIE'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancelAuthentication,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: 'Ricarica',
          ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0066CC)),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          
          if (_isLoading && _loadingProgress < 0.3)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0066CC)),
                    SizedBox(height: 20),
                    Text('Caricamento...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}