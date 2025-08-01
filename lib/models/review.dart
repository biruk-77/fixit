class Review {
  final String id;
  final String workerId;
  final String reviewerId;
  final String reviewerName;
  final String text;
  final double rating;
  final DateTime timestamp;

  Review({
    required this.id,
    required this.workerId,
    required this.reviewerId,
    required this.reviewerName,
    required this.text,
    required this.rating,
    required this.timestamp,
  });

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      id: data['id'],
      workerId: data['workerId'],
      reviewerId: data['reviewerId'],
      reviewerName: data['reviewerName'],
      text: data['text'],
      rating: data['rating'].toDouble(),
      timestamp: data['timestamp'].toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'text': text,
      'rating': rating,
      'timestamp': timestamp,
    };
  }
}
