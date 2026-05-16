import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthorsScreen extends StatefulWidget {
  const AuthorsScreen({super.key});

  @override
  State<AuthorsScreen> createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  bool _showContent = false;
  bool _funMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDecisionDialog();
    });
  }

  Future<void> _showDecisionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Decyzja'),
          content: const Text('Czy wpisujemy piąteczkę za projekt?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Nie :('),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Jeszcze jak!'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (result == true) {
      setState(() => _showContent = true);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFun = _funMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Autorzy projektu'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isFun
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD54F),
                    Color(0xFFFF8A65),
                    Color(0xFFBA68C8),
                    Color(0xFF4FC3F7),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8F8F8), Color(0xFFEDEDED)],
                ),
        ),
        child: !_showContent
            ? const SizedBox.shrink()
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      _AuthorCard(
                        firstName: isFun ? 'Sir Kacper' : 'Kacper',
                        lastName: 'Błażejewski',
                        albumNumber: '206733',
                        responsibility: isFun
                            ? 'Sigma ohio rizzler backendu, el mucho senior.'
                            : 'Przygotowanie backendu, integracja z API, implementacja logiki webservisów.',
                      ),
                      const SizedBox(height: 16),
                      _AuthorCard(
                        firstName: isFun ? 'Sir Bartosz' : 'Bartosz',
                        lastName: 'Preneta',
                        albumNumber: '202241',
                        responsibility: isFun
                            ? 'Creative skibidi manager, 67 i do pieca developer.'
                            : 'Przygotowanie aplikacji mobilnej, interfejsu użytkownika oraz implementacja testów.',
                      ),
                      const Spacer(),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Standard',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Switch(
                              value: _funMode,
                              onChanged: (value) {
                                setState(() => _funMode = value);
                              },
                              activeColor: const Color(0xFF4CAF50),
                            ),
                            const Text(
                              'Fun',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({
    required this.firstName,
    required this.lastName,
    required this.albumNumber,
    required this.responsibility,
  });

  final String firstName;
  final String lastName;
  final String albumNumber;
  final String responsibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$firstName $lastName',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Numer albumu: $albumNumber',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          const Text(
            'Za co odpowiadał:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(responsibility, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
