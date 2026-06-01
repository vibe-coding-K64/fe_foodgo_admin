import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/review_api_service.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final ReviewApiService _apiService = ReviewApiService();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _filterStar = 0;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.getAllReviews();
      setState(() {
        _reviews = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi kết nối API đánh giá: $e';
      });
    }
  }

  Future<void> _deleteReview(String id) async {
    try {
      final success = await _apiService.deleteReview(id);
      if (success) {
        _showToast('Đã xóa đánh giá vi phạm thành công!', Colors.redAccent);
        _fetchReviews();
      }
    } catch (e) {
      _showToast('Không thể xóa đánh giá: $e', Colors.red);
    }
  }

  void _showToast(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterStar == 0) return _reviews;
    return _reviews.where((r) => (r['starRating'] as num?)?.toInt() == _filterStar).toList();
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.map((r) => (r['starRating'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a + b);
    return sum / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giám sát & Kiểm duyệt Đánh giá',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D)),
                ),
                SizedBox(height: 4),
                Text(
                  'Xem và kiểm soát toàn bộ bình luận đánh giá trong hệ thống. Xóa các bình luận vi phạm chính sách của sàn.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            IconButton(
              onPressed: _fetchReviews,
              icon: const Icon(Icons.refresh, color: Color(0xFFFF6B35)),
              tooltip: 'Tải lại',
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (!_isLoading && _errorMessage == null && _reviews.isNotEmpty) ...[
          // Stats summary
          Row(
            children: [
              _buildRatingCard(),
              const SizedBox(width: 16),
              Expanded(child: _buildStarDistribution()),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // Filters bar
        Row(
          children: [
            const Text('Lọc theo đánh giá:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E1E2D))),
            const SizedBox(width: 12),
            ...[0, 5, 4, 3, 2, 1].map((star) {
              final isSelected = _filterStar == star;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(star == 0 ? 'Tất cả' : '★ $star'),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _filterStar = star),
                  selectedColor: const Color(0xFFFF6B35),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade300),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
        const SizedBox(height: 20),

        // Main List Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
              : _errorMessage != null
                  ? _buildErrorState()
                  : _filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, i) => _buildReviewCard(_filtered[i]),
                        ),
        ),
      ],
    );
  }

  Widget _buildRatingCard() {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(_avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Color(0xFFFF6B35))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Icon(
              i < _avgRating.round() ? Icons.star : Icons.star_outline,
              color: Colors.amber, size: 20,
            )),
          ),
          const SizedBox(height: 8),
          Text('${_reviews.length} đánh giá', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStarDistribution() {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final s = (r['starRating'] as num?)?.toInt() ?? 5;
      counts[s] = (counts[s] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [5, 4, 3, 2, 1].map((star) {
          final count = counts[star] ?? 0;
          final ratio = _reviews.isEmpty ? 0.0 : count / _reviews.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text('$star ★', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: ratio, backgroundColor: Colors.grey.shade200, color: Colors.amber, minHeight: 8),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 25, child: Text('$count', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchReviews, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline, size: 70, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có bình luận đánh giá nào trong hệ thống!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final id = review['id']?.toString() ?? '';
    final userName = review['userName']?.toString() ?? 'Ẩn danh';
    final userAvatar = review['userAvatarUrl']?.toString();
    final starRating = (review['starRating'] as num?)?.toInt() ?? 5;
    final comment = review['comment']?.toString() ?? '';
    final imageUrls = review['imageUrls'] as List? ?? [];
    
    // Formatting date
    String dateStr = 'Mới đây';
    if (review['createdAt'] != null) {
      try {
        final parsed = DateTime.parse(review['createdAt'].toString());
        dateStr = DateFormat('dd/MM/yyyy HH:mm').format(parsed);
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFFFF3E0),
                backgroundImage: userAvatar != null && userAvatar.isNotEmpty ? NetworkImage(userAvatar) : null,
                child: userAvatar == null || userAvatar.isEmpty
                    ? Text(userName[0].toUpperCase(), style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold, fontSize: 16))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: List.generate(5, (i) => Icon(
                      i < starRating ? Icons.star : Icons.star_outline,
                      color: Colors.amber, size: 18,
                    )),
                  ),
                  const SizedBox(height: 4),
                  if (review['storeId'] != null)
                    Text(
                      'Cửa hàng ID: ${review['storeId']}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(comment, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF2D3238))),
          
          if (imageUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrls[idx].toString(),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, err, st) => Container(
                        color: Colors.grey[200],
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(id, userName),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Xóa đánh giá vi phạm'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String userName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFDC3545),
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Xác nhận xóa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Bạn có chắc chắn muốn xóa đánh giá của người dùng "$userName"? Hành động này không thể hoàn tác.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Hủy', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteReview(id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC3545),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Xóa bỏ', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
