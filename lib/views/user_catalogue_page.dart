import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/Controllers/media_controller.dart';
import 'package:mediatech/models/media_model.dart';

import 'media_detail_page.dart';

class CataloguePage extends ConsumerStatefulWidget {
  const CataloguePage({super.key});

  @override
  ConsumerState<CataloguePage> createState() => _CataloguePageState();
}

class _CataloguePageState extends ConsumerState<CataloguePage> {
  String searchQuery = '';
  String? filterType;
  String? selectedGenre;
  String? selectedCategory;
  bool gridView = true;

  @override
  Widget build(BuildContext context) {
    final mediaState = ref.watch(mediaControllerProvider);
    final mediaList = mediaState.media;

    // ------------------------- FILTERS LOGIC -------------------------
    final filteredMedia = mediaList.where((media) {
      final q = searchQuery.toLowerCase();

      final matchesSearch =
          media.title.toLowerCase().contains(q) ||
          media.author.toLowerCase().contains(q) ||
          media.typeDisplayName.toLowerCase().contains(q) ||
          media.genre.toLowerCase().contains(q) ||
          media.tags.any((t) => t.toLowerCase().contains(q));

      final matchesType = (filterType == null || media.typeDisplayName == filterType);
      final matchesGenre = (selectedGenre == null || media.genre == selectedGenre);
      final matchesCategory = (selectedCategory == null || media.typeDisplayName == selectedCategory);

      return matchesSearch && matchesType && matchesGenre && matchesCategory;
    }).toList();

    // Extract unique genres & categories
    final genres = mediaList.map((e) => e.genre).toSet().toList()..sort();
    final categories = mediaList.map((e) => e.typeDisplayName).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Catalogue",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(gridView ? Icons.view_list : Icons.grid_view, color: Colors.black87),
            onPressed: () => setState(() => gridView = !gridView),
          )
        ],
      ),

      body: Column(
        children: [

          // ------------------------- SEARCH BAR -------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Rechercher titre, auteur, tags...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (val) => setState(() => searchQuery = val),
              ),
            ),
          ),

          // ------------------------- FILTER CHIPS -------------------------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 6),
            child: Row(
              children: [

                _filterChip(
                  label: "Tous",
                  selected: filterType == null,
                  onTap: () => setState(() => filterType = null),
                ),

                const SizedBox(width: 6),

                for (var type in ["Book", "Magazine", "Movie", "Music", "Game"])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _filterChip(
                      label: type,
                      selected: filterType == type,
                      onTap: () => setState(() => filterType = type),
                    ),
                  )
              ],
            ),
          ),

          // ------------------------- GENRE & CATEGORY FILTERS -------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _dropdown("Genre", genres, selectedGenre,
                    (value) => setState(() => selectedGenre = value))),
                const SizedBox(width: 12),
                Expanded(child: _dropdown("Catégorie", categories, selectedCategory,
                    (value) => setState(() => selectedCategory = value))),
              ],
            ),
          ),


          // ------------------------- MEDIA LIST / GRID -------------------------
          Expanded(
            child: mediaState.loading
                ? const Center(child: CircularProgressIndicator())
                : filteredMedia.isEmpty
                    ? const Center(child: Text("Aucun média trouvé"))
                    : gridView
                        ? _buildGrid(filteredMedia)
                        : _buildList(filteredMedia),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // UI COMPONENTS
  // ---------------------------------------------------------------------

  Widget _filterChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.red : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Colors.red : Colors.grey.shade300),
          boxShadow: selected
              ? [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String hint,
    List<String> items,
    String? selected,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        hint: Text(hint),
        value: selected,
        underline: const SizedBox.shrink(),
        items: [
          const DropdownMenuItem(value: null, child: Text("Tous")),
          ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
        ],
        onChanged: onChanged,
      ),
    );
  }

  // GRID ----------------------------------------------------
  Widget _buildGrid(List<MediaModel> media) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) => _mediaCard(media[index]),
    );
  }

  // LIST ----------------------------------------------------
  Widget _buildList(List<MediaModel> media) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: media.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _mediaTile(media[index]),
      ),
    );
  }

  // CARD (Grid) ---------------------------------------------------------
  Widget _mediaCard(MediaModel media) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => MediaDetailPage(media: media))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COVER IMAGE
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                media.coverUrl,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(media.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(media.author,
                      style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 2),

                  // CATEGORY + GENRE chips
                  Wrap(
                    spacing: 6,
                    children: [
                      _chipSmall(media.typeDisplayName),
                      _chipSmall(media.genre),
                    ],
                  ),

              

                  Text(
                    "${media.availableCount}/${media.totalCount} disponible",
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          media.availableCount > 0 ? Colors.green : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // LIST TILE (list view) ----------------------------------------------
  Widget _mediaTile(MediaModel media) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => MediaDetailPage(media: media))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              child: Image.network(media.coverUrl,
                  height: 110, width: 90, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(media.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(media.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54)),

                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 6,
                      children: [
                        _chipSmall(media.typeDisplayName),
                        _chipSmall(media.genre),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "${media.availableCount}/${media.totalCount} disponible",
                      style: TextStyle(
                        fontSize: 12,
                        color: media.availableCount > 0
                            ? Colors.green
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _chipSmall(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.blueAccent)),
    );
  }
}
