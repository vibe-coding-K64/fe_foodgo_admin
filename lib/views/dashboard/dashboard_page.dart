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
  List<Map<String, dynamic>> _topStores = [];

  List<model.Order> _recentOrders = [];
  Map<String, int> _statusCount = {};

  // Time filter variables
  String _selectedPeriod = 'week';
  DateTimeRange? _selectedDateRange;
  double _periodRevenue = 0.0;
  int _periodOrders = 0;
  double _prevPeriodRevenue = 0.0;
  int _prevPeriodOrders = 0;
  double _revenueGrowth = 0.0;
  List<double> _periodDailyRevenue = [];

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
      String? fromStr;
      String? toStr;
      if (_selectedPeriod == 'custom' && _selectedDateRange != null) {
        fromStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
        toStr = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
      }

      final stats = await _statsApiService.getSystemStats(
        period: _selectedPeriod,
        from: fromStr,
        to: toStr,
      );

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

      if (!mounted) return;
      setState(() {
        _totalRevenue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0;
        _totalOrders = (stats['totalOrders'] as num?)?.toInt() ?? 0;
        _totalStores = (stats['totalStores'] as num?)?.toInt() ?? 0;
        _totalDrivers = (stats['totalDrivers'] as num?)?.toInt() ?? 0;
        _totalCustomers = (stats['totalCustomers'] as num?)?.toInt() ?? 0;

        _periodRevenue = (stats['periodRevenue'] as num?)?.toDouble() ?? 0.0;
        _periodOrders = (stats['periodOrders'] as num?)?.toInt() ?? 0;
        _prevPeriodRevenue = (stats['prevPeriodRevenue'] as num?)?.toDouble() ?? 0.0;
        _prevPeriodOrders = (stats['prevPeriodOrders'] as num?)?.toInt() ?? 0;
        _revenueGrowth = (stats['revenueGrowth'] as num?)?.toDouble() ?? 0.0;

        final List<dynamic>? dailyList = stats['periodDailyRevenue'] ?? stats['weeklyRevenue'];
        if (dailyList != null) {
          _periodDailyRevenue = dailyList.map((e) => (e as num).toDouble()).toList();
        } else {
          _periodDailyRevenue = [];
        }

        final List<dynamic>? topStoresList = stats['topStores'];
        if (topStoresList != null) {
          _topStores = topStoresList.map((e) => Map<String, dynamic>.from(e)).toList();
        }

        _recentOrders = recent.take(5).toList();
        _statusCount = counts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể kết nối API thống kê hệ thống: $e';
      });
    }
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPeriod = value;
            if (value != 'custom') {
              _loadDashboardData();
            } else {
              _selectDateRange();
            }
          });
        }
      },
      selectedColor: const Color(0xFFFF6B35),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B35),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _loadDashboardData();
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
              const SizedBox(height: 16),

              // Period Filter row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildPeriodChip('today', 'Hôm nay'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('week', 'Tuần này'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('month', 'Tháng này'),
                      const SizedBox(width: 8),
                      _buildPeriodChip('custom', 'Tùy chỉnh'),
                      if (_selectedPeriod == 'custom') ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text(_selectedDateRange == null 
                            ? 'Chọn khoảng ngày' 
                            : '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6B35),
                            side: const BorderSide(color: Color(0xFFFF6B35)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _revenueGrowth >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _revenueGrowth >= 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _revenueGrowth >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: _revenueGrowth >= 0 ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Doanh thu ${_revenueGrowth >= 0 ? 'tăng ↑' : 'giảm ↓'} ${_revenueGrowth.abs().toStringAsFixed(1)}% so với kỳ trước',
                          style: TextStyle(
                            color: _revenueGrowth >= 0 ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // STATS GRID CARD
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      _selectedPeriod == 'today' ? "Doanh thu Hôm nay" : (_selectedPeriod == 'week' ? "Doanh thu Tuần này" : (_selectedPeriod == 'month' ? "Doanh thu Tháng này" : "Doanh thu Kỳ chọn")),
                      _formatMoney(_periodRevenue),
                      Icons.monetization_on_outlined,
                      [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      _selectedPeriod == 'today' ? "Đơn hàng Hôm nay" : (_selectedPeriod == 'week' ? "Đơn hàng Tuần này" : (_selectedPeriod == 'month' ? "Đơn hàng Tháng này" : "Đơn hàng Kỳ chọn")),
                      _periodOrders.toString(),
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
                  // Sales Analaysis
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildCardContainer(
                          title: _selectedPeriod == 'today' ? "Phân Tích Doanh Thu Hôm Nay" : (_selectedPeriod == 'week' ? "Phân Tích Doanh Thu Tuần Này" : (_selectedPeriod == 'month' ? "Phân Tích Doanh Thu Tháng Này" : "Phân Tích Doanh Thu Kỳ Chọn")),
                          child: SizedBox(
                            height: 300,
                            child: LineChart(_mainLineData()),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Top Stores BarChart
                        if (_topStores.isNotEmpty)
                          _buildCardContainer(
                            title: "Top 5 Cửa Hàng Bán Chạy",
                            child: SizedBox(
                              height: 220,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: (_topStores
                                              .map((s) => (s['reviewCount'] as num?)?.toDouble() ?? 0)
                                              .reduce((a, b) => a > b ? a : b) *
                                          1.3)
                                      .clamp(1, double.infinity),
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        final store = _topStores[groupIndex];
                                        return BarTooltipItem(
                                          '${store['name']}\n${rod.toY.toInt()} đánh giá',
                                          const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= _topStores.length) return const SizedBox();
                                          final name = (_topStores[idx]['name'] as String?) ?? '';
                                          final shortName = name.length > 10 ? '${name.substring(0, 10)}…' : name;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(shortName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                  barGroups: List.generate(_topStores.length, (i) {
                                    final reviewCount = (_topStores[i]['reviewCount'] as num?)?.toDouble() ?? 0;
                                    final colors = [
                                      const Color(0xFFFF6B35),
                                      const Color(0xFF4F46E5),
                                      Colors.green,
                                      Colors.orange,
                                      Colors.teal,
                                    ];
                                    return BarChartGroupData(
                                      x: i,
                                      barRods: [
                                        BarChartRodData(
                                          toY: reviewCount,
                                          color: colors[i % colors.length],
                                          width: 32,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
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
    double maxVal = _periodDailyRevenue.isEmpty ? 0 : _periodDailyRevenue.reduce((a, b) => a > b ? a : b);
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
              final int idx = value.toInt();
              if (idx < 0 || idx >= _periodDailyRevenue.length) return const SizedBox();
              
              if (_periodDailyRevenue.length == 7) {
                const days = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(days[idx], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                );
              } else if (_periodDailyRevenue.length == 1) {
                return const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text("Hôm nay", style: TextStyle(color: Colors.grey, fontSize: 12)),
                );
              } else {
                final interval = (_periodDailyRevenue.length / 5).ceil();
                if (idx % interval == 0 || idx == _periodDailyRevenue.length - 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('${idx + 1}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  );
                }
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(_periodDailyRevenue.length, (i) => FlSpot(i.toDouble(), _periodDailyRevenue[i])),
          isCurved: _periodDailyRevenue.length > 1,
          gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Colors.orangeAccent]),
          barWidth: 4,
          dotData: FlDotData(show: _periodDailyRevenue.length < 15),
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
