import 'package:flutter/material.dart';

class ReportTicketsPage extends StatefulWidget {
  const ReportTicketsPage({super.key});

  @override
  State<ReportTicketsPage> createState() => _ReportTicketsPageState();
}

class _ReportTicketsPageState extends State<ReportTicketsPage> {
  String _filter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Mở', 'Đang xử lý', 'Đã giải quyết'];
  final List<Map<String, dynamic>> _tickets = [
    {'id': 'RT-001', 'order': 'OD-002', 'customer': 'Trần Thị B', 'reason': 'Thiếu món', 'desc': 'Đơn hàng thiếu 1 ly nước cam tươi', 'status': 'Mở', 'date': '18/05/2025'},
    {'id': 'RT-002', 'order': 'OD-003', 'customer': 'Lê Văn C', 'reason': 'Món hư hỏng', 'desc': 'Burger bị nguội lạnh khi giao đến', 'status': 'Đang xử lý', 'date': '17/05/2025'},
    {'id': 'RT-003', 'order': 'OD-001', 'customer': 'Nguyễn Văn A', 'reason': 'Giao sai món', 'desc': 'Nhận được burger bò thay vì burger gà', 'status': 'Đã giải quyết', 'date': '15/05/2025'},
  ];

  List<Map<String, dynamic>> get _filtered => _filter == 'Tất cả'
      ? _tickets
      : _tickets.where((t) => t['status'] == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Khiếu nại từ Khách', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
        const SizedBox(height: 4),
        const Text('Xem và theo dõi các khiếu nại liên quan đến quán', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 20),
        Row(
          children: _filters.map((f) {
            final isSelected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f),
                selected: isSelected,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: _filterColor(f),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w500),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? _filterColor(f) : Colors.grey.shade300)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _buildTicketCard(_filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'] as String;
    final statusColor = _statusColor(status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ticket['id'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E1E2D))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(ticket['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _badge(Icons.shopping_bag_outlined, 'Đơn: ${ticket['order']}', Colors.blue),
              const SizedBox(width: 8),
              _badge(Icons.person_outline, ticket['customer'], Colors.purple),
              const SizedBox(width: 8),
              _badge(Icons.report_outlined, ticket['reason'], Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          Text(ticket['desc'], style: const TextStyle(fontSize: 14, color: Color(0xFF1E1E2D), height: 1.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'Mở' || status == 'Đang xử lý')
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Đánh dấu đã giải quyết'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Mở': return Colors.orange;
      case 'Đang xử lý': return Colors.blue;
      case 'Đã giải quyết': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _filterColor(String f) {
    switch (f) {
      case 'Mở': return Colors.orange;
      case 'Đang xử lý': return Colors.blue;
      case 'Đã giải quyết': return Colors.green;
      default: return const Color(0xFFFF6B35);
    }
  }
}
