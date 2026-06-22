import "package:flutter/material.dart";

import "../../../../data/mg_models.dart";
import "../../../../theme/app_colors.dart";

class ChatMessageBubbleContent extends StatelessWidget {
  const ChatMessageBubbleContent({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final m = message;
    switch (m.messageType) {
      case "image":
      case "video":
        if (m.storagePath != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(m.messageType == "video" ? Icons.videocam : Icons.image, color: AppColors.muted, size: 20),
              Text(m.messageType, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              const Text("Stored", style: TextStyle(fontSize: 12, color: AppColors.text)),
            ],
          );
        }
        return const Text("—");
      default:
        return Text(m.body ?? "", style: const TextStyle(fontSize: 15));
    }
  }
}
