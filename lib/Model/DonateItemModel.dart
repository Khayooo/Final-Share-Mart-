class DonateItemModel {
  final String image;
  final String itemType;
  final String productName;
  final String productDescription;
  final String productPrice;
  final int timestamp;
  final String uid;
  final String userId;
//model for donate item
  DonateItemModel({
    required this.image,
    required this.itemType,
    required this.productName,
    required this.productDescription,
    required this.productPrice,
    required this.timestamp,
    required this.uid,
    required this.userId,
  });

  factory DonateItemModel.fromMap(Map<String, dynamic> map) {
    return DonateItemModel(
      image: map['image'] ?? '',
      itemType: map['itemType'] ?? '',
      productName: map['productName'] ?? '',
      productDescription: map['productDescription'] ?? '',
      productPrice: map['productPrice'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      uid: map['uid'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'itemType': itemType,
      'productName': productName,
      'productDescription': productDescription,
      'productPrice': productPrice,
      'timestamp': timestamp,
      'uid': uid,
      'userId': userId,
    };
  }
}
