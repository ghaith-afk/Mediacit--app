// widgets/media_tile.dart
import 'package:flutter/material.dart';
import 'package:mediatech/models/media_model.dart';

class MediaTile extends StatelessWidget {
  final MediaModel media;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MediaTile({
    super.key,
    required this.media,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image - Fixed with better error handling
            _buildCoverImage(),
            const SizedBox(width: 12),

            // Media Info - Properly constrained
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row with proper constraints
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          media.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (media.featured) _buildFeaturedBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Author
                  Text(
                    'by ${media.author}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Chips - Fixed overflow with proper wrapping
                  _buildChipsRow(),
                  const SizedBox(height: 8),
                  
                  // Bottom info row
                  _buildBottomInfoRow(),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                onSelected: (value) {
                  switch (value) {
                    case 'edit': onEdit(); break;
                    case 'delete': onDelete(); break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit Media'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Media'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    final hasValidImage = media.coverUrl.isNotEmpty ;
    
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: hasValidImage
            ? Image.network(
                media.coverUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholder();
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: _getTypeColor(media.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getTypeIcon(media.type), 
        color: _getTypeColor(media.type), 
        size: 24
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: Colors.orange.shade700),
          const SizedBox(width: 4),
          Text(
            'Featured',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsRow() {
    final chips = <Widget>[
      _buildInfoChip(media.typeDisplayName, _getTypeColor(media.type)),
      _buildInfoChip(media.genre, Colors.grey.shade600),
      if (media.pagesOrDuration > 0)
        _buildInfoChip('${media.pagesOrDuration} ${media.unitDisplay}', Colors.blue.shade600),
      _buildAvailabilityChip(),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }

  Widget _buildBottomInfoRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showIsbn = constraints.maxWidth > 200 && media.isbn.isNotEmpty;
        
        return Row(
          children: [
            // Availability info
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${media.availableCount}/${media.totalCount} available',
                      style: TextStyle(
                        fontSize: 12,
                        color: media.availableCount > 0 ? Colors.green.shade600 : Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            if (showIsbn) const Spacer(),
            
            // ISBN - Only show if there's space
            if (showIsbn)
              Flexible(
                flex: 2,
                child: Text(
                  'ISBN: ${media.isbn}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAvailabilityChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: media.availableCount > 0 ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            media.availableCount > 0 ? Icons.check_circle : Icons.cancel,
            size: 10,
            color: media.availableCount > 0 ? Colors.green.shade600 : Colors.red.shade600,
          ),
          const SizedBox(width: 3),
          Text(
            media.availableCount > 0 ? 'Available' : 'Out of Stock',
            style: TextStyle(
              fontSize: 10,
              color: media.availableCount > 0 ? Colors.green.shade600 : Colors.red.shade600,
              fontWeight: FontWeight.w500,
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