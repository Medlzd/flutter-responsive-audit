import 'package:flutter/material.dart';

import '../core/breakpoints.dart';
import 'note_form_screen.dart';
import 'notes_list_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  /// Keeps the tab states (scroll, text fields) when the layout switches
  /// between bottom navigation and the rail (rotation, fold, window resize).
  final _bodyKey = GlobalKey();

  static const _destinations = [
    (icon: Icons.notes_outlined, selected: Icons.notes, label: 'Notes'),
    (icon: Icons.edit_outlined, selected: Icons.edit, label: 'New'),
  ];

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= Breakpoints.medium;

    final body = IndexedStack(
      key: _bodyKey,
      index: _index,
      children: const [
        NotesListScreen(key: PageStorageKey('notes')),
        NoteFormScreen(key: PageStorageKey('form')),
      ],
    );

    return Scaffold(
      // Horizontal insets (landscape notch) are consumed once here, so the
      // rail and the pages below do not apply them a second time.
      body: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            if (useRail) ...[
              SafeArea(
                child: NavigationRail(
                  selectedIndex: _index,
                  extended: width >= Breakpoints.expanded,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selected),
                        label: Text(d.label),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
            ],
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selected),
                    label: d.label,
                  ),
              ],
            ),
    );
  }
}
