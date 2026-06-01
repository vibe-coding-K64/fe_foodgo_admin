import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/services/admin_stats_api_service.dart';
import '../../data/services/order_api_service.dart';
import '../../data/models/order_model.dart' as model;

class MyDashboard extends StatefulWidget {
  const MyDashboard({super.key});
  @override
  State<MyDashboard> createState() => _MyDashboardState();
}

class _MyDashboardState extends State<MyDashboard> {
  final AdminStatsApiService _statsApiService = AdminStatsApiService();
  final OrderApiService _orderApiService = OrderApiService();

  bool _isLoading = true;
  String? _errorMessage;

  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalStores = 0;
  int _totalDrivers = 0;
  int _totalCustomers = 0;
  List<double> _weeklyRevenue = [0, 0, 0, 0, 0, 0, 0];

  List<model.Order> _recentOrders = [];
  Map<String, int> _statusCount = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _statsApiService.getSystemStats();
      final allOrders = await _orderApiService.getAllPlatformOrders();

      // Aggregate status counts
      final counts = <String, int>{};
      for (var o in allOrders) {
        counts[o.status] = (counts[o.status] ?? 0) + 1;
      }

      // Sort recent orders
      final recent = List<model.Order>.from(allOrders);
      recent.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      setState(() {
        _totalRevenue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        _totalOrders = (stats['totalOrders'] as num?)?.toInt() ?? 0;
        _totalStores = (stats['totalStores'] as num?)?.toInt() ?? 0;
        _totalDrivers = (stats['totalDrivers'] as num?)?.toInt() ?? 0;
        _totalCustomers = (stats['totalCustomers'] as num?)?.toInt() ?? 0;
        
        final List<dynamic>? weeklyList = stats['weeklyRevenue'];
        if (weeklyList != null) {
          _weeklyRevenue = weeklyList.map((e) => (e as num).toDouble()).toList();
        }

        _recentOrders = recent.take(5).toList();
        _statusCount = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể kết nối API thống kê hệ thống: $e';
      });
    }
  }

  String _formatMoney(double value) {
    return '${NumberFormat("#,###").format(value)}đ';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận': return Colors.orange;
      case 'Đang chế biến': return Colors.blue;
      case 'Đang giao': return Colors.purple;
      case 'Hoàn thành': return Colors.green;
      case 'Đã hủy': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B35)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                          Icons.dashboard_outlined,
                          color: Color(0xFFFF6B35),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bảng Điều Khiển Hệ Thống",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E1E2D),
                            ),
                          ),
                          Text(
                            "Thống kê tổng quan hoạt động toàn sàn FoodGo",
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _loadDashboardData,
                    icon: const Icon(Icons.refresh, color: Color(0xFFFF6B35)),
                    tooltip: 'Làm mới',
                  )
                ],
              ),
              const SizedBox(height: 30),

              // STATS GRID CARD
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Tổng Doanh Thu Sàn",
                      _formatMoney(_totalRevenue),
                      Icons.monetization_on_outlined,
                      [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Tổng Đơn Hàng",
                      _totalOrders.toString(),
                      Icons.shopping_bag_outlined,
                      [const Color(0xFF2196F3), const Color(0xFF00BCD4)],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Cửa Hàng Hoạt Động",
                      _totalStores.toString(),
                      Icons.storefront_outlined,
                      [const Color(0xFFFF9800), const Color(0xFFFFC107)],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Tài Xế Hệ Thống",
                      _totalDrivers.toString(),
                      Icons.local_shipping_outlined,
                      [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Khách Hàng Đăng Ký",
                      _totalCustomers.toString(),
                      Icons.people_outline,
                      [const Color(0xFF607D8B), const Color(0xFF9E9E9E)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // CHARTS & GRAPHS
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weekly Sales
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildCardContainer(
                          title: "Phân Tích Doanh Thu Tuần Này",
                          child: SizedBox(
                            height: 300,
                            child: LineChart(_mainLineData()),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Recent Orders
                        _buildCardContainer(
                          title: "Đơn Hàng Mới Nhất",
                          child: SizedBox(
                            width: double.infinity,
                            child: _recentOrders.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Center(child: Text('Chưa có đơn hàng nào phát sinh')),
                                  )
                                : DataTable(
                                    headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                                    horizontalMargin: 10,
                                    columnSpacing: 20,
                                    columns: const [
                                      DataColumn(label: Text("Mã Đơn", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Khách Hàng", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Hình Thức", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Trạng Thái", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Thanh Toán", style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: _recentOrders.map((o) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(o.code, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B35)))),
                                          DataCell(Text(o.customerName)),
                                          DataCell(Text(o.paymentMethod)),
                                          DataCell(_buildStatusChip(o.status)),
                                          DataCell(Text(_formatMoney(o.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Order Status Pie Chart
                  Expanded(
                    flex: 2,
                    child: _buildCardContainer(
                      title: "Tỷ Lệ Trạng Thái Đơn",
                      child: Column(
                        children: [
                          SizedBox(
                            height: 260,
                            child: _statusCount.isEmpty
                                ? const Center(child: Text('Chưa có thống kê'))
                                : PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 50,
                                      sections: _buildStatusSections(),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 20),
                          if (_statusCount.isNotEmpty)
                            ..._statusCount.entries.map((e) {
                              final total = _statusCount.values.fold(0, (sum, val) => sum + val);
                              final percent = total == 0 ? 0.0 : (e.value / total) * 100;
                              return _buildStatusRow(e.key, e.value, percent);
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 54, color: Colors.white.withOpacity(0.15)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              FittedBox(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(blurRadius: 15, color: Colors.black.withOpacity(0.03), offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3238)),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusRow(String status, int count, double percent) {
    Color color = _getStatusColor(status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(status, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Text(
            '$count (${percent.toStringAsFixed(0)}%)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  LineChartData _mainLineData() {
    double maxVal = _weeklyRevenue.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 100000;
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[100], strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const Text('0đ', style: TextStyle(color: Colors.grey, fontSize: 10));
              if (value >= 1000000) {
                return Text('${(value / 1000000).toStringAsFixed(1)}M', style: const TextStyle(color: Colors.grey, fontSize: 10));
              }
              return Text('${(value / 1000).toStringAsFixed(0)}K', style: const TextStyle(color: Colors.grey, fontSize: 10));
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const days = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
              if (value.toInt() >= 0 && value.toInt() < days.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(days[value.toInt()], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(7, (i) => FlSpot(i.toDouble(), _weeklyRevenue[i])),
          isCurved: true,
          gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Colors.orangeAccent]),
          barWidth: 4,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6B35).withOpacity(0.15),
                const Color(0xFFFF6B35).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildStatusSections() {
    final total = _statusCount.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return [];
    
    return _statusCount.entries.map((e) {
      final percent = (e.value / total) * 100;
      return PieChartSectionData(
        color: _getStatusColor(e.key),
        value: e.value.toDouble(),
        title: '${percent.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
}
