import 'package:flutter/material.dart';

class MessageLogController {
  final _messages = <String>[];
  final _listeners = <VoidCallback>[];

  List<String> get messages => List.unmodifiable(_messages);

  void add(String msg) {
    _messages.add(msg);
    for (final l in _listeners) {
      l();
    }
  }

  void addListener(VoidCallback cb) => _listeners.add(cb);
  void removeListener(VoidCallback cb) => _listeners.remove(cb);
}

class MessageLog extends StatefulWidget {
  final MessageLogController controller;
  const MessageLog({super.key, required this.controller});

  @override
  State<MessageLog> createState() => _MessageLogState();
}

class _MessageLogState extends State<MessageLog> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.controller.messages
            .map((m) => Text('• $m'))
            .toList(growable: false),
      ),
    );
  }
}
