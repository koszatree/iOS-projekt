import 'package:flutter/material.dart';

import 'package:app/models/status.dart';
import 'package:app/providers/service_status.dart';

class ServerStatusScreen extends StatefulWidget {
  const ServerStatusScreen({super.key});

  @override
  State<ServerStatusScreen> createState() => _ServerStatusScreenState();
}

class _ServerStatusScreenState extends State<ServerStatusScreen> {
  List<Status> _statuses = [];
  bool _loading = true;
  String? _errorMessage;

  // Dane zbiorcze z <return>
  String _globalCheckedAt = '';
  String _globalMessage = '';
  bool _globalOk = true;
  int _globalResponseTimeMs = 0;

  @override
  void initState() {
    super.initState();
    _pingAll();
  }

  Future<void> _pingAll() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final result = await ServiceStatus.pingAll();
      setState(() {
        _statuses = result.statuses;
        _globalCheckedAt = result.checkedAt;
        _globalMessage = result.message;
        _globalOk = result.ok;
        _globalResponseTimeMs = result.responseTimeMs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Błąd pobierania statusów: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Status połączenia z serwerem'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież',
            onPressed: _pingAll,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ── Ładowanie ─────────────────────────────────────────────────────────
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF4CAF50)),
            SizedBox(height: 16),
            Text(
              'Sprawdzanie statusów…',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // ── Błąd połączenia ───────────────────────────────────────────────────
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Color(0xFFD32F2F)),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: Color(0xFFD32F2F)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pingAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Spróbuj ponownie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Lista z banerem zbiorczym ─────────────────────────────────────────
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Baner zbiorczy
        _GlobalStatusBanner(
          ok: _globalOk,
          message: _globalMessage,
          checkedAt: _globalCheckedAt,
          responseTimeMs: _globalResponseTimeMs,
        ),
        const SizedBox(height: 16),

        // Karty usług
        if (_statuses.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 32),
              child: Text(
                'Brak danych o usługach',
                style: TextStyle(fontSize: 15, color: Colors.black45),
              ),
            ),
          )
        else
          ..._statuses.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StatusCard(status: s),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: baner zbiorczy (dane z <return>)
// ─────────────────────────────────────────────────────────────────────────────

class _GlobalStatusBanner extends StatelessWidget {
  const _GlobalStatusBanner({
    required this.ok,
    required this.message,
    required this.checkedAt,
    required this.responseTimeMs,
  });

  final bool ok;
  final String message;
  final String checkedAt;
  final int responseTimeMs;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F);
    final icon = ok ? Icons.check_circle : Icons.cancel;
    final label = ok ? 'Wszystkie usługi działają' : 'Wykryto problemy';

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${responseTimeMs} ms',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
          if (checkedAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Sprawdzono: $checkedAt',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: karta statusu pojedynczej usługi
// ─────────────────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});

  final Status status;

  @override
  Widget build(BuildContext context) {
    final color = status.ok ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F);
    final icon = status.ok ? Icons.check_circle_outline : Icons.error_outline;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nagłówek ───────────────────────────────────────────────
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.serviceName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                      if (status.externalServiceName.isNotEmpty)
                        Text(
                          status.externalServiceName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                    ],
                  ),
                ),
                // Czas odpowiedzi
                Text(
                  '${status.responseTimeMs} ms',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(width: 8),
                // Kod HTTP
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'HTTP ${status.httpStatusCode}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Szczegóły ──────────────────────────────────────────────
            _DetailRow(label: 'Wiadomość', value: status.message),
            _DetailRow(label: 'URL', value: status.checkedUrl),
            _DetailRow(label: 'Sprawdzono', value: status.checkedAt),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: wiersz szczegółu
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF212121)),
            ),
          ),
        ],
      ),
    );
  }
}
