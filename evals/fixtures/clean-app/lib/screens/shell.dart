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

  static const _destinations = [
    (icon: Icons.notes_outlined, selected: Icons.notes, label: 'Notes'),
    (icon: Icons.edit_outlined, selected: Icons.edit, label: 'New'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= Breakpoints.medium;

    final body = IndexedStack(
      index: _index,
      children: const [
        NotesListScreen(key: PageStorageKey('notes')),
        NoteFormScreen(key: PageStorageKey('form')),
      ],
    );

    if (!useRail) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
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

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              selectedIndex: _index,
              extended: width >= Breakpoints.expanded,
              onDestinationSelected: (i) => setState(() => _index = i),
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
          Expanded(child: body),
        ],
      ),
    );
  }
}
