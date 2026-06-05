import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/admin_transaction_api_service.dart';

class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({super.key});

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  final AdminTransactionApiService _apiService = AdminTransactionApiService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingWithdrawals = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.getPendingWithdrawals();
      setState(() {
        _pendingWithdrawals = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách yêu cầu rút tiền: $e';
      });
    }
  }

  Future<void> _approve(String id) async {
    // Show confirming indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
    );

    try {
      final success = await _apiService.approveWithdrawal(id);
      Navigator.pop(context); // close loading dialog
      
      if (success) {
        _showToast('Đã duyệt yêu cầu rút tiền thành công!', Colors.green);
        _loadWithdrawals();
      }
    } catch (e) {
      Navigator.pop(context); // close loading dialog
      _showToast('Lỗi khi duyệt yêu cầu: $e', Colors.red);
    }
  }

  Future<void> _reject(String id) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối yêu cầu rút tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng nhập lý do từ chối yêu cầu rút tiền này:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'VD: Sai thông tin ngân hàng thụ hưởng',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (result == null) return; // cancelled

    // Show processing loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
    );

    try {
      final success = await _apiService.rejectWithdrawal(id, result.isEmpty ? 'Yêu cầu rút tiền không hợp lệ' : result);
      Navigator.pop(context); // close loading dialog
      
      if (success) {
        _showToast('Đã từ chối yêu cầu rút tiền!', Colors.orange);
        _loadWithdrawals();
      }
    } catch (e) {
      Navigator.pop(context); // close loading
      _showToast('Lỗi khi từ chối yêu cầu: $e', Colors.red);
    }
  }

  void _showToast(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(bgColor == Colors.green ? Icons.check_circle_outline : Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatMoney(double value) {
    return NumberFormat("#,###").format(value);
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    // Handle ISO strings or numeric epoch ms
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
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
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFFFF6B35),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duyệt rút tiền',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E2D),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Xem và phê duyệt các yêu cầu thanh toán từ đối tác Merchant & Driver',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadWithdrawals,
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
          const SizedBox(height: 24),

          // LOADING STATE
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
              ),
            )
          // ERROR STATE
          else if (_errorMessage != null)
            _buildErrorState()
          // EMPTY STATE
          else if (_pendingWithdrawals.isEmpty)
            _buildEmptyState()
          // MAIN LIST OF PENDING WITHDRAWALS
          else
            _buildWithdrawalTable(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadWithdrawals,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 15,
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 72),
            SizedBox(height: 20),
            Text(
              'Không có yêu cầu rút tiền nào cần duyệt!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3238)),
            ),
            SizedBox(height: 6),
            Text(
              'Toàn bộ yêu cầu rút tiền của Merchant & Driver đã được đối soát sạch sẽ.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Text(
                  'Yêu cầu đang chờ duyệt',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3238)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_pendingWithdrawals.length} Đang chờ',
                    style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.5), // ID & Date
              1: FlexColumnWidth(2),   // User & Role
              2: FlexColumnWidth(2.5), // Destination Bank details
              3: FlexColumnWidth(1.5), // Amount
              4: FlexColumnWidth(2.2), // Actions
            },
            children: [
              // TABLE HEADER ROW
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[50]),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text('Mã GD / Ngày tạo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text('Đối tác / Vai trò', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text('Tài khoản thụ hưởng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text('Số tiền rút', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  ),
                ],
              ),

              // DATA ROWS
              ..._pendingWithdrawals.map((w) {
                final id = w['id'] ?? '';
                final userId = w['userId'] ?? 'Chưa rõ';
                final double amount = (w['amount'] as num?)?.toDouble() ?? 0.0;
                final description = w['description'] ?? 'Yêu cầu rút tiền';
                
                // Deduce role from userId format or dummy
                final bool isDriver = userId.toString().contains('driver') || userId.toString().startsWith('user_003');
                final String roleName = isDriver ? 'Tài xế (Driver)' : 'Cửa hàng (Merchant)';
                final Color roleColor = isDriver ? Colors.blue : Colors.purple;

                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1))),
                  ),
                  children: [
                    // TRANSACTION ID & DATE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#$id', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(_formatDate(w['createdAt']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),

                    // USER ID & ROLE BADGE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userId, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              roleName,
                              style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // RECIPIENT DETAILS (MOCK FOR TRANSACTION DATA IN DEMO)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vietcombank - CN Sài Gòn', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            isDriver ? '0123.4567.8901 · LE VAN B' : '0987.6543.2109 · PHUC LOC THO',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text('Nội dung: $description', style: const TextStyle(color: Colors.black54, fontSize: 11, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),

                    // AMOUNT VALUE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Text(
                        '${_formatMoney(amount)}đ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                      ),
                    ),

                    // ACTIONS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _reject(id),
                            icon: const Icon(Icons.close, size: 14),
                            label: const Text('Từ chối'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _approve(id),
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Duyệt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
