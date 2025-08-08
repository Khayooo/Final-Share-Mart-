class ExchangeItemModel {
  final String id;
  final String productName;
  final String productDescription;
  final String productImage;
  final String desiredProductName;
  final String desiredProductDescription;
  final String userId;
  final String status;
  final int timestamp;

  ExchangeItemModel({
    required this.id,
    required this.productName,
    required this.productDescription,
    required this.productImage,
    required this.desiredProductName,
    required this.desiredProductDescription,
    required this.userId,
    required this.status,
    required this.timestamp,
  });

  factory ExchangeItemModel.fromMap(Map<dynamic, dynamic> map) {
    return ExchangeItemModel(
      id: map['id'] ?? '',
      productName: map['productName'] ?? '',
      productDescription: map['productDescription'] ?? '',
      productImage: map['productImage'] ?? '',
      desiredProductName: map['desiredProductName'] ?? '',
      desiredProductDescription: map['desiredProductDescription'] ?? '',
      userId: map['userId'] ?? '',
      status: map['status'] ?? '',
      timestamp: map['timestamp'] ?? 0,
    );
  }
}