class Artist {
  final String id;
  final String name;
  final List<String> genres;
  final int popularity;
  final int followers;
  final String? imageUrl;
  final String? spotifyUrl;

  Artist({
    required this.id,
    required this.name,
    required this.genres,
    required this.popularity,
    required this.followers,
    this.imageUrl,
    this.spotifyUrl,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      imageUrl = images[0]['url'];
    }

    return Artist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Artist',
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      popularity: json['popularity'] ?? 0,
      followers: json['followers']?['total'] ?? 0,
      imageUrl: imageUrl,
      spotifyUrl: json['external_urls']?['spotify'],
    );
  }
}
