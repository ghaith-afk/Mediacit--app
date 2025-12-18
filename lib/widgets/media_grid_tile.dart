// widgets/media_grid_tile.dart
import 'package:flutter/material.dart';
import 'package:mediatech/models/media_model.dart';

class MediaGridTile extends StatelessWidget {
  final MediaModel media;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool listView;

  const MediaGridTile({
    super.key,
    required this.media,
    required this.onTap,
    required this.onDelete,
    this.listView = false,
  });

  @override
  Widget build(BuildContext context) {
    if (listView) {
      return _buildListView();
    }
    return _buildGridView();
  }

  Widget _buildGridView() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.grey.shade100,
                ),
                child: media.coverUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          media.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        ),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            // Media Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      media.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Author
                    Text(
                      media.author,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                   

                    // Metadata Row
                    Row(
                      children: [
                        // Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTypeColor(media.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            media.typeDisplayName,
                            style: TextStyle(
                              fontSize: 8,
                              color: _getTypeColor(media.type),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Availability
                        Icon(
                          media.availableCount > 0 ? Icons.check_circle : Icons.cancel,
                          size: 14,
                          color: media.availableCount > 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${media.availableCount}',
                          style: TextStyle(
                            fontSize: 11,
                            color: media.availableCount > 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: media.coverUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          media.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        ),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),

              // Media Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Featured
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            media.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (media.featured)
                          Icon(Icons.star, size: 16, color: Colors.orange.shade600),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Author
                    Text(
                      media.author,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Metadata
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTypeColor(media.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            media.typeDisplayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getTypeColor(media.type),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            media.genre,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: media.availableCount > 0 
                                ? Colors.green.shade100 
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                media.availableCount > 0 ? Icons.check_circle : Icons.cancel,
                                size: 10,
                                color: media.availableCount > 0 ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${media.availableCount} available',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: media.availableCount > 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: _getTypeColor(media.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getTypeIcon(media.type), color: _getTypeColor(media.type), size: 32),
          const SizedBox(height: 4),
          Text(
            media.typeDisplayName,
            style: TextStyle(
              color: _getTypeColor(media.type),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(MediaType type) {
    switch (type) {
      case MediaType.book: return const Color(0xFF6B0E2A);
      case MediaType.movie: return const Color(0xFF001F3F);
      case MediaType.magazine: return Colors.orange.shade700;
      case MediaType.music: return Colors.purple.shade700;
      case MediaType.game: return Colors.green.shade700;
    }
  }

  IconData _getTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.book: return Icons.menu_book;
      case MediaType.movie: return Icons.movie;
      case MediaType.magazine: return Icons.article;
      case MediaType.music: return Icons.music_note;
      case MediaType.game: return Icons.sports_esports;
    }
  }
}