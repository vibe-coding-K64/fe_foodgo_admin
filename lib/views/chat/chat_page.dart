import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  int _selectedChat = 0;
  final _messageCtrl = TextEditingController();

  final List<Map<String, dynamic>> _chatList = [
    {'customer': 'Nguyễn Văn A', 'order': 'OD-001', 'lastMsg': 'Bao giờ giao tới vậy bạn?', 'time': '14:23', 'unread': 2},
    {'customer': 'Trần Thị B', 'order': 'OD-002', 'lastMsg': 'Cảm ơn quán nhé!', 'time': '13:15', 'unread': 0},
    {'customer': 'Lê Văn C', 'order': 'OD-003', 'lastMsg': 'Cho mình đổi sang ít đá được không?', 'time': '12:40', 'unread': 1},
  ];

  final List<Map<String, dynamic>> _messages = [
    {'sender': 'customer', 'text': 'Xin chào quán ơi!', 'time': '14:10'},
    {'sender': 'merchant', 'text': 'Chào bạn! Quán có thể giúp gì ạ?', 'time': '14:11'},
    {'sender': 'customer', 'text': 'Bao giờ giao tới vậy bạn?', 'time': '14:23'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFFFF6B35),
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chat với khách hàng', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                  SizedBox(height: 4),
                  Text('Nhắn tin trực tiếp với khách về đơn hàng', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            children: [
              // Chat list
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          isDense: true,
                          filled: true,
                          fillColor: Color(0xFFF8F9FA),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _chatList.length,
                        itemBuilder: (context, i) => _buildChatItem(i),
                      ),
                    ),
                  ],
                ),
              ),
              // Chat window
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Chat header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(topRight: Radius.circular(16)),
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFFFF3E0),
                              child: Text(_chatList[_selectedChat]['customer'].toString()[0],
                                  style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_chatList[_selectedChat]['customer'],
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Đơn hàng: ${_chatList[_selectedChat]['order']}',
                                    style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Messages
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) => _buildMessage(_messages[i]),
                        ),
                      ),
                      // Input
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Row(
                          children: [
                            IconButton(onPressed: () {}, icon: const Icon(Icons.image_outlined, color: Colors.grey)),
                            Expanded(
                              child: TextField(
                                controller: _messageCtrl,
                                decoration: InputDecoration(
                                  hintText: 'Nhập tin nhắn...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  isDense: true,
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FA),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _sendMessage,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatItem(int index) {
    final chat = _chatList[index];
    final isSelected = _selectedChat == index;
    return InkWell(
      onTap: () => setState(() => _selectedChat = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? const Color(0xFFFFF3E0) : Colors.transparent,
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFFF6B35).withOpacity(0.2),
              child: Text(chat['customer'].toString()[0],
                  style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat['customer'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(chat['lastMsg'],
                      style: TextStyle(color: (chat['unread'] as int) > 0 ? const Color(0xFF1E1E2D) : Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(chat['time'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                if ((chat['unread'] as int) > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                    child: Center(child: Text('${chat['unread']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMe = msg['sender'] == 'merchant';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFFF3E0),
              child: Text(_chatList[_selectedChat]['customer'].toString()[0],
                  style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFFF6B35) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(msg['text'], style: TextStyle(color: isMe ? Colors.white : const Color(0xFF1E1E2D), fontSize: 13)),
                const SizedBox(height: 4),
                Text(msg['time'], style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageCtrl.text.isNotEmpty) {
      setState(() {
        _messages.add({'sender': 'merchant', 'text': _messageCtrl.text, 'time': '14:30'});
        _messageCtrl.clear();
      });
    }
  }
}
