import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/home_project_controller.dart';
import 'package:movil_architect/core/app_services.dart';
import 'package:movil_architect/core/utils/app_notifications.dart';
import 'package:movil_architect/core/utils/date_utils.dart';
import 'package:movil_architect/models/home_project_models.dart';
import 'package:movil_architect/views/home_projects/widgets/home_project_widgets.dart';
import 'package:movil_architect/views/shared/app_states.dart';
import 'package:movil_architect/views/shared/attachment_picker_sheet.dart';

class SectionDetailView extends StatefulWidget {
  const SectionDetailView({
    super.key,
    required this.projectId,
    required this.stageNumber,
    required this.sectionId,
    required this.controller,
  });

  final String projectId;
  final int stageNumber;
  final int sectionId;
  final HomeProjectDetailController controller;

  @override
  State<SectionDetailView> createState() => _SectionDetailViewState();
}

class _SectionDetailViewState extends State<SectionDetailView> {
  final _commentController = TextEditingController();
  List<HomeProjectComment>? _extraComments;
  int? _commentsTotal;

  HomeProjectSection? get _section =>
      widget.controller.project?.sectionById(widget.sectionId);

  int? get _currentUserId =>
      AppServices.instance.authService.currentUser?.id;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _changeStatus() async {
    if (!widget.controller.permissions.canEdit) return;
    final current = _section?.status ?? 'pending';
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Estado del apartado',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            for (final status in sectionStatusOptions)
              ListTile(
                title: Text(homeProjectStatusLabel(status)),
                trailing: status == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, status),
              ),
          ],
        ),
      ),
    );
    if (selected == null || selected == current || !mounted) return;

    final ok = await widget.controller.updateSectionStatus(
      sectionId: widget.sectionId,
      status: selected,
    );
    if (!mounted) return;
    AppNotifications.result(
      context,
      ok: ok,
      successMessage: 'Estado actualizado',
      errorMessage: widget.controller.actionError,
    );
  }

  Future<void> _upload() async {
    if (!widget.controller.permissions.canUpload) return;
    final pick = await showAttachmentPickerSheet(context);
    if (pick == null || !mounted) return;

    final file = pick.file;
    final size = await file.length();
    if (size > 25 * 1024 * 1024) {
      if (!mounted) return;
      AppNotifications.error(
        context,
        'El archivo supera el límite de 25 MB',
      );
      return;
    }

    final ok = await widget.controller.uploadDocument(
      stageNumber: widget.stageNumber,
      sectionId: widget.sectionId,
      file: file,
    );
    if (!mounted) return;
    AppNotifications.result(
      context,
      ok: ok,
      successMessage: 'Documento subido',
      errorMessage: widget.controller.actionError,
    );
  }

  Future<void> _openDoc(HomeProjectDocument doc) async {
    final error = await widget.controller.openDocument(doc);
    if (!mounted || error == null) return;
    AppNotifications.error(context, error);
  }

  Future<void> _deleteDoc(HomeProjectDocument doc) async {
    final canDelete = widget.controller.permissions.canDeleteDocuments ||
        widget.controller.permissions.canEdit;
    if (!canDelete) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('¿Eliminar "${doc.originalFilename}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await widget.controller.deleteDocument(doc.id);
    if (!mounted) return;
    AppNotifications.result(
      context,
      ok: ok,
      successMessage: 'Documento eliminado',
      errorMessage: widget.controller.actionError,
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final ok = await widget.controller.addComment(
      sectionId: widget.sectionId,
      body: text,
    );
    if (!mounted) return;
    if (ok) {
      _commentController.clear();
      setState(() {
        _extraComments = null;
        _commentsTotal = null;
      });
    }
    AppNotifications.result(
      context,
      ok: ok,
      successMessage: 'Comentario publicado',
      errorMessage: widget.controller.actionError,
    );
  }

  Future<void> _loadAllComments() async {
    final page = await widget.controller.loadAllComments(
      sectionId: widget.sectionId,
    );
    if (!mounted || page == null) return;
    setState(() {
      _extraComments = page.comments;
      _commentsTotal = page.total;
    });
  }

  Future<void> _deleteComment(HomeProjectComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await widget.controller.deleteComment(
      sectionId: widget.sectionId,
      commentId: comment.id,
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _extraComments = null;
        _commentsTotal = null;
      });
    }
    AppNotifications.result(
      context,
      ok: ok,
      successMessage: 'Comentario eliminado',
      errorMessage: widget.controller.actionError,
    );
  }

  bool _canDeleteComment(HomeProjectComment comment) {
    final permissions = widget.controller.permissions;
    if (permissions.canEdit) return true;
    if (!permissions.canComment) return false;
    final uid = _currentUserId;
    return uid != null && comment.userId == uid;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.isDisposed) {
          return const Scaffold(body: SizedBox.shrink());
        }
        final section = _section;
        final permissions = widget.controller.permissions;
        final canDeleteDocs =
            permissions.canDeleteDocuments || permissions.canEdit;
        final comments = _extraComments ?? section?.comments ?? const [];
        final commentsCount = _commentsTotal ?? section?.commentsCount ?? 0;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              section?.title ?? 'Apartado',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
          ),
          floatingActionButton: permissions.canUpload
              ? FloatingActionButton.extended(
                  onPressed: widget.controller.busy ? null : _upload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Subir archivo'),
                )
              : null,
          body: section == null
              ? AppErrorView(
                  message: 'No se encontró el apartado',
                  onRetry: () => widget.controller.load(refresh: true),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _extraComments = null;
                      _commentsTotal = null;
                    });
                    await widget.controller.load(refresh: true);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      if (widget.controller.busy)
                        const LinearProgressIndicator(minHeight: 2),
                      Row(
                        children: [
                          HomeStatusChip(status: section.status),
                          const Spacer(),
                          if (permissions.canEdit)
                            TextButton.icon(
                              onPressed:
                                  widget.controller.busy ? null : _changeStatus,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Cambiar estado'),
                            ),
                        ],
                      ),
                      if (section.description.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          section.description,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Text(
                        'Documentos',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (section.documents.isEmpty)
                        Text(
                          'Aún no hay documentos en este apartado.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        )
                      else
                        for (final doc in section.documents) ...[
                          Material(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              leading: Icon(
                                doc.isImage
                                    ? Icons.image_outlined
                                    : Icons.description_outlined,
                              ),
                              title: Text(
                                doc.originalFilename,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(_formatSize(doc.fileSize)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Abrir',
                                    onPressed: () => _openDoc(doc),
                                    icon: const Icon(Icons.open_in_new),
                                  ),
                                  if (canDeleteDocs)
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      onPressed: widget.controller.busy
                                          ? null
                                          : () => _deleteDoc(doc),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      const SizedBox(height: 28),
                      Text(
                        'Comentarios ($commentsCount)',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (comments.isEmpty)
                        Text(
                          'Sin comentarios todavía.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        )
                      else
                        for (final comment in comments) ...[
                          Material(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              title: Text(
                                comment.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comment.body),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatRelativeTime(comment.createdAt),
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: _canDeleteComment(comment)
                                  ? IconButton(
                                      tooltip: 'Eliminar',
                                      onPressed: widget.controller.busy
                                          ? null
                                          : () => _deleteComment(comment),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      if (commentsCount > comments.length) ...[
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _loadAllComments,
                          child: Text(
                            'Ver todos ($commentsCount)',
                          ),
                        ),
                      ],
                      if (permissions.canComment) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _commentController,
                          maxLength: 4000,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Escribe un comentario',
                            hintText: 'Puedes mencionar con @correo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed:
                                widget.controller.busy ? null : _sendComment,
                            icon: const Icon(Icons.send),
                            label: const Text('Enviar'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
