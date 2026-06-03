import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/menu_item_model.dart';
import '../../../../core/services/ordering_service.dart';
import '../../../../../../../core/constants/app_colors.dart';

class AddMenuItemScreen extends StatefulWidget {
  final MenuItemModel? item;

  const AddMenuItemScreen({Key? key, this.item}) : super(key: key);

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _prepTimeController = TextEditingController();

  String _selectedCategory = 'food';
  File? _imageFile;
  bool _isLoading = false;
  int? _hotelId;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'food', 'label': '🍽️ Food'},
    {'value': 'drinks', 'label': '🥤 Drinks'},
    {'value': 'spa', 'label': '💆 Spa & Wellness'},
    {'value': 'laundry', 'label': '👕 Laundry'},
    {'value': 'transport', 'label': '🚗 Transport'},
    {'value': 'other', 'label': '📦 Other Services'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHotelId();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _descriptionController.text = widget.item!.description ?? '';
      _priceController.text = widget.item!.price.toString();
      _prepTimeController.text = widget.item!.preparationTime.toString();
      _selectedCategory = widget.item!.category;
    } else {
      _prepTimeController.text = '15';
    }
  }

  Future<void> _loadHotelId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hotelId = prefs.getInt('selected_hotel_id');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hotelId == null) {
      _showError('Hotel not selected');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showError('Please login first');
        setState(() => _isLoading = false);
        return;
      }

      final price = double.parse(_priceController.text);
      final prepTime = int.parse(_prepTimeController.text);

      Map<String, dynamic> response;

      if (widget.item == null) {
        // Create new item
        response = await OrderingService.createMenuItem(
          token: token,
          hotelId: _hotelId!,
          category: _selectedCategory,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          price: price,
          preparationTime: prepTime,
          image: _imageFile,
        );
      } else {
        // Update existing item
        response = await OrderingService.updateMenuItem(
          token: token,
          itemId: widget.item!.id,
          category: _selectedCategory,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          price: price,
          preparationTime: prepTime,
          image: _imageFile,
        );
      }

      setState(() => _isLoading = false);

      if (response['status'] == true) {
        _showSuccess(widget.item == null
            ? 'Menu item created successfully'
            : 'Menu item updated successfully');
        if (mounted) context.pop(true);
      } else {
        _showError(response['message'] ?? 'Failed to save menu item');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 24),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Item Name',
              hint: 'e.g., Chicken Momo',
              icon: Icons.restaurant,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              hint: 'Brief description of the item',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _priceController,
              label: 'Price (NPR)',
              hint: '0.00',
              icon: Icons.attach_money,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter price';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Please enter valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _prepTimeController,
              label: 'Preparation Time (minutes)',
              hint: '15',
              icon: Icons.timer,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter preparation time';
                }
                final time = int.tryParse(value);
                if (time == null || time <= 0) {
                  return 'Please enter valid time';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.item == null ? 'Add Menu Item' : 'Update Menu Item',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.gray[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGray!),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
            : widget.item?.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(widget.item!.image!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 48, color: AppColors.gray[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add image',
                        style: TextStyle(color: AppColors.gray[600]),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat['value'];
            return ChoiceChip(
              label: Text(cat['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = cat['value'] as String);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
    );
  }
}
