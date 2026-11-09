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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 360).floor().clamp(1, 3);
            return Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Breakpoints.maxContentWidth * 1.5,
                ),
                child: GridView.builder(
                  key: const PageStorageKey('notes-grid'),
                  padding: const EdgeInsetsDirectional.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 120,
                  ),
                  itemCount: _notes.length,
                  itemBuilder: (context, i) => _NoteTile(note: _notes[i]),
                ),
              ),
            );
          },
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
                  Flexible(
                    child: Text(
                      note.excerpt,
                      style: textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
