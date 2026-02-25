import 'package:flutter/material.dart';
import '../services/cie_auth_service.dart';
import '../widgets/cie_login_button.dart';
import 'cie_webview_screen.dart';
import 'success_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool? _isCieIdInstalled;

  @override
  void initState() {
    super.initState();
    _checkCieIdInstallation();
  }

  Future<void> _checkCieIdInstallation() async {
    final installed = await CieAuthService.isCieIdAppInstalled();
    if (mounted) {
      setState(() => _isCieIdInstalled = installed);
    }
  }

  Future<void> _startCieLogin() async {
    setState(() => _isLoading = true);

    // Verifica se CieID è installata
    // final isInstalled = await CieAuthService.isCieIdAppInstalled();
    
    // if (!isInstalled) {
    //   setState(() => _isLoading = false);
    //   if (mounted) {
    //     _showCieIdNotInstalledDialog();
    //   }
    //   return;
    // }

    // Naviga alla schermata WebView per l'autenticazione CIE
    if (!mounted) return;
    
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (context) => const CieWebViewScreen(),
      ),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      // Autenticazione riuscita
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessScreen(userData: result['userData']),
        ),
      );
    } else if (result != null && result['error'] != null) {
      _showErrorSnackbar(result['error']);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showCieIdNotInstalledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            ),
            const SizedBox(width: 12),
            const Text('App CieID richiesta'),
          ],
        ),
        content: const Text(
          'Per utilizzare il login con CIE è necessario avere l\'app CieID installata sul dispositivo.\n\n'
          'Vuoi scaricarla ora dallo store?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non ora'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              CieAuthService.openCieIdStore();
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Scarica'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Cos\'è la CIE?'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'La Carta d\'Identità Elettronica (CIE) è il documento di identità dei cittadini italiani che consente:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              _InfoItem(icon: Icons.badge, text: 'Identificazione fisica'),
              SizedBox(height: 8),
              _InfoItem(icon: Icons.language, text: 'Accesso ai servizi digitali della PA'),
              SizedBox(height: 8),
              _InfoItem(icon: Icons.draw, text: 'Firma elettronica avanzata'),
              SizedBox(height: 20),
              Text(
                'Requisiti:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 12),
              Text('1. CIE 3.0 (con chip NFC)'),
              Text('2. PIN della CIE (8 cifre)'),
              Text('3. App CieID sul telefono'),
              Text('4. Smartphone con NFC'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ho capito'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Login con CIE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Informazioni sulla CIE',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo/Illustrazione
              Hero(
                tag: 'cie_logo',
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0066CC).withOpacity(0.1),
                        const Color(0xFF0066CC).withOpacity(0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    size: 70,
                    color: Color(0xFF0066CC),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Titolo
              Text(
                'Accedi con la tua\nCarta d\'Identità Elettronica',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 12),

              // Sottotitolo
              Text(
                'Utilizza la CIE 3.0 per accedere in modo sicuro ai servizi digitali',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 40),

              // Requisiti
              const CieInfoCard(),

              const SizedBox(height: 40),

              // Pulsante Login CIE
              CieLoginButton(
                onPressed: _startCieLogin,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),

              // Status CieID
              if (_isCieIdInstalled != null)
                _buildCieIdStatus(),

              const SizedBox(height: 24),

              // Link per scaricare CieID
              TextButton.icon(
                onPressed: () => CieAuthService.openCieIdStore(),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Scarica l\'app CieID'),
              ),

              const SizedBox(height: 32),

              // Footer informativo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'I tuoi dati sono protetti e trattati in conformità al GDPR',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCieIdStatus() {
    final installed = _isCieIdInstalled!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: installed
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            installed ? Icons.check_circle : Icons.warning,
            size: 18,
            color: installed ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 8),
          Text(
            installed ? 'CieID installata' : 'CieID non trovata',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: installed ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
