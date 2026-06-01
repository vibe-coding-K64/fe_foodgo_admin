class SystemConfig {
  final String? id;
  final double platformFeePercentage;
  final double baseDeliveryFee;
  final double minDeliveryFee;
  final double maxDeliveryFee;
  final double driverCommissionPercentage;
  final double merchantCommissionPercentage;
  final double minWithdrawalAmount;
  final double maxWithdrawalAmount;
  final bool maintenanceMode;
  final String appVersion;
  final String? createdAt;
  final String? updatedAt;

  SystemConfig({
    this.id,
    required this.platformFeePercentage,
    required this.baseDeliveryFee,
    required this.minDeliveryFee,
    required this.maxDeliveryFee,
    required this.driverCommissionPercentage,
    required this.merchantCommissionPercentage,
    required this.minWithdrawalAmount,
    required this.maxWithdrawalAmount,
    required this.maintenanceMode,
    required this.appVersion,
    this.createdAt,
    this.updatedAt,
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      id: json['id'],
      platformFeePercentage: (json['platformFeePercentage'] ?? 0.0).toDouble(),
      baseDeliveryFee: (json['baseDeliveryFee'] ?? 0.0).toDouble(),
      minDeliveryFee: (json['minDeliveryFee'] ?? 0.0).toDouble(),
      maxDeliveryFee: (json['maxDeliveryFee'] ?? 0.0).toDouble(),
      driverCommissionPercentage: (json['driverCommissionPercentage'] ?? 0.0).toDouble(),
      merchantCommissionPercentage: (json['merchantCommissionPercentage'] ?? 0.0).toDouble(),
      minWithdrawalAmount: (json['minWithdrawalAmount'] ?? 0.0).toDouble(),
      maxWithdrawalAmount: (json['maxWithdrawalAmount'] ?? 0.0).toDouble(),
      maintenanceMode: json['maintenanceMode'] ?? false,
      appVersion: json['appVersion'] ?? '1.0.0',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platformFeePercentage': platformFeePercentage,
      'baseDeliveryFee': baseDeliveryFee,
      'minDeliveryFee': minDeliveryFee,
      'maxDeliveryFee': maxDeliveryFee,
      'driverCommissionPercentage': driverCommissionPercentage,
      'merchantCommissionPercentage': merchantCommissionPercentage,
      'minWithdrawalAmount': minWithdrawalAmount,
      'maxWithdrawalAmount': maxWithdrawalAmount,
      'maintenanceMode': maintenanceMode,
      'appVersion': appVersion,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
