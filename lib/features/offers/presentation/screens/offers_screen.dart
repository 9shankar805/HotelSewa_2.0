import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/offer_model.dart';
import '../providers/offers_provider.dart';
import '../widgets/offer_card.dart';
import '../widgets/offer_form_modal.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/offer_analytics_modal.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  Future<void> _initializeProvider() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final offersProvider = Provider.of<OffersProvider>(context, listen: false);
    
    final token = authProvider.token;
    if (token != null) {
      offersProvider.setToken(token);
      await _loadOffers();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    final offersProvider = Provider.of<OffersProvider>(context, listen: false);
    await offersProvider.loadOffers();
  }

  Future<void> _onRefresh() async {
    await _loadOffers();
  }

  void _showAddOfferModal() {
    showDialog(
      context: context,
      builder: (context) => OfferFormModal(
        onSave: (offer) async {
          final success = await _createOffer(offer);
          if (success) {
            Navigator.of(context).pop();
            _showSuccessMessage('Offer created successfully');
          }
          return success;
        },
      ),
    );
  }

  Future<bool> _createOffer(Offer offer) async {
    final offersProvider = Provider.of<OffersProvider>(context, listen: false);
    return await offersProvider.createOffer(offer);
  }

  void _showEditOfferModal(Offer offer) {
    showDialog(
      context: context,
      builder: (context) => OfferFormModal(
        offer: offer,
        onSave: (updatedOffer) async {
          final success = await _updateOffer(updatedOffer);
          if (success) {
            Navigator.of(context).pop();
            _showSuccessMessage('Offer updated successfully');
          }
          return success;
        },
      ),
    );
  }

  Future<bool> _updateOffer(Offer offer) async {
    final offersProvider = Provider.of<OffersProvider>(context, listen: false);
    return await offersProvider.updateOffer(offer);
  }

  void _showDeleteConfirmation(Offer offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: Text('Are you sure you want to delete "${offer.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _deleteOffer(offer.id);
              if (success) {
                _showSuccessMessage('Offer deleted successfully');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool> _deleteOffer(String offerId) async {
    final offersProvider = Provider.of<OffersProvider>(context, listen: false);
    return await offersProvider.deleteOffer(offerId);
  }

  void _showOfferAnalytics(Offer offer) {
    showDialog(
      context: context,
      builder: (context) => OfferAnalyticsModal(offer: offer),
    );
  }

  void _toggleOfferStatus(Offer offer) async {
    final offersProvider = Provider.of<OffersProvider>(context, listen: false);
    final success = await offersProvider.toggleOfferStatus(offer.id, !offer.isActive);
    if (success) {
      _showSuccessMessage('Offer status updated successfully');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Offer> _getFilteredOffers() {
    final offersProvider = Provider.of<OffersProvider>(context);
    List<Offer> offers = [];

    switch (_tabController.index) {
      case 0: // All
        offers = offersProvider.offers;
        break;
      case 1: // Active
        offers = offersProvider.activeOffers;
        break;
      case 2: // Inactive
        offers = offersProvider.inactiveOffers;
        break;
      case 3: // Upcoming
        offers = offersProvider.upcomingOffers;
        break;
      case 4: // Expired
        offers = offersProvider.expiredOffers;
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      offers = offers.where((offer) {
        return offer.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               offer.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               offer.discountText.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return offers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offers & Promotions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE60023),
          labelColor: const Color(0xFFE60023),
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Inactive'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Expired'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddOfferModal,
          ),
        ],
      ),
      body: Consumer<OffersProvider>(
        builder: (context, offersProvider, child) {
          if (offersProvider.isLoading && offersProvider.offers.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE60023),
              ),
            );
          }

          if (offersProvider.error != null && offersProvider.offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.gray[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading offers',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.gray[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offersProvider.error!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE60023),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final filteredOffers = _getFilteredOffers();

          return Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.gray[50],
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search offers...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE60023)),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Statistics cards
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildStatCard('Total', offersProvider.offers.length),
                    _buildStatCard('Active', offersProvider.activeOffers.length),
                    _buildStatCard('Expired', offersProvider.expiredOffers.length),
                  ],
                ),
              ),

              // Offers list
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: List.generate(5, (index) {
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: const Color(0xFFE60023),
                      child: filteredOffers.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredOffers.length,
                              itemBuilder: (context, index) {
                                final offer = filteredOffers[index];
                                return OfferCard(
                                  offer: offer,
                                  onEdit: () => _showEditOfferModal(offer),
                                  onDelete: () => _showDeleteConfirmation(offer),
                                  onToggleStatus: () => _toggleOfferStatus(offer),
                                  onViewAnalytics: () => _showOfferAnalytics(offer),
                                );
                              },
                            ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, int count) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightGray!),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE60023),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 64,
            color: AppColors.gray[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No offers found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.gray[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'Create your first offer to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddOfferModal,
              icon: const Icon(Icons.add),
              label: const Text('Create Offer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE60023),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
