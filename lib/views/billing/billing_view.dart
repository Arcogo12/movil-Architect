import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/network/api_exception.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/core/utils/app_notifications.dart';
import 'package:movil_architect/core/utils/external_url.dart';
import 'package:movil_architect/models/auth_models.dart';
import 'package:movil_architect/models/billing_models.dart';
import 'package:movil_architect/views/billing/widgets/plan_pricing_card.dart';
import 'package:movil_architect/views/login/widgets/login_widgets.dart';
import 'package:open_filex/open_filex.dart';

class BillingView extends StatefulWidget {
  const BillingView({super.key});

  @override
  State<BillingView> createState() => _BillingViewState();
}

class _BillingViewState extends State<BillingView> {
  bool _loading = true;
  String? _error;
  List<BillingPlan> _plans = [];
  SubscriptionModel? _subscription;
  List<BillingReceipt> _receipts = [];
  List<BillingRefund> _refunds = [];
  List<UsageHistoryPoint> _history = [];
  bool _canRefund = false;
  String? _selectingSlug;
  final _refundReason = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _refundReason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final billing = AppServices.instance.billingService;
      final api = AppServices.instance.mobileApiService;
      final auth = AppServices.instance.authService;
      final results = await Future.wait([
        billing.listPlans(),
        billing.getSubscription(),
        billing.listReceipts(),
        billing.listRefunds(),
        billing.usageHistory(),
        billing.refundEligibility(),
        api.me(),
      ]);
      _plans = results[0] as List<BillingPlan>;
      _subscription = results[1] as SubscriptionModel?;
      _receipts = results[2] as List<BillingReceipt>;
      _refunds = results[3] as List<BillingRefund>;
      _history = results[4] as List<UsageHistoryPoint>;
      _canRefund = results[5] as bool;
      final me = results[6] as MeResponse;
      auth.updateSession(user: me.user, subscription: me.subscription);
      _subscription ??= me.subscription;
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectPlan(BillingPlan plan) async {
    if (_selectingSlug != null) return;
    setState(() => _selectingSlug = plan.slug);
    final billing = AppServices.instance.billingService;
    try {
      if (!plan.requiresCheckout || plan.isFree) {
        await billing.changePlan(plan.slug);
      } else {
        final session = await billing.checkout(
          planSlug: plan.slug,
          returnUrl: '${AppServices.instance.apiClient.dio.options.baseUrl}/',
        );
        if (session.sessionToken != null &&
            (session.isDemo || session.url == null)) {
          await billing.completeDemoCheckout(session.sessionToken!);
        } else if (session.url != null) {
          await openExternalUrl(session.url!);
          if (session.sessionId != null) {
            await billing.completeStripeCheckout(session.sessionId!);
          }
        }
      }
      await _load();
      if (mounted) {
        AppNotifications.success(context, 'Plan actualizado');
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      AppNotifications.error(context, error.message);
    } finally {
      if (mounted) setState(() => _selectingSlug = null);
    }
  }

  Future<void> _openPortal() async {
    try {
      final url = await AppServices.instance.billingService.openPortal(
        '${AppServices.instance.apiClient.dio.options.baseUrl}/',
      );
      if (url != null) await openExternalUrl(url);
    } on ApiException catch (error) {
      if (!mounted) return;
      AppNotifications.error(context, error.message);
    }
  }

  Future<void> _cancel() async {
    try {
      await AppServices.instance.billingService.cancel();
      await _load();
      if (mounted) {
        AppNotifications.success(context, 'Plan cancelado');
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      AppNotifications.error(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes y facturación'),
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
                  if (_subscription != null) ...[
                    Text(
                      'Plan actual: ${_subscription!.plan.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Uso: ${_subscription!.usage.analysesUsed}'
                      '${_subscription!.plan.analysesLimitMonthly == null ? '' : ' / ${_subscription!.plan.analysesLimitMonthly}'}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _openPortal,
                          child: const Text('Portal Stripe'),
                        ),
                        FilledButton(
                          onPressed: _cancel,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD64545),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cancelar plan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Planes',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  PlanCarousel(
                    plans: _plans,
                    currentPlanSlug: _subscription?.plan.slug,
                    selectingSlug: _selectingSlug,
                    onSelect: _selectPlan,
                  ),
                  if (_history.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Uso mensual',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    ..._history.map(
                      (point) => ListTile(
                        dense: true,
                        title: Text(point.label),
                        trailing: Text('${point.analysesUsed} análisis'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Comprobantes',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  if (_receipts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Sin comprobantes'),
                    ),
                  ..._receipts.map((receipt) {
                    final date = receipt.createdAt == null
                        ? ''
                        : DateFormat('dd/MM/yyyy').format(receipt.createdAt!);
                    return ListTile(
                      title: Text(receipt.title),
                      subtitle: Text(date),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            onPressed: () async {
                              final bytes = await AppServices
                                  .instance.billingService
                                  .downloadReceiptPdf(receipt.id);
                              final file = await AppServices
                                  .instance.billingService
                                  .writeTempFile(bytes, 'recibo-${receipt.id}.pdf');
                              await OpenFilex.open(file.path);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.email_outlined),
                            onPressed: () async {
                              await AppServices.instance.billingService
                                  .emailReceipt(receipt.id);
                              if (!context.mounted) return;
                              AppNotifications.success(
                                context,
                                'Comprobante enviado al correo',
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton(
                    onPressed: () async {
                      final bytes = await AppServices.instance.billingService
                          .exportReceiptsZip();
                      final file = await AppServices.instance.billingService
                          .writeTempFile(bytes, 'comprobantes.zip');
                      await OpenFilex.open(file.path);
                    },
                    child: const Text('Descargar ZIP de comprobantes'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reembolsos',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  ..._refunds.map(
                    (item) => ListTile(
                      title: Text(item.status),
                      subtitle: Text(item.reason),
                    ),
                  ),
                  if (_canRefund) ...[
                    const SizedBox(height: 8),
                    LoginPillField(
                      controller: _refundReason,
                      hint: 'MOTIVO DEL REEMBOLSO',
                    ),
                    const SizedBox(height: 10),
                    LoginPrimaryButton(
                      label: 'Solicitar reembolso',
                      onPressed: () async {
                        try {
                          await AppServices.instance.billingService
                              .requestRefund(_refundReason.text);
                          _refundReason.clear();
                          await _load();
                          if (!mounted) return;
                          AppNotifications.success(
                            context,
                            'Reembolso solicitado',
                          );
                        } on ApiException catch (error) {
                          if (!mounted) return;
                          AppNotifications.error(context, error.message);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
