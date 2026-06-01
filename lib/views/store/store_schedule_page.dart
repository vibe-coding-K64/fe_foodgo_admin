import 'package:flutter/material.dart';

class StoreSchedulePage extends StatefulWidget {
  const StoreSchedulePage({super.key});

  @override
  State<StoreSchedulePage> createState() => _StoreSchedulePageState();
}

class _StoreSchedulePageState extends State<StoreSchedulePage> {
  final List<Map<String, dynamic>> _schedules = [
    {'day': 'Chủ Nhật', 'open': '08:00', 'close': '22:00', 'isClosed': false},
    {'day': 'Thứ Hai', 'open': '07:00', 'close': '22:00', 'isClosed': false},
    {'day': 'Thứ Ba', 'open': '07:00', 'close': '22:00', 'isClosed': false},
    {'day': 'Thứ Tư', 'open': '07:00', 'close': '22:00', 'isClosed': false},
    {'day': 'Thứ Năm', 'open': '07:00', 'close': '22:00', 'isClosed': false},
    {'day': 'Thứ Sáu', 'open': '07:00', 'close': '23:00', 'isClosed': false},
    {'day': 'Thứ Bảy', 'open': '07:00', 'close': '23:00', 'isClosed': false},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lịch Mở Cửa',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E2D))),
                  SizedBox(height: 4),
                  Text('Cài đặt giờ hoạt động từng ngày',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _saveSchedule,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Lưu thay đổi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: List.generate(_schedules.length, (i) => _buildRow(i)),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Thay đổi lịch mở cửa sẽ được áp dụng ngay và hiển thị cho khách hàng.',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    final s = _schedules[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: index < _schedules.length - 1
              ? BorderSide(color: Colors.grey.shade100)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(s['day'],
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: s['isClosed'] ? Colors.grey : const Color(0xFF1E1E2D))),
          ),
          const SizedBox(width: 20),
          Switch(
            value: !s['isClosed'],
            onChanged: (val) => setState(() => _schedules[index]['isClosed'] = !val),
            activeColor: const Color(0xFFFF6B35),
          ),
          const SizedBox(width: 8),
          Text(s['isClosed'] ? 'Nghỉ' : 'Mở cửa',
              style: TextStyle(
                  color: s['isClosed'] ? Colors.grey : Colors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 24),
          if (!s['isClosed']) ...[
            _timePicker(index, 'open', s['open']),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('→', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ),
            _timePicker(index, 'close', s['close']),
          ],
        ],
      ),
    );
  }

  Widget _timePicker(int index, String field, String time) {
    return InkWell(
      onTap: () => _pick(index, field, time),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF9F9F9),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Color(0xFFFF6B35)),
            const SizedBox(width: 6),
            Text(time, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(int index, String field, String current) async {
    final parts = current.split(':');
    final t = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(context: context, initialTime: t);
    if (picked != null) {
      setState(() {
        _schedules[index][field] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _saveSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lưu lịch mở cửa thành công!'), backgroundColor: Colors.green),
    );
  }
}
