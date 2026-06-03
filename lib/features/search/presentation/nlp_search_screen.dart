import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class NlpSearchScreen extends StatefulWidget {
  const NlpSearchScreen({Key? key}) : super(key: key);

  @override
  State<NlpSearchScreen> createState() => _NlpSearchScreenState();
}

class _NlpSearchScreenState extends State<NlpSearchScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  List<Map<String, dynamic>> _results = [];
  List<String> _suggestions = [];
  List<String> _popular = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPopular();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPopular() async {
    try {
      final response = await ApiService.get('/search/popular');
      if (response['success'] == true) {
        final data = response['data'];
        List raw = data is List ? data : (data is Map ? (data['terms'] ?? data['popular'] ?? []) : []);
        setState(() => _popular = List<String>.from(raw.map((e) => e.toString())));
      }
    } catch (_) {}
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    setState(() { _searching = true; _error = null; _results = []; });
    try {
      final response = await ApiService.get('/search/nlp', queryParams: {'q': query});
      if (response['success'] == true) {
        final data = response['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['hotels'] ?? data['results'] ?? []) : []);
        setState(() { _results = List<Map<String, dynamic>>.from(raw); _searching = false; });
      } else {
        setState(() { _error = response['message'] ?? 'No results found'; _searching = false; });
      }
    } catch (e) {
      setState(() { _error = 'Search failed'; _searching = false; });
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.length < 2) { setState(() => _suggestions = []); return; }
    try {
      final response = await ApiService.get('/search/suggestions', queryParams: {'q': query});
      if (response['success'] == true) {
        final data = response['data'];
        List raw = data is List ? data : (data is Map ? (data['suggestions'] ?? []) : []);
        setState(() => _suggestions = List<String>.from(raw.map((e) => e.toString())));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray), onPressed: () => Navigator.pop(context)),
        title: const Text('Smart Search', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _getSuggestions,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'e.g. "pet friendly hotel in Pokhara under 3000"',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.placeholder),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, color: AppColors.gray), onPressed: () { _searchCtrl.clear(); setState(() { _results = []; _suggestions = []; }); })
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Suggestions
          if (_suggestions.isNotEmpty)
            Container(
              color: Colors.white,
              child: Column(
                children: _suggestions.take(5).map((s) => ListTile(
                  leading: const Icon(Icons.search_rounded, color: AppColors.gray, size: 18),
                  title: Text(s, style: const TextStyle(fontSize: 14, color: AppColors.darkGray)),
                  onTap: () { _searchCtrl.text = s; _search(s); setState(() => _suggestions = []); },
                  dense: true,
                )).toList(),
              ),
            ),

          Expanded(
            child: _searching
                ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Searching...', style: TextStyle(color: AppColors.gray)),
                  ]))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.gray)))
                    : _results.isNotEmpty
                        ? _buildResults()
                        : _buildInitialState(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final hotel = _results[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
          child: Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.hotel_rounded, color: AppColors.gray, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hotel['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                Text(hotel['city'] ?? hotel['address'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                const SizedBox(height: 4),
                if ((hotel['min_price'] ?? hotel['price']) != null)
                  Text('From NPR ${hotel['min_price'] ?? hotel['price']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ])),
              if ((hotel['star_rating'] ?? hotel['rating']) != null)
                Row(children: [
                  const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                  Text('${hotel['star_rating'] ?? hotel['rating']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 10),
                const Text('Natural Language Search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 6),
                const Text('Describe what you\'re looking for in plain language.', style: TextStyle(fontSize: 12, color: Colors.white70), textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Try searching for:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          const SizedBox(height: 12),
          ...[
            'Pet friendly hotel in Pokhara under 3000',
            'Luxury resort with pool near Kathmandu',
            'Budget hotel with free breakfast',
            'Hotel with mountain view for 2 nights',
          ].map((example) => GestureDetector(
            onTap: () { _searchCtrl.text = example; _search(example); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppColors.cardShadow),
              child: Row(children: [
                const Icon(Icons.search_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(example, style: const TextStyle(fontSize: 13, color: AppColors.darkGray))),
                const Icon(Icons.north_west_rounded, size: 14, color: AppColors.gray),
              ]),
            ),
          )),
          if (_popular.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Trending Searches', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _popular.map((term) => GestureDetector(
                onTap: () { _searchCtrl.text = term; _search(term); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                  child: Text(term, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
