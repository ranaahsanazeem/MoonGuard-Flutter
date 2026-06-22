import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../data/mg_models.dart";
import "../../data/moon_guard_repository.dart";
import "../../theme/app_colors.dart";
import "../../widgets/chat_keyword_scrubber.dart";

class ChildFamilyChat extends StatefulWidget {
  const ChildFamilyChat({super.key, required this.child});
  final ChildProfile child;

  @override
  State<ChildFamilyChat> createState() => _ChildFamilyChatState();
}

class _ChildFamilyChatState extends State<ChildFamilyChat> {
  final _t = TextEditingController();
  List<String> _kw = [];

  @override
  void initState() {
    super.initState();
    _t.addListener(_scrub);
    _loadKw();
  }

  @override
  void dispose() {
    _t.removeListener(_scrub);
    _t.dispose();
    super.dispose();
  }

  Future<void> _loadKw() async {
    final r = context.read<MoonGuardRepository>();
    final a = await r.listKeywordsForChild(widget.child);
    if (mounted) {
      setState(() {
        _kw = a.map((e) => e.keyword).toList();
      });
    }
  }

  void _scrub() {
    if (_kw.isEmpty) {
      return;
    }
    final s = scrubChatText(_t.text, _kw);
    if (s != _t.text) {
      _t.value = _t.value.copyWith(
        text: s,
        selection: TextSelection.collapsed(offset: s.length),
      );
    }
  }

  Future<void> _send() async {
    var text = _t.text.trim();
    if (text.isEmpty) {
      return;
    }
    text = scrubChatText(text, _kw);
    if (text.isEmpty || RegExp(r"^\*+$").hasMatch(text)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nothing safe to send after filtering.")),
        );
      }
      return;
    }
    final r = context.read<MoonGuardRepository>();
    final err = await r.sendTextMessage(widget.child.id, text);
    if (err == null) {
      _t.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.read<MoonGuardRepository>();
    final me = Supabase.instance.client.auth.currentUser?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Family chat", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 4),
        if (_kw.isNotEmpty) const Text("Blocked words are masked with * as you type.", style: TextStyle(color: AppColors.muted, fontSize: 11)),
        const SizedBox(height: 6),
        SizedBox(
          height: 200,
          child: StreamBuilder<List<ChatMessage>>(
            stream: r.messageStream(widget.child.id),
            builder: (context, s) {
              if (s.hasError) {
                return Center(child: Text("Chat: ${s.error}"));
              }
              final msgs = s.data ?? <ChatMessage>[];
              if (msgs.isEmpty) {
                return const Center(child: Text("No messages yet.", style: TextStyle(color: AppColors.muted)));
              }
              return ListView.builder(
                itemCount: msgs.length,
                itemBuilder: (ctx, i) {
                  final m = msgs[i];
                  final isMe = m.senderUserId == me;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFE8F5E9) : const Color(0xFFEDE7E3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(m.body ?? "", style: const TextStyle(fontSize: 14)),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _t,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: "Message…",
                  filled: true,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            FilledButton(onPressed: _send, child: const Icon(Icons.send, size: 20)),
          ],
        ),
      ],
    );
  }
}
