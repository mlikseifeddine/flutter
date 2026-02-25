import 'package:flutter/material.dart';

/// Pulsante ufficiale "Entra con CIE"
/// Segue le linee guida grafiche del Ministero dell'Interno
class CieLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;

  const CieLoginButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled && !isLoading
            ? [
                BoxShadow(
                  color: const Color(0xFF0066CC).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0066CC),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[500],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icona CIE stilizzata
                  _buildCieIcon(),
                  const SizedBox(width: 12),
                  const Text(
                    'Entra con CIE',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCieIcon() {
    return Container(
      width: 36,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Stack(
        children: [
          // Chip dorato della carta
          Positioned(
            left: 5,
            top: 5,
            child: Container(
              width: 12,
              height: 14,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildChipLine(),
                  const SizedBox(height: 2),
                  _buildChipLine(),
                  const SizedBox(height: 2),
                  _buildChipLine(),
                ],
              ),
            ),
          ),
          // Linee decorative
          Positioned(
            right: 4,
            top: 6,
            child: Container(
              width: 10,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC).withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 11,
            child: Container(
              width: 10,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC).withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 16,
            child: Container(
              width: 10,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC).withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipLine() {
    return Container(
      width: 8,
      height: 1.5,
      color: const Color(0xFF8B6914),
    );
  }
}

/// Versione compatta del pulsante CIE
class CieLoginButtonCompact extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const CieLoginButtonCompact({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0066CC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.credit_card, size: 22),
        label: const Text(
          'CIE',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Card informativa sulla CIE
class CieInfoCard extends StatelessWidget {
  const CieInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.blue.shade700 : Colors.blue[100]!,
        ),
      ),
      child: Column(
        children: [
          _buildRequirement(
            context,
            Icons.credit_card,
            'CIE 3.0 con PIN attivo',
          ),
          const SizedBox(height: 10),
          _buildRequirement(
            context,
            Icons.phone_android,
            'App CieID installata',
          ),
          const SizedBox(height: 10),
          _buildRequirement(
            context,
            Icons.nfc,
            'Smartphone con NFC attivo',
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          color: Colors.green[600],
          size: 20,
        ),
        const SizedBox(width: 10),
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
