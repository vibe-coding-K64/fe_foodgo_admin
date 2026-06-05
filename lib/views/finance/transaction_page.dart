import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/admin_transaction_api_service.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final AdminTransactionApiService _apiService = AdminTransactionApiService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTransactions = [];
  String? _errorMessage;
  String _filter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Tiền vào', 'Tiền ra'];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.getAllTransactions();
      setState(() {
        _allTransactions = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải lịch sử giao dịch: $e';
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    List<Map<String, dynamic>> list = _allTransactions;
    if (_filter == 'Tiền vào') {
      list = list.where((t) {
        final typeVal = t['type'];
        return typeVal != 3 && typeVal != 5;
      }).toList();
    } else if (_filter == 'Tiền ra') {
      list = list.where((t) {
        final typeVal = t['type'];
        return typeVal == 3 || typeVal == 5;
      }).toList();
    }
    return list;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is String) {
      final parsed = DateTime.tryParse(timestamp);
      if (parsed != null) {
        return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
      }
    } else if (timestamp is int) {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal());
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Icons.receipt_long_outlined,
                    color: Color(0xFFFF6B35),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lịch sử giao dịch', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                    SizedBox(height: 4),
                    Text('Sao kê chi tiết tất cả giao dịch trong ví', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: _loadTransactions,
              icon: const Icon(Icons.refresh, color: Color(0xFFFF6B35)),
              tooltip: 'Làm mới dữ liệu',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shadowColor: Colors.black.withOpacity(0.05),
                elevation: 2,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
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
                      SizedBox(width: 160, child: Text('Thời gian', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 120, child: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 140, child: Text('Số tiền', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                                  const SizedBox(height: 12),
                                  Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadTransactions,
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                                    child: const Text('Thử lại'),
                                  ),
                                ],
                              ),
                            )
                          : _filtered.isEmpty
                              ? const Center(child: Text('Chưa có giao dịch nào.'))
                              : ListView.separated(
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
    final typeVal = tx['type'];
    final bool isCredit = typeVal != 3 && typeVal != 5;
    
    // Amount formatting
    final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final amtText = NumberFormat("#,###").format(amount);

    // Status mapping
    final int statusVal = tx['status'] ?? 0;
    String statusText = 'Chờ duyệt';
    Color statusColor = Colors.orange;
    if (statusVal == 1) {
      statusText = 'Thành công';
      statusColor = Colors.green;
    } else if (statusVal == 2) {
      statusText = 'Bị từ chối';
      statusColor = Colors.red;
    }

    // Time formatting
    final String timeStr = _formatDate(tx['createdAt']);
    final String desc = tx['description'] ?? 'Giao dịch';

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                const SizedBox(height: 4),
                if (tx['userId'] != null)
                  Text('Đối tác: ${tx['userId']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(width: 160, child: Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12))),
          
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

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
