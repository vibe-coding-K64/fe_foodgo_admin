import 'package:flutter/material.dart';
import '../../data/services/report_api_service.dart';

class ReportTicketsPage extends StatefulWidget {
  const ReportTicketsPage({super.key});

  @override
  State<ReportTicketsPage> createState() => _ReportTicketsPageState();
}

class _ReportTicketsPageState extends State<ReportTicketsPage> {
  final ReportApiService _reportService = ReportApiService();

  String _filter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Mở', 'Đang xử lý', 'Đã giải quyết'];
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _reportService.getAllReports(
        status: _filter == 'Tất cả' ? null : _filter,
      );
      if (!mounted) return;
      setState(() {
        _tickets = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markResolved(Map<String, dynamic> ticket) async {
    final id = ticket['id'] as String? ?? '';
    if (id.isEmpty) return;

    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đánh dấu đã giải quyết'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thêm ghi chú xử lý (tuỳ chọn):'),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Xác nhận'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _reportService.updateStatus(id, 'Đã giải quyết', adminNote: noteCtrl.text);
      await _loadTickets();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã đánh dấu khiếu nại là đã giải quyết'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _markProcessing(Map<String, dynamic> ticket) async {
    final id = ticket['id'] as String? ?? '';
    if (id.isEmpty) return;
    try {
      await _reportService.updateStatus(id, 'Đang xử lý');
      await _loadTickets();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã chuyển sang trạng thái Đang xử lý'),
        backgroundColor: Colors.blue,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Khiếu nại từ Khách', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                const SizedBox(height: 4),
                Text(
                  '${_tickets.length} khiếu nại',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadTickets,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF6B35)),
              tooltip: 'Tải lại',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Stats
        if (!_isLoading && _error == null) ...[
          _buildStatsRow(),
          const SizedBox(height: 16),
        ],

        // Filters
        Row(
          children: _filters.map((f) {
            final isSelected = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _filter = f);
                  _loadTickets();
                },
                selectedColor: _filterColor(f),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? _filterColor(f) : Colors.grey.shade300),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildStatsRow() {
    final open = _tickets.where((t) => ReportApiService.mapStatusVi(t['status'] ?? '') == 'Mở' || t['status'] == 'open').length;
    final processing = _tickets.where((t) => ReportApiService.mapStatusVi(t['status'] ?? '') == 'Đang xử lý' || t['status'] == 'processing').length;
    final resolved = _tickets.where((t) => ReportApiService.mapStatusVi(t['status'] ?? '') == 'Đã giải quyết' || t['status'] == 'resolved').length;

    return Row(
      children: [
        _statCard('Tổng khiếu nại', _tickets.length.toString(), Icons.report_outlined, const Color(0xFF4F46E5)),
        const SizedBox(width: 12),
        _statCard('Đang mở', open.toString(), Icons.warning_amber_rounded, Colors.orange),
        const SizedBox(width: 12),
        _statCard('Đang xử lý', processing.toString(), Icons.pending_outlined, Colors.blue),
        const SizedBox(width: 12),
        _statCard('Đã giải quyết', resolved.toString(), Icons.check_circle_outline, Colors.green),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTickets,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    if (_tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _filter == 'Tất cả' ? 'Chưa có khiếu nại nào' : 'Không có khiếu nại ở trạng thái "$_filter"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildTicketCard(_tickets[i]),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final rawStatus = ticket['status'] as String? ?? 'open';
    final statusVi = ReportApiService.mapStatusVi(rawStatus);
    final statusColor = _statusColor(statusVi);

    final orderId = ticket['orderId'] ?? ticket['order'] ?? '—';
    final customer = ticket['customerName'] ?? ticket['customer'] ?? 'Không rõ';
    final reason = ticket['reason'] ?? 'Không rõ';
    final desc = ticket['description'] ?? ticket['desc'] ?? '';
    final date = ticket['createdAt'] != null
        ? _formatDate(ticket['createdAt'].toString())
        : '';
    final adminNote = ticket['adminNote'] as String? ?? '';

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusVi,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Text(ticket['id']?.toString().substring(0, 8) ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _badge(Icons.shopping_bag_outlined, 'Đơn: $orderId', Colors.blue),
              _badge(Icons.person_outline, customer, Colors.purple),
              _badge(Icons.report_outlined, reason, Colors.red),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(desc, style: const TextStyle(fontSize: 14, color: Color(0xFF1E1E2D), height: 1.5)),
          ],
          if (adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Ghi chú Admin: $adminNote',
                        style: const TextStyle(fontSize: 12, color: Colors.green)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (rawStatus == 'open' || statusVi == 'Mở')
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => _markProcessing(ticket),
                    icon: const Icon(Icons.pending_outlined, size: 16),
                    label: const Text('Đang xử lý'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              if (rawStatus != 'resolved' && statusVi != 'Đã giải quyết')
                ElevatedButton.icon(
                  onPressed: () => _markResolved(ticket),
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
      case 'Mở':
        return Colors.orange;
      case 'Đang xử lý':
        return Colors.blue;
      case 'Đã giải quyết':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _filterColor(String f) {
    switch (f) {
      case 'Mở':
        return Colors.orange;
      case 'Đang xử lý':
        return Colors.blue;
      case 'Đã giải quyết':
        return Colors.green;
      default:
        return const Color(0xFFFF6B35);
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
