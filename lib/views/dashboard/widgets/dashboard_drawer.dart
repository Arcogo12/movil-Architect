import 'package:flutter/material.dart';
import 'package:movil_architect/controllers/dashboard_controller.dart';
import 'package:movil_architect/core/utils/date_utils.dart';
import 'package:movil_architect/models/chat_models.dart';

class DashboardDrawer extends StatefulWidget {
  const DashboardDrawer({
    super.key,
    required this.controller,
    required this.onNewChat,
    required this.onSettings,
    required this.onChatOpen,
    required this.onStageAdmin,
    this.isStageAdminActive = false,
  });

  final DashboardController controller;
  final VoidCallback onNewChat;
  final VoidCallback onSettings;
  final ValueChanged<String> onChatOpen;
  final VoidCallback onStageAdmin;
  final bool isStageAdminActive;

  @override
  State<DashboardDrawer> createState() => _DashboardDrawerState();
}

class _DashboardDrawerState extends State<DashboardDrawer> {
  final _searchController = TextEditingController();
  String? _selectedChatId;
  String? _selectedProjectId;
  bool _chatsExpanded = true;
  bool _stagesExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatSummary> get _filteredChats {
    final query = _searchController.text.trim().toLowerCase();
    final items = widget.controller.chats;
    if (query.isEmpty) return items;
    return items
        .where((item) => item.title.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _confirmDelete(ChatSummary chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: Text('¿Borrar "${chat.title}"?'),
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

    try {
      await widget.controller.deleteChat(chat.id);
      if (_selectedChatId == chat.id) _selectedChatId = null;
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la conversación')),
      );
    }
  }

  void _openChat(ChatSummary chat) {
    setState(() => _selectedChatId = chat.id);
    Navigator.of(context).pop();
    widget.onChatOpen(chat.id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final drawerColor = colorScheme.brightness == Brightness.dark
        ? colorScheme.surface
        : const Color(0xFFEFEFEF);

    return Drawer(
      backgroundColor: drawerColor,
      width: MediaQuery.sizeOf(context).width * 0.88,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final user = widget.controller.user;
            final planName =
                widget.controller.subscription?.plan.name ?? 'Plan';
            final chats = _filteredChats;
            final projects = widget.controller.projects;
            if (_selectedChatId == null && chats.isNotEmpty) {
              _selectedChatId = chats.first.id;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Text(
                    'ARCHITECT',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _SearchField(controller: _searchController),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _NewChatButton(
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onNewChat();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _StageAdminModule(
                    selected: widget.isStageAdminActive,
                    onTap: () {
                      setState(() => _stagesExpanded = true);
                      Navigator.of(context).pop();
                      widget.onStageAdmin();
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => widget.controller.load(refresh: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                      children: [
                        _CollapsibleHistoryHeader(
                          title: 'RECIENTES',
                          count: chats.length,
                          expanded: _chatsExpanded,
                          onTap: () =>
                              setState(() => _chatsExpanded = !_chatsExpanded),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: chats.isEmpty
                                ? _HistoryEmptyMessage(
                                    message:
                                        'No hay chats recientes.\nInicia uno con + Nuevo chat.',
                                  )
                                : Column(
                                    children: [
                                      for (final item in chats)
                                        _ChatHistoryTile(
                                          title: item.title,
                                          subtitle: formatRelativeTime(
                                            item.updatedAt,
                                          ),
                                          badge: '${item.messageCount}',
                                          selected: item.id == _selectedChatId,
                                          onTap: () => _openChat(item),
                                          onMore: item.id == _selectedChatId
                                              ? () => _showChatMenu(item)
                                              : null,
                                        ),
                                    ],
                                  ),
                          ),
                          crossFadeState: _chatsExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                          sizeCurve: Curves.easeInOut,
                        ),
                        const SizedBox(height: 8),
                        _CollapsibleHistoryHeader(
                          title: 'HISTORIAL DE ETAPAS',
                          count: projects.length,
                          expanded: _stagesExpanded,
                          onTap: () => setState(
                            () => _stagesExpanded = !_stagesExpanded,
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: projects.isEmpty
                                ? const _HistoryEmptyMessage(
                                    message:
                                        'Aún no hay proyectos.\nCrea uno desde Administración de etapas.',
                                  )
                                : Column(
                                    children: [
                                      for (final project in projects)
                                        _ProjectHistoryTile(
                                          title: project.name,
                                          subtitle:
                                              '${project.client} · ${project.location}',
                                          selected:
                                              project.id == _selectedProjectId,
                                          onTap: () {
                                            setState(
                                              () => _selectedProjectId =
                                                  project.id,
                                            );
                                            Navigator.of(context).pop();
                                            widget.onStageAdmin();
                                          },
                                        ),
                                    ],
                                  ),
                          ),
                          crossFadeState: _stagesExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                          sizeCurve: Curves.easeInOut,
                        ),
                      ],
                    ),
                  ),
                ),
                _DrawerUserFooter(
                  name: user?.fullName.isNotEmpty == true
                      ? user!.fullName
                      : user?.email ?? 'Usuario',
                  planLabel: 'Plan $planName',
                  onSettings: () {
                    Navigator.of(context).pop();
                    widget.onSettings();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showChatMenu(ChatSummary chat) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Abrir conversación'),
              onTap: () {
                Navigator.pop(context);
                _openChat(chat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Eliminar conversación',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(chat);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFE4E4E6);

    return TextField(
      controller: controller,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Buscar chats',
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(
          Icons.search,
          color: colorScheme.onSurfaceVariant,
          size: 22,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final bgColor = isDark ? colorScheme.onSurface : Colors.black;
    final fgColor = isDark ? colorScheme.surface : Colors.white;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: fgColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Nuevo chat',
                style: TextStyle(
                  color: fgColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageAdminModule extends StatelessWidget {
  const _StageAdminModule({
    required this.onTap,
    this.selected = false,
  });

  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFE4E4E6);
    final selectedColor = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHigh
        : Colors.white;

    return Material(
      color: selected ? selectedColor : fillColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            'Administración de etapas',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsibleHistoryHeader extends StatelessWidget {
  const _CollapsibleHistoryHeader({
    required this.title,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryEmptyMessage extends StatelessWidget {
  const _HistoryEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

class _ProjectHistoryTile extends StatelessWidget {
  const _ProjectHistoryTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? selectedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.apartment_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
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

class _ChatHistoryTile extends StatelessWidget {
  const _ChatHistoryTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.selected,
    required this.onTap,
    this.onMore,
  });

  final String title;
  final String subtitle;
  final String badge;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? selectedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (onMore != null)
                  IconButton(
                    onPressed: onMore,
                    icon: Icon(
                      Icons.more_horiz,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerUserFooter extends StatelessWidget {
  const _DrawerUserFooter({
    required this.name,
    required this.planLabel,
    required this.onSettings,
  });

  final String name;
  final String planLabel;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final isDark = colorScheme.brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainerHighest
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Material(
        color: cardColor,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.surfaceContainerHigh,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      planLabel,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSettings,
                icon: Icon(
                  Icons.settings_outlined,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
