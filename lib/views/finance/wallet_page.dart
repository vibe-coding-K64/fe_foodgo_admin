import 'package:flutter/material.dart';

class WalletPage extends StatelessWidget {
  final Function(String)? onNavigate;
  const WalletPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFFFF6B35),
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ví doanh thu', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                    SizedBox(height: 4),
                    Text('Quản lý số dư và theo dõi dòng tiền', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Balance card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng số dư khả dụng', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                const Text('12.450.000đ', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _walletStat('Tháng này', '+3.200.000đ', Icons.trending_up),
                    const SizedBox(width: 32),
                    _walletStat('Đang chờ', '850.000đ', Icons.hourglass_empty_outlined),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (onNavigate != null) onNavigate!('/finance/withdrawal');
                      },
                      icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                      label: const Text('Rút tiền'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B35),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Quick stats
          Row(
            children: [
              Expanded(child: _statCard('Doanh thu hôm nay', '1.250.000đ', Icons.today_outlined, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _statCard('Đơn hoàn thành', '14', Icons.check_circle_outline, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _statCard('Rút gần nhất', '5.000.000đ', Icons.arrow_upward_outlined, Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          // Recent transactions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Giao dịch gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                    TextButton(
                      onPressed: () {
                        if (onNavigate != null) onNavigate!('/finance/transactions');
                      },
                      child: const Text('Xem tất cả', style: TextStyle(color: Color(0xFFFF6B35))),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ...[
                  {'type': 'credit', 'desc': 'Đơn hàng #OD-001 hoàn thành', 'amount': '+89.000đ', 'time': '14:23 hôm nay'},
                  {'type': 'credit', 'desc': 'Đơn hàng #OD-002 hoàn thành', 'amount': '+130.000đ', 'time': '13:40 hôm nay'},
                  {'type': 'debit', 'desc': 'Rút tiền về Vietcombank', 'amount': '-2.000.000đ', 'time': '10:00 hôm nay'},
                  {'type': 'credit', 'desc': 'Đơn hàng #OD-003 hoàn thành', 'amount': '+215.000đ', 'time': 'Hôm qua'},
                ].map((tx) => _transactionRow(tx)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E1E2D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionRow(Map<String, dynamic> tx) {
    final isCredit = tx['type'] == 'credit';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.green : Colors.red, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['desc'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Text(tx['time'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(tx['amount'],
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : Colors.red,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
