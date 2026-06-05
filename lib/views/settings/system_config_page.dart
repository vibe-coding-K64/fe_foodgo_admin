import 'package:flutter/material.dart';
import '../../data/models/system_config_model.dart';
import '../../data/services/system_config_api_service.dart';

class SystemConfigPage extends StatefulWidget {
  const SystemConfigPage({super.key});

  @override
  State<SystemConfigPage> createState() => _SystemConfigPageState();
}

class _SystemConfigPageState extends State<SystemConfigPage> {
  final SystemConfigApiService _service = SystemConfigApiService();
  SystemConfig? _config;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _hasChanges = false;

  // Controllers
  late TextEditingController _platformFeeCtrl;
  late TextEditingController _baseDeliveryCtrl;
  late TextEditingController _minDeliveryCtrl;
  late TextEditingController _maxDeliveryCtrl;
  late TextEditingController _driverCommCtrl;
  late TextEditingController _merchantCommCtrl;
  late TextEditingController _minWithdrawCtrl;
  late TextEditingController _maxWithdrawCtrl;
  late TextEditingController _appVersionCtrl;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadConfig();
  }

  void _initControllers() {
    _platformFeeCtrl = TextEditingController();
    _baseDeliveryCtrl = TextEditingController();
    _minDeliveryCtrl = TextEditingController();
    _maxDeliveryCtrl = TextEditingController();
    _driverCommCtrl = TextEditingController();
    _merchantCommCtrl = TextEditingController();
    _minWithdrawCtrl = TextEditingController();
    _maxWithdrawCtrl = TextEditingController();
    _appVersionCtrl = TextEditingController();

    for (final ctrl in _allControllers) {
      ctrl.addListener(() => setState(() => _hasChanges = true));
    }
  }

  List<TextEditingController> get _allControllers => [
        _platformFeeCtrl, _baseDeliveryCtrl, _minDeliveryCtrl, _maxDeliveryCtrl,
        _driverCommCtrl, _merchantCommCtrl, _minWithdrawCtrl, _maxWithdrawCtrl,
        _appVersionCtrl,
      ];

  void _populateControllers(SystemConfig cfg) {
    _platformFeeCtrl.text = cfg.platformFeePercentage.toString();
    _baseDeliveryCtrl.text = cfg.baseDeliveryFee.toString();
    _minDeliveryCtrl.text = cfg.minDeliveryFee.toString();
    _maxDeliveryCtrl.text = cfg.maxDeliveryFee.toString();
    _driverCommCtrl.text = cfg.driverCommissionPercentage.toString();
    _merchantCommCtrl.text = cfg.merchantCommissionPercentage.toString();
    _minWithdrawCtrl.text = cfg.minWithdrawalAmount.toString();
    _maxWithdrawCtrl.text = cfg.maxWithdrawalAmount.toString();
    _appVersionCtrl.text = cfg.appVersion;
    _maintenanceMode = cfg.maintenanceMode;
    _hasChanges = false;
  }

  Future<void> _loadConfig() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final cfg = await _service.getSystemConfig();
      if (!mounted) return;
      setState(() {
        _config = cfg;
        _isLoading = false;
      });
      _populateControllers(cfg);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;
    setState(() => _isSaving = true);
    try {
      final updated = SystemConfig(
        id: _config!.id,
        platformFeePercentage: double.tryParse(_platformFeeCtrl.text) ?? _config!.platformFeePercentage,
        baseDeliveryFee: double.tryParse(_baseDeliveryCtrl.text) ?? _config!.baseDeliveryFee,
        minDeliveryFee: double.tryParse(_minDeliveryCtrl.text) ?? _config!.minDeliveryFee,
        maxDeliveryFee: double.tryParse(_maxDeliveryCtrl.text) ?? _config!.maxDeliveryFee,
        driverCommissionPercentage: double.tryParse(_driverCommCtrl.text) ?? _config!.driverCommissionPercentage,
        merchantCommissionPercentage: double.tryParse(_merchantCommCtrl.text) ?? _config!.merchantCommissionPercentage,
        minWithdrawalAmount: double.tryParse(_minWithdrawCtrl.text) ?? _config!.minWithdrawalAmount,
        maxWithdrawalAmount: double.tryParse(_maxWithdrawCtrl.text) ?? _config!.maxWithdrawalAmount,
        maintenanceMode: _maintenanceMode,
        appVersion: _appVersionCtrl.text,
        createdAt: _config!.createdAt,
      );
      final saved = await _service.updateSystemConfig(updated);
      if (!mounted) return;
      setState(() {
        _config = saved;
        _isSaving = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Lưu cấu hình hệ thống thành công'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    for (final ctrl in _allControllers) ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: Color(0xFFFF6B35),
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cấu hình hệ thống',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                  SizedBox(height: 4),
                  Text('Điều chỉnh phí, hoa hồng và cài đặt toàn hệ thống',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _loadConfig,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF6B35)),
              tooltip: 'Tải lại',
            ),
            const SizedBox(width: 8),
            if (_hasChanges)
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveConfig,
                icon: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu thay đổi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadConfig,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Maintenance Mode Banner
                  _buildMaintenanceBanner(),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildSection(
                              icon: Icons.percent_rounded,
                              title: 'Phí nền tảng',
                              color: const Color(0xFF4F46E5),
                              fields: [
                                _buildField('Phí nền tảng (%)', _platformFeeCtrl, suffix: '%', hint: 'VD: 10'),
                                _buildField('Hoa hồng tài xế (%)', _driverCommCtrl, suffix: '%', hint: 'VD: 80'),
                                _buildField('Hoa hồng merchant (%)', _merchantCommCtrl, suffix: '%', hint: 'VD: 70'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildSection(
                              icon: Icons.savings_outlined,
                              title: 'Hạn mức rút tiền',
                              color: Colors.teal,
                              fields: [
                                _buildField('Rút tối thiểu (đ)', _minWithdrawCtrl, suffix: 'đ', hint: 'VD: 50000'),
                                _buildField('Rút tối đa (đ)', _maxWithdrawCtrl, suffix: 'đ', hint: 'VD: 10000000'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          children: [
                            _buildSection(
                              icon: Icons.delivery_dining_rounded,
                              title: 'Phí giao hàng',
                              color: Colors.orange,
                              fields: [
                                _buildField('Phí cơ bản (đ)', _baseDeliveryCtrl, suffix: 'đ', hint: 'VD: 15000'),
                                _buildField('Phí tối thiểu (đ)', _minDeliveryCtrl, suffix: 'đ', hint: 'VD: 10000'),
                                _buildField('Phí tối đa (đ)', _maxDeliveryCtrl, suffix: 'đ', hint: 'VD: 50000'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildSection(
                              icon: Icons.phone_android_rounded,
                              title: 'Ứng dụng',
                              color: Colors.green,
                              fields: [
                                _buildField('Phiên bản App', _appVersionCtrl, hint: 'VD: 1.0.0'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMaintenanceBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _maintenanceMode ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _maintenanceMode ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _maintenanceMode ? Icons.construction_rounded : Icons.check_circle_rounded,
            color: _maintenanceMode ? Colors.red : Colors.green,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _maintenanceMode ? '⚠️ Hệ thống đang trong chế độ bảo trì' : '✅ Hệ thống đang hoạt động bình thường',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _maintenanceMode ? Colors.red : Colors.green,
                  ),
                ),
                Text(
                  _maintenanceMode
                      ? 'Người dùng không thể truy cập ứng dụng trong lúc bảo trì.'
                      : 'Tắt chế độ này để đặt hệ thống vào trạng thái bảo trì.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: _maintenanceMode,
            onChanged: (val) => setState(() { _maintenanceMode = val; _hasChanges = true; }),
            activeColor: Colors.red,
            inactiveThumbColor: Colors.green,
            inactiveTrackColor: Colors.green.shade200,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> fields,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {String suffix = '', String hint = ''}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E1E2D))),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: suffix == 'đ' || suffix == '%'
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              suffixText: suffix,
              suffixStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFFF6B35)),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
