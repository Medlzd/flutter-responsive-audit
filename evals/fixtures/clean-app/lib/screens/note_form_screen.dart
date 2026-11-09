import 'package:flutter/material.dart';

import '../core/breakpoints.dart';

class NoteFormScreen extends StatelessWidget {
  const NoteFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New note')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
            child: ListView(
              padding: const EdgeInsetsDirectional.all(16),
              children: [
                const TextField(
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(labelText: 'Content'),
                  minLines: 4,
                  maxLines: null,
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Save'),
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
