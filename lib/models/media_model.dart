// models/media_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType { book, magazine, movie, music, game }

class MediaModel {
  final String id;
  final String title;
  final String author;
  final MediaType type;
  final String description;
  final String coverUrl;
  final String? imageFile; // For uploaded images
  final int pagesOrDuration;
  final int totalCount;
  final int availableCount;
  final List<String> tags;
  final double rating;
  final String isbn;
  final String genre;
  final String publisher;
  final int publicationYear;
  final String language;
  final bool featured;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  MediaModel({
    required this.id,
    required this.title,
    required this.author,
    required this.type,
    required this.description,
    required this.coverUrl,
    this.imageFile,
    required this.pagesOrDuration,
    required this.totalCount,
    required this.availableCount,
    required this.tags,
    required this.rating,
    required this.isbn,
    required this.genre,
    required this.publisher,
    required this.publicationYear,
    required this.language,
    this.featured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MediaModel.fromMap(String id, Map<String, dynamic> data) {
    return MediaModel(
      id: id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      type: _stringToMediaType(data['type'] ?? 'book'),
      description: data['description'] ?? '',
      coverUrl: data['coverUrl'] ?? '',
      imageFile: data['imageFile'],
      pagesOrDuration: (data['pagesOrDuration'] ?? 0) as int,
      totalCount: (data['totalCount'] ?? 1) as int,
      availableCount: (data['availableCount'] ?? 1) as int,
      tags: List<String>.from(data['tags'] ?? []),
      rating: (data['rating'] ?? 0.0).toDouble(),
      isbn: data['isbn'] ?? '',
      genre: data['genre'] ?? '',
      publisher: data['publisher'] ?? '',
      publicationYear: (data['publicationYear'] ?? DateTime.now().year) as int,
      language: data['language'] ?? 'English',
      featured: data['featured'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'type': _mediaTypeToString(type),
      'description': description,
      'coverUrl': coverUrl,
      'imageFile': imageFile,
      'pagesOrDuration': pagesOrDuration,
      'totalCount': totalCount,
      'availableCount': availableCount,
      'tags': tags,
      'rating': rating,
      'isbn': isbn,
      'genre': genre,
      'publisher': publisher,
      'publicationYear': publicationYear,
      'language': language,
      'featured': featured,
      'createdAt': createdAt,
      'updatedAt': Timestamp.now(),
    };
  }

  static MediaType _stringToMediaType(String s) {
    switch (s) {
      case 'movie': return MediaType.movie;
      case 'magazine': return MediaType.magazine;
      case 'music': return MediaType.music;
      case 'game': return MediaType.game;
      default: return MediaType.book;
    }
  }

  static String _mediaTypeToString(MediaType type) {
    switch (type) {
      case MediaType.movie: return 'movie';
      case MediaType.magazine: return 'magazine';
      case MediaType.music: return 'music';
      case MediaType.game: return 'game';
      default: return 'book';
    }
  }

  // ADD THIS COPYWITH METHOD
  MediaModel copyWith({
    String? id,
    String? title,
    String? author,
    MediaType? type,
    String? description,
    String? coverUrl,
    String? imageFile,
    int? pagesOrDuration,
    int? totalCount,
    int? availableCount,
    List<String>? tags,
    double? rating,
    String? isbn,
    String? genre,
    String? publisher,
    int? publicationYear,
    String? language,
    bool? featured,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return MediaModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      type: type ?? this.type,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      imageFile: imageFile ?? this.imageFile,
      pagesOrDuration: pagesOrDuration ?? this.pagesOrDuration,
      totalCount: totalCount ?? this.totalCount,
      availableCount: availableCount ?? this.availableCount,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      isbn: isbn ?? this.isbn,
      genre: genre ?? this.genre,
      publisher: publisher ?? this.publisher,
      publicationYear: publicationYear ?? this.publicationYear,
      language: language ?? this.language,
      featured: featured ?? this.featured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case MediaType.book: return 'Book';
      case MediaType.movie: return 'Movie';
      case MediaType.magazine: return 'Magazine';
      case MediaType.music: return 'Music';
      case MediaType.game: return 'Game';
    }
  }

  String get unitDisplay {
    switch (type) {
      case MediaType.book: return 'pages';
      case MediaType.magazine: return 'pages';
      case MediaType.movie: return 'minutes';
      case MediaType.music: return 'tracks';
      case MediaType.game: return 'hours';
    }
  }
}