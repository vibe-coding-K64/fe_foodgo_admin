import 'package:flutter/material.dart';
import '../../data/models/system_config_model.dart';
import '../../data/services/system_config_api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SystemConfigApiService _apiService = SystemConfigApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Form controllers
  final TextEditingController _platformFeeController = TextEditingController();
  final TextEditingController _baseDeliveryFeeController = TextEditingController();
  final TextEditingController _minDeliveryFeeController = TextEditingController();
  final TextEditingController _maxDeliveryFeeController = TextEditingController();
  final TextEditingController _driverCommissionController = TextEditingController();
  final TextEditingController _merchantCommissionController = TextEditingController();
  final TextEditingController _minWithdrawalController = TextEditingController();
  final TextEditingController _maxWithdrawalController = TextEditingController();
  final TextEditingController _appVersionController = TextEditingController();

  bool _maintenanceMode = false;
  SystemConfig? _currentConfig;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _platformFeeController.dispose();
    _baseDeliveryFeeController.dispose();
    _minDeliveryFeeController.dispose();
    _maxDeliveryFeeController.dispose();
    _driverCommissionController.dispose();
    _merchantCommissionController.dispose();
    _minWithdrawalController.dispose();
    _maxWithdrawalController.dispose();
    _appVersionController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = await _apiService.getSystemConfig();
      _currentConfig = config;

      _platformFeeController.text = config.platformFeePercentage.toString();
      _baseDeliveryFeeController.text = config.baseDeliveryFee.toStringAsFixed(0);
      _minDeliveryFeeController.text = config.minDeliveryFee.toStringAsFixed(0);
      _maxDeliveryFeeController.text = config.maxDeliveryFee.toStringAsFixed(0);
      _driverCommissionController.text = config.driverCommissionPercentage.toString();
      _merchantCommissionController.text = config.merchantCommissionPercentage.toString();
      _minWithdrawalController.text = config.minWithdrawalAmount.toStringAsFixed(0);
      _maxWithdrawalController.text = config.maxWithdrawalAmount.toStringAsFixed(0);
      _appVersionController.text = config.appVersion;

      setState(() {
        _maintenanceMode = config.maintenanceMode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải cấu hình hệ thống: $e';
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final updatedConfig = SystemConfig(
      id: _currentConfig?.id ?? 'config_001',
      platformFeePercentage: double.parse(_platformFeeController.text),
      baseDeliveryFee: double.parse(_baseDeliveryFeeController.text),
      minDeliveryFee: double.parse(_minDeliveryFeeController.text),
      maxDeliveryFee: double.parse(_maxDeliveryFeeController.text),
      driverCommissionPercentage: double.parse(_driverCommissionController.text),
      merchantCommissionPercentage: double.parse(_merchantCommissionController.text),
      minWithdrawalAmount: double.parse(_minWithdrawalController.text),
      maxWithdrawalAmount: double.parse(_maxWithdrawalController.text),
      maintenanceMode: _maintenanceMode,
      appVersion: _appVersionController.text.trim(),
    );

    try {
      await _apiService.updateSystemConfig(updatedConfig);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Cập nhật cấu hình hệ thống thành công!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _loadConfig();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Lỗi cập nhật cấu hình: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadConfig,
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

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER BAR
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
                        Icons.settings_outlined,
                        color: Color(0xFFFF6B35),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cấu hình hệ thống',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E2D),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Thiết lập các tham số, mức phí và chế độ hoạt động toàn sàn',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveConfig,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Lưu cấu hình'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN
                Expanded(
                  child: Column(
                    children: [
                      // SECTION 1: FEES & COMMISSIONS
                      _buildCard(
                        title: 'Phí & Hoa hồng',
                        icon: Icons.monetization_on_outlined,
                        iconColor: Colors.green,
                        children: [
                          _buildNumberInput(
                            label: 'Phí nền tảng (%)',
                            controller: _platformFeeController,
                            suffix: '%',
                            hint: 'Mức phí hệ thống thu trên mỗi đơn hàng',
                            validator: (v) => _validatePercentage(v, 'Phí nền tảng'),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberInput(
                                  label: 'Hoa hồng tài xế (%)',
                                  controller: _driverCommissionController,
                                  suffix: '%',
                                  hint: 'Tỷ lệ tài xế nhận',
                                  validator: (v) => _validatePercentage(v, 'Hoa hồng tài xế'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildNumberInput(
                                  label: 'Hoa hồng đối tác (%)',
                                  controller: _merchantCommissionController,
                                  suffix: '%',
                                  hint: 'Tỷ lệ quán nhận',
                                  validator: (v) => _validatePercentage(v, 'Hoa hồng đối tác'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // SECTION 2: DELIVERY FEES
                      _buildCard(
                        title: 'Cấu hình Phí giao hàng',
                        icon: Icons.delivery_dining_outlined,
                        iconColor: Colors.blue,
                        children: [
                          _buildNumberInput(
                            label: 'Phí giao hàng cơ bản (VNĐ)',
                            controller: _baseDeliveryFeeController,
                            suffix: 'đ',
                            hint: 'Phí giao hàng tối thiểu ban đầu',
                            validator: (v) => _validateAmount(v, 'Phí giao hàng cơ bản'),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberInput(
                                  label: 'Phí giao hàng tối thiểu (VNĐ)',
                                  controller: _minDeliveryFeeController,
                                  suffix: 'đ',
                                  hint: 'Giới hạn dưới',
                                  validator: (v) => _validateAmount(v, 'Phí tối thiểu'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildNumberInput(
                                  label: 'Phí giao hàng tối đa (VNĐ)',
                                  controller: _maxDeliveryFeeController,
                                  suffix: 'đ',
                                  hint: 'Giới hạn trên',
                                  validator: (v) => _validateAmount(v, 'Phí tối đa'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // RIGHT COLUMN
                Expanded(
                  child: Column(
                    children: [
                      // SECTION 3: WALLET & LIMITS
                      _buildCard(
                        title: 'Giới hạn số dư ví',
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Colors.purple,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberInput(
                                  label: 'Yêu cầu rút tối thiểu (VNĐ)',
                                  controller: _minWithdrawalController,
                                  suffix: 'đ',
                                  hint: 'Mức rút tối thiểu',
                                  validator: (v) => _validateAmount(v, 'Rút tối thiểu'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildNumberInput(
                                  label: 'Yêu cầu rút tối đa (VNĐ)',
                                  controller: _maxWithdrawalController,
                                  suffix: 'đ',
                                  hint: 'Giới hạn một lần rút',
                                  validator: (v) => _validateAmount(v, 'Rút tối đa'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // SECTION 4: SYSTEM STATS & STATUS
                      _buildCard(
                        title: 'Trạng thái hệ thống',
                        icon: Icons.settings_applications_outlined,
                        iconColor: Colors.orange,
                        children: [
                          _buildTextInput(
                            label: 'Phiên bản ứng dụng hiện tại',
                            controller: _appVersionController,
                            hint: 'VD: 1.0.0 (Dùng để bắt buộc cập nhật nếu cần)',
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Vui lòng nhập phiên bản app';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _maintenanceMode
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.construction_outlined,
                                  color: _maintenanceMode ? Colors.red : Colors.orange,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Chế độ bảo trì hệ thống',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      _maintenanceMode
                                          ? 'Ứng dụng đang khóa để bảo trì. Khách hàng/tài xế không thể thao tác.'
                                          : 'Hệ thống đang hoạt động bình thường.',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _maintenanceMode,
                                onChanged: (val) {
                                  setState(() {
                                    _maintenanceMode = val;
                                  });
                                },
                                activeColor: Colors.red,
                              ),
                            ],
                          ),
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
    );
  }

  // WIDGET BUILDERS
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3238),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNumberInput({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            suffixText: suffix,
            suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF6B35)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF6B35)),
            ),
          ),
        ),
      ],
    );
  }

  // VALIDATORS
  String? _validatePercentage(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    final numVal = double.tryParse(value);
    if (numVal == null) {
      return '$fieldName phải là số hợp lệ';
    }
    if (numVal < 0 || numVal > 100) {
      return '$fieldName phải từ 0% đến 100%';
    }
    return null;
  }

  String? _validateAmount(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    final numVal = double.tryParse(value);
    if (numVal == null) {
      return '$fieldName phải là số tiền hợp lệ';
    }
    if (numVal < 0) {
      return '$fieldName không được âm';
    }
    return null;
  }
}
