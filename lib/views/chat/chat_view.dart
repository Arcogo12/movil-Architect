import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/chat_controller.dart';
import 'package:movil_architect/core/theme/app_colors.dart';
import 'package:movil_architect/views/chat/widgets/chat_messages_list.dart';
import 'package:movil_architect/views/login/widgets/login_widgets.dart';
import 'package:movil_architect/views/shared/app_states.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.chatId});

  final String chatId;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final ChatController _controller;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ChatController(chatId: widget.chatId);
    _controller.load().then((_) => _scrollToBottom());
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

  Future<void> _refreshChat() async {
    await _controller.load(showLoading: false);
    _scrollToBottom();
  }

  Future<void> _send() async {
    _scrollToBottom();
    await _controller.sendMessage();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppBar(
        backgroundColor: AppColors.dashboardSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Text(
            _controller.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.state == ChatState.loading) {
            return const AppLoadingView(message: 'Cargando conversación...');
          }

          if (_controller.state == ChatState.error) {
            return AppErrorView(
              message: _controller.errorMessage ?? 'Error al cargar el chat',
              onRetry: () => _controller.load().then((_) => _scrollToBottom()),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ChatMessagesList(
                  controller: _controller,
                  scrollController: _scrollController,
                  onRefresh: _refreshChat,
                ),
              ),
              if (_controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _controller.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: LoginPillField(
                          controller: _controller.messageController,
                          hint: 'ESCRIBE TU MENSAJE',
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: FilledButton(
                          onPressed: _controller.isSending ? null : _send,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          child: _controller.isSending
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
