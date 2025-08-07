class RequestItemModel {
  final String id;
  final String name;
  final String description;
  final String itemType;
  final int timestamp;
  final String userId;

  RequestItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.itemType,
    required this.timestamp,
    required this.userId,
  });

  factory RequestItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return RequestItemModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      itemType: map['itemType'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'itemType': itemType,
      'timestamp': timestamp,
      'userId': userId,
    };
  }
}
