import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/services/admin_stats_api_service.dart';
import '../../data/services/order_api_service.dart';
import '../../data/services/product_api_service.dart';
import '../../data/models/order_model.dart' as model;
import '../../data/models/product_model.dart';
import '../orders/order_detail_page.dart';

class StoreDetailStatsPage extends StatefulWidget {
  final String storeId;
  final String storeName;
  final Function(String)? onNavigate;

  const StoreDetailStatsPage({
    super.key,
    required this.storeId,
    required this.storeName,
    this.onNavigate,
  });

  @override
  State<StoreDetailStatsPage> createState() => _StoreDetailStatsPageState();
}

class _StoreDetailStatsPageState extends State<StoreDetailStatsPage> {
  final AdminStatsApiService _statsApiService = AdminStatsApiService();
  final OrderApiService _orderApiService = OrderApiService();
  final ProductApiService _productApiService = ProductApiService();

  bool _isLoading = true;
  String? _errorMessage;

  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  double _storeRating = 0.0;
  int _reviewCount = 0;

  List<model.Order> _recentOrders = [];
  Map<String, int> _statusCount = {};
  List<Product> _products = [];

  String _selectedPeriod = 'month';
  double _periodRevenue = 0.0;
  int _periodOrders = 0;
  List<double> _periodDailyRevenue = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _statsApiService.getMerchantStats(
        widget.storeId,
        period: _selectedPeriod,
      );
      final allOrders = await _orderApiService.getOrdersByStoreId(widget.storeId);
      final productsList = await _productApiService.getAllProducts(widget.storeId);

      final counts = <String, int>{};
      for (var o in allOrders) {
        counts[o.status] = (counts[o.status] ?? 0) + 1;
      }

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
        _totalProducts = productsList.length;
        _storeRating = (stats['rating'] as num?)?.toDouble() ?? 4.5;
        _reviewCount = (stats['reviewCount'] as num?)?.toInt() ?? 12;

        _periodRevenue = (stats['periodRevenue'] as num?)?.toDouble() ?? 0.0;
        _periodOrders = (stats['periodOrders'] as num?)?.toInt() ?? 0;

        final List<dynamic>? dailyList = stats['periodDailyRevenue'] ?? stats['weeklyRevenue'];
        if (dailyList != null) {
          _periodDailyRevenue = dailyList.map((e) => (e as num).toDouble()).toList();
        } else {
          _periodDailyRevenue = [];
        }

        _recentOrders = recent.take(10).toList();
        _statusCount = counts;
        _products = productsList;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải dữ liệu thống kê: $e';
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
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B35)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStats,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
                child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMetricsGrid(),
            const SizedBox(height: 24),
            _buildChartsSection(),
            const SizedBox(height: 24),
            _buildRecentOrdersAndProducts(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E2D)),
          onPressed: () {
            if (widget.onNavigate != null) {
              widget.onNavigate!('/stores');
            }
          },
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê: ${widget.storeName}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D)),
            ),
            const SizedBox(height: 4),
            Text(
              'Xem chi tiết doanh thu, đơn hàng và danh sách món ăn',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const Spacer(),
        _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          _buildPeriodButton('week', 'Tuần'),
          _buildPeriodButton('month', 'Tháng'),
          _buildPeriodButton('year', 'Năm'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return InkWell(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedPeriod = value;
          });
          _loadStats();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: [
        _buildMetricCard(
          'Tổng doanh thu',
          _formatMoney(_totalRevenue),
          Icons.monetization_on_outlined,
          Colors.orange,
        ),
        _buildMetricCard(
          'Số đơn hàng',
          _totalOrders.toString(),
          Icons.shopping_bag_outlined,
          Colors.blue,
        ),
        _buildMetricCard(
          'Số món ăn',
          _totalProducts.toString(),
          Icons.restaurant_menu_outlined,
          Colors.green,
        ),
        _buildMetricCard(
          'Đánh giá cửa hàng',
          '${_storeRating.toStringAsFixed(1)} ★ (${_reviewCount} đánh giá)',
          Icons.star_outline_rounded,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            height: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Biểu đồ doanh thu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                    Text(
                      'Doanh thu kỳ này: ${_formatMoney(_periodRevenue)}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFFFF6B35), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _periodDailyRevenue.isEmpty
                      ? const Center(child: Text('Không có dữ liệu biểu đồ cho kỳ này'))
                      : LineChart(_mainLineData()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            height: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trạng thái đơn hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                const SizedBox(height: 24),
                Expanded(
                  child: _statusCount.isEmpty
                      ? const Center(child: Text('Không có đơn hàng nào'))
                      : Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections: _buildStatusSections(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _statusCount.entries.map((e) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(e.key),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${e.key}: ${e.value} đơn', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        radius: 50,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildRecentOrdersAndProducts() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Đơn hàng gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                const SizedBox(height: 16),
                _recentOrders.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(child: Text('Không có đơn hàng nào')),
                      )
                    : Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                          4: FixedColumnWidth(60),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            ),
                            children: const [
                              Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Mã đơn', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          ),
                          ..._recentOrders.map((order) {
                            return TableRow(
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(order.code, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFFF6B35))),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(order.customerName.isEmpty ? 'Khách hàng' : order.customerName),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(_formatMoney(order.finalAmount)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: UnconstrainedBox(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(order.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        order.status,
                                        style: TextStyle(color: _getStatusColor(order.status), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: IconButton(
                                    icon: const Icon(Icons.visibility_outlined, color: Color(0xFFFF6B35), size: 20),
                                    onPressed: () {
                                      model.Order o = order;
                                      OrderDetailPage.currentOrder = o;
                                      if (widget.onNavigate != null) {
                                        widget.onNavigate!('/orders/detail');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Danh sách món ăn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                const SizedBox(height: 16),
                _products.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(child: Text('Không có món ăn nào')),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.take(6).length,
                        itemBuilder: (context, idx) {
                          final p = _products[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey[100],
                                    child: p.imageUrl != null
                                        ? Image.network(p.imageUrl!, fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.fastfood, color: Colors.grey))
                                        : const Icon(Icons.fastfood, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D)), overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(p.categoryName, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(_formatMoney(p.basePrice), style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: !p.isOutOfStock ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        !p.isOutOfStock ? 'Đang bán' : 'Hết món',
                                        style: TextStyle(fontSize: 10, color: !p.isOutOfStock ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
