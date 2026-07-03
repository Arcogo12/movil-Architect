import 'dart:io';

import 'package:flutter/material.dart';

bool isPlanoImageFile(String name) {
  final ext = name.split('.').last.toLowerCase();
  return ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp';
}

class PendingPlanoLoadingBanner extends StatelessWidget {
  const PendingPlanoLoadingBanner({
    super.key,
    required this.fileName,
    required this.progress,
    this.onCancel,
  });

  final String fileName;
  final double progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final percent = (progress * 100).clamp(0, 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Material(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: progress > 0 ? progress : null,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cargando plano…',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress > 0 ? progress : null,
                        minHeight: 5,
                        backgroundColor: colorScheme.surfaceContainerHigh,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percent%',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onCancel != null)
                IconButton(
                  onPressed: onCancel,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Cancelar',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PendingPlanoBanner extends StatelessWidget {
  const PendingPlanoBanner({
    super.key,
    required this.file,
    required this.fileName,
    required this.onTap,
    required this.onDismiss,
  });

  final File file;
  final String fileName;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final isImage = isPlanoImageFile(fileName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Material(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: isImage
                        ? Image.file(file, fit: BoxFit.cover)
                        : ColoredBox(
                            color: colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.description_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu plano',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Escribe abajo y envía para analizar',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Quitar plano',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardTopBar extends StatelessWidget {  const DashboardTopBar({
    super.key,
    required this.onMenuTap,
    this.onNewChatTap,
  });

  final VoidCallback onMenuTap;
  final VoidCallback? onNewChatTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            icon: Icon(Icons.menu_rounded, size: 26, color: iconColor),
          ),
          const Spacer(),
          IconButton(
            onPressed: onNewChatTap,
            tooltip: 'Nuevo chat',
            icon: Icon(Icons.edit_outlined, size: 24, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class DashboardHero extends StatelessWidget {
  const DashboardHero({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        '¿Qué plano revisamos hoy?',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

class DashboardAskBar extends StatefulWidget {
  const DashboardAskBar({
    super.key,
    required this.controller,
    this.onAttachTap,
    this.onSendTap,
    this.isSending = false,
    this.hintText = 'Pregunta algo sobre tu plano',
  });

  final TextEditingController controller;
  final VoidCallback? onAttachTap;
  final VoidCallback? onSendTap;
  final bool isSending;
  final String hintText;

  @override
  State<DashboardAskBar> createState() => _DashboardAskBarState();
}

class _DashboardAskBarState extends State<DashboardAskBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _focusField() {
    if (widget.isSending) return;
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final barColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.95)
        : const Color(0xF0FFFFFF);

    return Container(
      height: 56,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.25 : 0.09),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onAttachTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.attach_file_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 23,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _focusField,
              child: TextField(
                focusNode: _focusNode,
                controller: widget.controller,
                enabled: !widget.isSending,
                readOnly: false,
                enableInteractiveSelection: true,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: widget.isSending
                    ? null
                    : (_) => widget.onSendTap?.call(),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isSending ? null : widget.onSendTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.onSurface : Colors.black,
                  shape: BoxShape.circle,
                ),
                child: widget.isSending
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark
                              ? colorScheme.surface
                              : Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        color: isDark ? colorScheme.surface : Colors.white,
                        size: 26,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
