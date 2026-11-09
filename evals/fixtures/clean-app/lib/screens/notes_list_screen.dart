import 'package:flutter/material.dart';

import '../core/breakpoints.dart';

class Note {
  const Note(this.title, this.excerpt);
  final String title;
  final String excerpt;
}

const _notes = [
  Note('Groceries', 'Milk, eggs, bread, coffee beans, olive oil'),
  Note('Meeting notes', 'Discuss the Q3 roadmap and the hiring plan'),
  Note('Ideas', 'A small app to track houseplant watering'),
];

class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: SafeArea(
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
            child: ListView.separated(
              key: const PageStorageKey('notes-list'),
              padding: const EdgeInsetsDirectional.all(16),
              itemCount: _notes.length,
              separatorBuilder: (context, i) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _NoteTile(note: _notes[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Height is driven by the content, so larger text sizes grow the tile
    // instead of clipping it.
    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.excerpt,
                    style: textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.adaptive.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}
