class DailymotionMetaData {
  /// Dailymotion video ID of the currently loaded video.
  final String videoId;

  /// Video title of the currently loaded video.
  final String title;

  /// Channel name or uploader of the currently loaded video.
  final String author;

  /// Total duration of the currently loaded video.
  final Duration duration;

  const DailymotionMetaData({
    this.videoId = '',
    this.title = '',
    this.author = '',
    this.duration = const Duration(),
  });

  /// Creates [DailymotionMetaData] from raw json video data.
  factory DailymotionMetaData.fromRawData(dynamic rawData) {
    final data = rawData as Map<String, dynamic>;
    final durationInMs = ((data['duration'] ?? 0).toDouble() * 1000).floor();
    return DailymotionMetaData(
      videoId: data['videoId'],
      title: data['title'],
      author: data['author'],
      duration: Duration(milliseconds: durationInMs),
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'videoId: $videoId, '
        'title: $title, '
        'author: $author, '
        'duration: ${duration.inSeconds} sec.)';
  }
}
