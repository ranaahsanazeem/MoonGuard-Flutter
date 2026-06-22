import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../../../data/mg_models.dart";
import "../../../../data/moon_guard_repository.dart";
import "../../../../theme/app_colors.dart";
import "../../widgets/parent_empty_state.dart";
import "chat_message_bubble.dart";
import "chat_tab_controller.dart";

class ParentChatTab extends StatefulWidget {
  const ParentChatTab({super.key, required this.children});
  final List<ChildProfile> children;

  @override
  State<ParentChatTab> createState() => _ParentChatTabState();
}

class _ParentChatTabState extends State<ParentChatTab> {
  @override
  void initState() {
    super.initState();
    Get.put(ChatTabController(children: List.from(widget.children)), tag: kParentChatControllerTag);
  }

  @override
  void didUpdateWidget(covariant ParentChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    Get.find<ChatTabController>(tag: kParentChatControllerTag).syncChildren(widget.children);
  }

  @override
  void dispose() {
    Get.delete<ChatTabController>(tag: kParentChatControllerTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.read<MoonGuardRepository>();
    if (widget.children.isEmpty) {
      return const ParentEmptyState("Add a child to start chat.", icon: Icons.forum_outlined);
    }
    return GetBuilder<ChatTabController>(
      tag: kParentChatControllerTag,
      builder: (c) {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DropdownButtonFormField<String>(
                initialValue: c.selectedChildId,
                decoration: const InputDecoration(labelText: "Chat with", filled: true, fillColor: AppColors.card),
                items: [for (final ch in c.children) DropdownMenuItem(value: ch.id, child: Text(ch.name))],
                onChanged: (v) async {
                  if (v != null) {
                    await c.setChild(v);
                  }
                },
              ),
            ),
            Obx(
              () {
                if (c.keywords.isEmpty) {
                  return const SizedBox.shrink();
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    "Family chat: blocked words are replaced with * as you type.",
                    style: TextStyle(color: AppColors.muted, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: c.selectedChildId == null
                  ? const Center(child: Text("—"))
                  : StreamBuilder<List<ChatMessage>>(
                      stream: r.messageStream(c.selectedChildId!),
                      builder: (context, s) {
                        if (s.hasError) {
                          return Center(child: Text("Error: ${s.error}"));
                        }
                        final msgs = s.data ?? <ChatMessage>[];
                        if (s.connectionState == ConnectionState.waiting && msgs.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text("Loading…", style: TextStyle(color: AppColors.muted)),
                            ),
                          );
                        }
                        if (msgs.isEmpty) {
                          return const Center(
                            child: Text("No messages yet.", style: TextStyle(color: AppColors.muted)),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: msgs.length,
                          itemBuilder: (ctx, i) {
                            final m = msgs[i];
                            final me = m.senderUserId == uid;
                            return Align(
                              alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                constraints: const BoxConstraints(maxWidth: 280),
                                decoration: BoxDecoration(
                                  color: me ? const Color(0xFFE8F5E9) : const Color(0xFFEDE7E3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ChatMessageBubbleContent(message: m),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: c.selectedChildId == null
                          ? null
                          : () async {
                              final f = await FilePicker.platform.pickFiles(
                                withData: true,
                                type: FileType.image,
                                allowMultiple: false,
                              );
                              if (f == null || f.files.isEmpty) {
                                return;
                              }
                              final x = f.files.first;
                              final b = x.bytes;
                              if (b == null) {
                                return;
                              }
                              if (!context.mounted) {
                                return;
                              }
                              final e = await r.sendImageOrVideo(
                                c.selectedChildId!,
                                b,
                                x.name,
                              );
                              if (e != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
                              }
                            },
                      icon: const Icon(Icons.image_outlined, color: AppColors.primary),
                    ),
                    Expanded(
                      child: TextField(
                        controller: c.messageController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: "Message…",
                          filled: true,
                          fillColor: AppColors.card,
                        ),
                        onSubmitted: (_) => c.sendMessage(context),
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.all(12),
                        shape: const CircleBorder(),
                      ),
                      onPressed: c.selectedChildId == null ? null : () => c.sendMessage(context),
                      child: const Icon(Icons.send, size: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
