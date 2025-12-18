// views/admin/media_management_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/controllers/media_controller.dart';
import 'package:mediatech/models/media_model.dart';
import 'package:mediatech/views/admin/media_form_dialog.dart';
import 'package:mediatech/widgets/confirm_dialog.dart';
import 'package:mediatech/widgets/media_grid_tile.dart';

class MediaManagementView extends ConsumerStatefulWidget {
  const MediaManagementView({super.key});

  @override
  ConsumerState<MediaManagementView> createState() => _MediaManagementViewState();
}

class _MediaManagementViewState extends ConsumerState<MediaManagementView> {
  String _search = '';
  String _filter = 'All';
  final _searchController = TextEditingController();
  bool _showFilters = false;
  bool _gridView = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, int> _getFilterCounts(List<MediaModel> media) {
    return {
      'All': media.length,
      'Books': media.where((m) => m.type == MediaType.book).length,
      'Movies': media.where((m) => m.type == MediaType.movie).length,
      'Magazines': media.where((m) => m.type == MediaType.magazine).length,
      'Available': media.where((m) => m.availableCount > 0).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaControllerProvider);
    final controller = ref.read(mediaControllerProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final filteredMedia = state.media.where((m) {
      final matchesSearch = m.title.toLowerCase().contains(_search.toLowerCase()) ||
          m.author.toLowerCase().contains(_search.toLowerCase()) ||
          m.genre.toLowerCase().contains(_search.toLowerCase()) ||
          m.isbn.toLowerCase().contains(_search.toLowerCase());
      final matchesFilter = switch (_filter) {
        'Books' => m.type == MediaType.book,
        'Movies' => m.type == MediaType.movie,
        'Magazines' => m.type == MediaType.magazine,
        'Available' => m.availableCount > 0,
        _ => true,
      };
      return matchesSearch && matchesFilter;
    }).toList();

    final filterCounts = _getFilterCounts(state.media);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with Safe Area
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Title and Actions
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Media ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF001F3F),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _gridView ? Icons.view_list : Icons.grid_view,
                        color: const Color(0xFF6B0E2A),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _gridView = !_gridView),
                      tooltip: _gridView ? 'List View' : 'Grid View',
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Color(0xFF6B0E2A), size: 20),
                      onPressed: () => setState(() => _showFilters = !_showFilters),
                      tooltip: 'Filters',
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const MediaFormDialog(),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6B0E2A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16),
                          SizedBox(width: 4),
                          Text('Add Media'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6B0E2A)),
                    hintText: 'Search by title, author, genre, ISBN...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),

          // Filters - Now directly under search when shown
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterChip('All', filterCounts['All']!, _filter == 'All'),
                  _buildFilterChip('Books', filterCounts['Books']!, _filter == 'Books'),
                  _buildFilterChip('Movies', filterCounts['Movies']!, _filter == 'Movies'),
                  _buildFilterChip('Magazines', filterCounts['Magazines']!, _filter == 'Magazines'),
                  _buildFilterChip('Available', filterCounts['Available']!, _filter == 'Available'),
                ],
              ),
            ),

          // Messages
          if (state.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: controller.clearMessages,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          if (state.success != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.success!,
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: controller.clearMessages,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Results Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Text(
                  '${filteredMedia.length} items',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (_search.isNotEmpty || _filter != 'All')
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _search = '';
                        _filter = 'All';
                        _showFilters = false;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: const Color(0xFF6B0E2A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: controller.loadMedia,
                  tooltip: 'Refresh',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Media Grid/List - MAIN CONTENT AREA
          Expanded(
            child: state.loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF6B0E2A),
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Loading Media...',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : filteredMedia.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.library_books_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _search.isEmpty ? 'No Media Found' : 'No matches found',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _search.isEmpty 
                                    ? 'Start by adding your first media item to the library'
                                    : 'Try adjusting your search terms or filters',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: _search.isEmpty 
                                    ? () => showDialog(
                                          context: context,
                                          builder: (_) => const MediaFormDialog(),
                                        )
                                    : () {
                                        _searchController.clear();
                                        setState(() {
                                          _search = '';
                                          _filter = 'All';
                                          _showFilters = false;
                                        });
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B0E2A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Text(_search.isEmpty ? 'Add First Media' : 'Clear Search'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _gridView
                        ? _buildMediaGrid(filteredMedia, controller, isMobile)
                        : _buildMediaList(filteredMedia, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, bool isSelected) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : const Color(0xFF6B0E2A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF6B0E2A) : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filter = selected ? label : 'All'),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF6B0E2A),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF6B0E2A) : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildMediaGrid(List<MediaModel> media, MediaController controller, bool isMobile) {
    final crossAxisCount = isMobile ? 2 : 3;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        itemCount: media.length,
        itemBuilder: (context, index) {
          final item = media[index];
          return MediaGridTile(
            media: item,
            onTap: () => showDialog(
              context: context,
              builder: (_) => MediaFormDialog(media: item),
            ),
            onDelete: () => _confirmDelete(item, controller),
          );
        },
      ),
    );
  }

  Widget _buildMediaList(List<MediaModel> media, MediaController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: MediaGridTile(
            media: item,
            onTap: () => showDialog(
              context: context,
              builder: (_) => MediaFormDialog(media: item),
            ),
            onDelete: () => _confirmDelete(item, controller),
            listView: true,
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(MediaModel media, MediaController controller) async {
    final confirm = await showConfirmDialog(
      context,
      'Delete Media?',
      'This will permanently delete "${media.title}" and all associated data.',
    );
    if (confirm) {
      await controller.deleteMedia(media.id);
    }
  }
}