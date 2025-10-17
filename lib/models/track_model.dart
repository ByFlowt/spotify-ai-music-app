class Track {
  final String id;
  final String name;
  final String artistName;
  final String? albumName;
  final String? imageUrl;
  final int durationMs;
  final int popularity;
  final String? previewUrl;
  final String? spotifyUrl;

  Track({
    required this.id,
    required this.name,
    required this.artistName,
    this.albumName,
    this.imageUrl,
    required this.durationMs,
    required this.popularity,
    this.previewUrl,
    this.spotifyUrl,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    final album = json['album'] as Map<String, dynamic>?;
    final images = album?['images'] as List?;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      imageUrl = images[0]['url'];
    }

    final artists = json['artists'] as List?;
    String artistName = 'Unknown Artist';
    if (artists != null && artists.isNotEmpty) {
      artistName = artists[0]['name'] ?? 'Unknown Artist';
    }

    return Track(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Track',
      artistName: artistName,
      albumName: album?['name'],
      imageUrl: imageUrl,
      durationMs: json['duration_ms'] ?? 0,
      popularity: json['popularity'] ?? 0,
      previewUrl: json['preview_url'],
      spotifyUrl: json['external_urls']?['spotify'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artists': [{'name': artistName}],
      'album': {
        'name': albumName,
        'images': imageUrl != null ? [{'url': imageUrl}] : [],
      },
      'duration_ms': durationMs,
      'popularity': popularity,
      'preview_url': previewUrl,
      'external_urls': {'spotify': spotifyUrl},
    };
  }

  String get durationFormatted {
    final minutes = durationMs ~/ 60000;
    final seconds = (durationMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
