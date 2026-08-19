import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/guest_controller.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/core/utils/app_notifications.dart';
import 'package:movil_architect/models/chat_models.dart';
import 'package:movil_architect/views/chat/widgets/chat_message_bubble.dart';
import 'package:movil_architect/views/chat/widgets/plano_chat_attachment.dart';
import 'package:movil_architect/views/chat/widgets/typing_indicator_bubble.dart';
import 'package:movil_architect/views/dashboard/widgets/dashboard_shell.dart';
import 'package:movil_architect/views/register/register_view.dart';
import 'package:movil_architect/views/shared/app_states.dart';
import 'package:movil_architect/views/shared/attachment_picker_sheet.dart';

class GuestView extends StatefulWidget {
  const GuestView({super.key});

  @override
  State<GuestView> createState() => _GuestViewState();
}

class _GuestViewState extends State<GuestView> {
  late final GuestController _controller;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = GuestController()..load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RegisterView()),
    );
  }

  Future<void> _openAttachmentPicker() async {
    if (!_controller.canAnalyze) {
      _showLimitSnack(
        'Ya usaste el análisis de prueba. Crea una cuenta para continuar.',
      );
      return;
    }

    final pick = await showAttachmentPickerSheet(context);
    if (pick == null || !mounted) return;
    await _controller.preparePendingPlano(pick.file, pick.name);
    _scrollToBottom();
  }

  Future<void> _send() async {
    if (!_controller.hasPendingPlano && !_controller.canAsk) {
      _showLimitSnack(
        'Ya usaste tu pregunta de prueba. Crea una cuenta para continuar.',
      );
      return;
    }

    _scrollToBottom();
    final ok = await _controller.send();
    if (!mounted) return;
    if (_controller.actionError != null) {
      AppNotifications.error(context, _controller.actionError!);
    }
    if (ok) _scrollToBottom();
  }

  void _showLimitSnack(String message) {
    AppNotifications.error(context, message);
  }

  void _dismissPlanoAttachment() {
    if (_controller.isLoadingPendingPlano) {
      _controller.cancelPendingPlanoLoad();
    } else {
      _controller.clearPendingPlano();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.state == GuestUiState.loading) {
              return const AppLoadingView(message: 'Cargando prueba...');
            }

            if (_controller.state == GuestUiState.error) {
              return AppErrorView(
                message: _controller.errorMessage ?? 'Error al cargar',
                onRetry: _controller.load,
              );
            }

            return Column(
              children: [
                _GuestTopBar(
                  analysesRemaining: _controller.analysesRemaining,
                  asksRemaining: _controller.asksRemaining,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(child: _buildMainContent()),
                _buildComposer(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (!_controller.hasConversation) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: DashboardHero(),
        ),
      );
    }

    return _GuestMessagesList(
      controller: _controller,
      scrollController: _scrollController,
    );
  }

  Widget _buildComposer() {
    final exhausted = _controller.trialExhausted || !_controller.canContinueTrial;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_controller.isLoadingPendingPlano &&
            _controller.pendingPlanoName != null)
          PendingPlanoLoadingBanner(
            fileName: _controller.pendingPlanoName!,
            progress: _controller.pendingPlanoLoadProgress,
            onCancel: _controller.cancelPendingPlanoLoad,
          )
        else if (_controller.hasPendingPlano &&
            _controller.pendingPlanoFile != null &&
            _controller.pendingPlanoName != null)
          PendingPlanoBanner(
            file: _controller.pendingPlanoFile!,
            fileName: _controller.pendingPlanoName!,
            onTap: () {},
            onDismiss: _dismissPlanoAttachment,
          ),
        if (exhausted)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                const Text(
                  'Tu prueba se agotó. Crea una cuenta para seguir analizando planos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                TextButton(
                  onPressed: _openRegister,
                  child: const Text('Crear cuenta para continuar'),
                ),
              ],
            ),
          )
        else ...[
          DashboardAskBar(
            controller: _controller.messageController,
            onAttachTap: _controller.isLoadingPendingPlano ||
                    _controller.isAnalyzing
                ? null
                : _openAttachmentPicker,
            onSendTap: _send,
            isSending: _controller.isSending,
            hintText: _controller.hasPendingPlano
                ? 'Indica qué revisar en tu plano'
                : _controller.canAsk
                    ? 'Pregunta algo sobre tu plano'
                    : 'Adjunta un plano para analizarlo',
          ),
          TextButton(
            onPressed: _openRegister,
            child: const Text('Crear cuenta para continuar'),
          ),
        ],
      ],
    );
  }
}

class _GuestTopBar extends StatelessWidget {
  const _GuestTopBar({
    required this.analysesRemaining,
    required this.asksRemaining,
    required this.onBack,
  });

  final int analysesRemaining;
  final int asksRemaining;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Volver',
            icon: Icon(Icons.arrow_back_rounded, size: 24, color: iconColor),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prueba sin cuenta',
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Análisis restantes: $analysesRemaining  ·  '
                  'Preguntas restantes: $asksRemaining',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestMessagesList extends StatelessWidget {
  const _GuestMessagesList({
    required this.controller,
    required this.scrollController,
  });

  final GuestController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final pending = controller.pendingUserMessage;
    final showPending = pending != null;
    final showTyping = controller.isSending;
    final showPlano = showPending &&
        controller.displayPlanoName != null &&
        controller.displayPlanoName!.isNotEmpty;

    var itemCount = controller.messages.length;
    if (showPending) itemCount++;
    if (showTyping) itemCount++;

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < controller.messages.length) {
          return ChatMessageBubble(message: controller.messages[index]);
        }

        final pendingIndex = controller.messages.length;
        if (showPending && index == pendingIndex) {
          if (showPlano) {
            return UserPlanoMessageGroup(
              fileName: controller.displayPlanoName!,
              file: controller.displayPlanoFile,
              text: pending,
            );
          }
          return ChatMessageBubble(
            message: ChatMessage(
              id: -1,
              role: 'user',
              content: MessageContent(text: pending),
              createdAt: DateTime.now(),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TypingIndicatorBubble(),
            if (controller.isAnalyzing)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'Analizando plano…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
