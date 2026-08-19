import 'package:flutter/material.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/network/api_exception.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/core/utils/app_notifications.dart';
import 'package:movil_architect/models/support_models.dart';
import 'package:movil_architect/views/login/widgets/login_widgets.dart';
import 'package:movil_architect/views/support/support_ticket_view.dart';

class SupportListView extends StatefulWidget {
  const SupportListView({super.key});

  @override
  State<SupportListView> createState() => _SupportListViewState();
}

class _SupportListViewState extends State<SupportListView> {
  bool _loading = true;
  String? _error;
  List<SupportTicket> _tickets = [];
  final _subject = TextEditingController();
  final _body = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _tickets = await AppServices.instance.supportService.listTickets(limit: 100);
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    try {
      final ticket = await AppServices.instance.supportService.createTicket(
        subject: _subject.text,
        body: _body.text,
      );
      _subject.clear();
      _body.clear();
      await _load();
      if (!mounted) return;
      AppNotifications.success(context, 'Ticket enviado');
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SupportTicketView(ticketId: ticket.id),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      AppNotifications.error(context, error.message);
    }
  }

  Future<void> _confirmDeleteAll() async {
    if (_tickets.isEmpty) {
      AppNotifications.error(context, 'No hay tickets para eliminar');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todos los tickets'),
        content: Text(
          '¿Borrar los ${_tickets.length} tickets?\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar todo',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Eliminando tickets…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await AppServices.instance.supportService.deleteAllTickets(
        _tickets.map((ticket) => ticket.id).toList(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      await _load();
      if (!mounted) return;
      AppNotifications.success(context, 'Tickets eliminados');
    } on ApiException catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      AppNotifications.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      AppNotifications.error(context, 'No se pudieron eliminar los tickets');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda y soporte'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  const Text(
                    'Nuevo ticket',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  LoginPillField(controller: _subject, hint: 'ASUNTO'),
                  const SizedBox(height: 10),
                  LoginPillField(controller: _body, hint: 'DESCRIPCIÓN'),
                  const SizedBox(height: 12),
                  LoginPrimaryButton(label: 'Enviar ticket', onPressed: _create),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mis tickets',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _confirmDeleteAll,
                        tooltip: 'Eliminar todo',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  if (_tickets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Aún no tienes tickets.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ..._tickets.map(
                    (ticket) => ListTile(
                      title: Text(ticket.subject),
                      subtitle: Text(ticket.status),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                SupportTicketView(ticketId: ticket.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
