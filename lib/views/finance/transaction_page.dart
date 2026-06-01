import 'package:flutter/material.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String _filter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Tiền vào', 'Tiền ra'];

  final List<Map<String, dynamic>> _transactions = [
    {'type': 'credit', 'desc': 'Đơn hàng #OD-001 hoàn thành', 'amount': 89000, 'time': '14:23 18/05/2025', 'reason': 'Doanh thu đơn hàng'},
    {'type': 'credit', 'desc': 'Đơn hàng #OD-002 hoàn thành', 'amount': 130000, 'time': '13:40 18/05/2025', 'reason': 'Doanh thu đơn hàng'},
    {'type': 'debit', 'desc': 'Rút tiền về Vietcombank', 'amount': 2000000, 'time': '10:00 18/05/2025', 'reason': 'Yêu cầu rút tiền #W-045'},
    {'type': 'credit', 'desc': 'Đơn hàng #OD-003 hoàn thành', 'amount': 215000, 'time': '09:12 17/05/2025', 'reason': 'Doanh thu đơn hàng'},
    {'type': 'debit', 'desc': 'Rút tiền về Vietcombank', 'amount': 5000000, 'time': '08:00 15/05/2025', 'reason': 'Yêu cầu rút tiền #W-044'},
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'Tiền vào') return _transactions.where((t) => t['type'] == 'credit').toList();
    if (_filter == 'Tiền ra') return _transactions.where((t) => t['type'] == 'debit').toList();
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lịch sử Giao dịch', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
        const SizedBox(height: 4),
        const Text('Sao kê chi tiết tất cả giao dịch trong ví', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
                selectedColor: const Color(0xFFFF6B35),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w500),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade300)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 48),
                      Expanded(child: Text('Nội dung', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 200, child: Text('Thời gian', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 160, child: Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 140, child: Text('Số tiền', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, i) => _buildRow(_filtered[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(Map<String, dynamic> tx) {
    final isCredit = tx['type'] == 'credit';
    final amt = tx['amount'] as int;
    final amtText = amt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: Icon(isCredit ? Icons.south_west : Icons.north_east,
                color: isCredit ? Colors.green : Colors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(tx['desc'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          SizedBox(width: 200, child: Text(tx['time'], style: const TextStyle(color: Colors.grey, fontSize: 12))),
          SizedBox(width: 160, child: Text(tx['reason'], style: const TextStyle(color: Colors.grey, fontSize: 12))),
          SizedBox(
            width: 140,
            child: Text(
              '${isCredit ? '+' : '-'}$amtText đ',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : Colors.red,
                  fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
