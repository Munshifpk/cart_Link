import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'product_aded.dart';
import '../services/product_service.dart';
import '../services/auth_state.dart';
import '../services/upload_service.dart';
import 'package:cart_link/theme_data.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _mrpController = TextEditingController();
  bool _inStock = true;
  final _skuController = TextEditingController();
  final _colorController = TextEditingController();
  final _sizeController = TextEditingController();
  final _materialController = TextEditingController();
  final _weightController = TextEditingController();
  final _brandController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  String? _category;
  // final List<String> _images = [];
  bool _isActive = true;
  bool _isFeatured = false;
  bool _loading = false;
  final List<XFile> _pickedImages = [];

  final List<String> _categories = [
    'Groceries',
    'Electronics',
    'Fashion',
    'Home & Kitchen',
    'Beauty & Personal Care',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _skuController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _materialController.dispose();
    _weightController.dispose();
    _brandController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImages.isEmpty) {
      // Ask user whether to continue without images
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No images selected'),
          content: const Text(
            'You have not selected any images. Do you want to continue without images?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (_pickedImages.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 images allowed')),
      );
      return;
    }
    setState(() => _loading = true);

    // Upload images to Cloudinary and collect URLs
    final List<String> imageUrls = [];
    if (_pickedImages.isNotEmpty) {
      for (final x in _pickedImages) {
        try {
          final bytes = await x.readAsBytes();
          final b64 = base64Encode(bytes);
          final path = x.path.toLowerCase();
          final mime = path.endsWith('.png') ? 'image/png' : 'image/jpeg';
          final base64WithMime = 'data:$mime;base64,$b64';
          
          // Upload to Cloudinary
          final uploadResult = await UploadService.uploadImage(base64WithMime);
          
          if (uploadResult['success'] == true && uploadResult['url'] != null) {
            imageUrls.add(uploadResult['url']);
            print('[IMAGE_UPLOAD] Uploaded: ${uploadResult['url']}');
          } else {
            print('[IMAGE_UPLOAD_ERROR] ${uploadResult['message']}');
          }
        } catch (e) {
          print('[IMAGE_UPLOAD_ERROR] Failed to upload image: $e');
        }
      }
    }

    final payload = {
      'name': _nameController.text,
      'description': _descController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'mrp':
          double.tryParse(_mrpController.text) ??
          double.tryParse(_priceController.text) ??
          0.0,
      'inStock': _inStock,
      'sku': _skuController.text,
      'category': _category,
      'color': _colorController.text.trim().isNotEmpty
          ? _colorController.text.trim()
          : null,
      'size': _sizeController.text.trim().isNotEmpty
          ? _sizeController.text.trim()
          : null,
      'material': _materialController.text.trim().isNotEmpty
          ? _materialController.text.trim()
          : null,
      'weight': _weightController.text.trim().isNotEmpty
          ? _weightController.text.trim()
          : null,
      'brand': _brandController.text.trim().isNotEmpty
          ? _brandController.text.trim()
          : null,
      'length': _lengthController.text.trim().isNotEmpty
          ? _lengthController.text.trim()
          : null,
      'width': _widthController.text.trim().isNotEmpty
          ? _widthController.text.trim()
          : null,
      'height': _heightController.text.trim().isNotEmpty
          ? _heightController.text.trim()
          : null,
      'isActive': _isActive,
      'isFeatured': _isFeatured,
      'images': imageUrls,
      // include ownerId if present
      'ownerId': AuthState.currentOwner != null
          ? AuthState.currentOwner!['_id']
          : null,
    };

    try {
      print('[PRODUCT_SUBMIT] Sending payload: ${payload.keys.join(', ')}');
      print(
        '[PRODUCT_SUBMIT] Owner: ${payload['ownerId']}, Images: ${imageUrls.length}',
      );
      final res = await ProductService.createProduct(payload).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('[PRODUCT_SUBMIT_TIMEOUT] Request timed out after 30s');
          return {
            'success': false,
            'message':
                'Request timed out. Product may have been saved, please refresh.',
          };
        },
      );
      if (!mounted) return;
      setState(() => _loading = false);
      if (res['success'] == true) {
        print('[PRODUCT_SUBMIT] Success!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProductAddedSuccess()),
        );
      } else {
        print('[PRODUCT_SUBMIT] Failed: ${res['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to add product')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      print('[PRODUCT_SUBMIT_ERROR] Exception: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting product: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Boost Your Sales',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ThemeColors.primary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: ThemeColors.white),
                  )
                  : const Icon(Icons.rocket_launch, color: Colors.white),
            label: const Text(
              'Launch Product',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ThemeColors.primaryDark,
              ThemeColors.background,
              ThemeColors.background,
            ],
            stops: const [0.0, 0.12, 0.24],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ThemeColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ThemeColors.success.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              ThemeColors.success.withOpacity(0.2),
                          child: Icon(
                            Icons.trending_up,
                            color: ThemeColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ready to Grow? 🚀',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Products with complete details sell 2x faster!',
                                style: const TextStyle(
                                  color: ThemeColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image picker with enhanced design and thumbnails
                  GestureDetector(
                    onTap: _pickedImages.length < 10 ? _pickImages : null,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ThemeColors.accent.withOpacity(0.08),
                              ThemeColors.surface,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ThemeColors.accent.withOpacity(0.3),
                          ),
                        ),
                        child: _pickedImages.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          ThemeColors.accent.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: ThemeColors.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Add Stunning Product Photos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add 1-10 images (${_pickedImages.length}/10 selected)',
                                    style: const TextStyle(
                                      color: ThemeColors.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      height: 110,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        shrinkWrap: true,
                                        itemBuilder: (c, i) {
                                          final x = _pickedImages[i];
                                          return Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              FutureBuilder<Widget>(
                                                future: _buildThumbnail(x),
                                                builder: (ctx, snap) {
                                                  if (!mounted) {
                                                    return const SizedBox.shrink();
                                                  }
                                                  if (snap.connectionState ==
                                                          ConnectionState
                                                              .done &&
                                                      snap.hasData) {
                                                    return snap.data!;
                                                  }
                                                  return Container(
                                                    width: 100,
                                                    height: 100,
                                                    color: ThemeColors.surface,
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  );
                                                },
                                              ),
                                              GestureDetector(
                                                onTap: () {
                                                  if (!mounted) return;
                                                  setState(() {
                                                    _pickedImages.removeAt(i);
                                                  });
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: ThemeColors.error,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 8),
                                        itemCount: _pickedImages.length,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '${_pickedImages.length}/10 images selected',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: ThemeColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // Basic Info Card
                  Card(
                    elevation: 4,
                    shadowColor: ThemeColors.primary.withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: ThemeColors.primary,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Basic Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Product Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty
                                  ? 'Please enter product name'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty
                                  ? 'Please enter description'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _category = v),
                              validator: (v) =>
                                  v == null ? 'Please select a category' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _colorController,
                              decoration: const InputDecoration(
                                labelText: 'Color (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _sizeController,
                              decoration: const InputDecoration(
                                labelText: 'Size (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _materialController,
                              decoration: const InputDecoration(
                                labelText: 'Material (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(
                                labelText: 'Weight (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _brandController,
                              decoration: const InputDecoration(
                                labelText: 'Brand (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lengthController,
                              decoration: const InputDecoration(
                                labelText: 'Length (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _widthController,
                              decoration: const InputDecoration(
                                labelText: 'Width (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _heightController,
                              decoration: const InputDecoration(
                                labelText: 'Height (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pricing & Inventory Card
                  Card(
                    elevation: 4,
                    shadowColor: ThemeColors.primary.withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: ThemeColors.primary,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pricing & Inventory',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _mrpController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'MRP (List Price)',
                                prefixText: '₹',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Enter MRP' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    decoration: const InputDecoration(
                                      labelText: 'Selling Price',
                                      prefixText: '₹',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (v) =>
                                        v!.isEmpty ? 'Enter price' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CheckboxListTile(
                                        title: const Text(
                                          'In stock (available)',
                                        ),
                                        value: _inStock,
                                        onChanged: (v) => setState(
                                          () => _inStock = v ?? false,
                                        ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _skuController,
                              decoration: const InputDecoration(
                                labelText: 'SKU (Optional)',
                                border: OutlineInputBorder(),
                                helperText:
                                    'Unique identifier for your product',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Options Card
                  Card(
                    elevation: 4,
                    shadowColor: ThemeColors.primary.withOpacity(0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: ThemeColors.primary,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Options',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Active'),
                              subtitle: const Text('Product is ready for sale'),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                            SwitchListTile(
                              title: const Text('Featured'),
                              subtitle: const Text(
                                'Show in featured products section',
                              ),
                              value: _isFeatured,
                              onChanged: (v) => setState(() => _isFeatured = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Sales Tips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ThemeColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ThemeColors.accent.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: ThemeColors.accent,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Pro Tips for Success',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip('Add multiple images from different angles'),
                        _buildTip('Use detailed descriptions to build trust'),
                        _buildTip('Keep stock updated to avoid disappointment'),
                        _buildTip(
                          'Set competitive prices for better conversion',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: ThemeColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> imgs = await picker.pickMultiImage(imageQuality: 70);
      if (imgs.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _pickedImages.clear();
          _pickedImages.addAll(imgs);
        });
      }
    } catch (e) {
      // ignore picker errors; show minimal feedback
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
    }
  }

  Future<Widget> _buildThumbnail(XFile x) async {
    try {
      final bytes = await x.readAsBytes();
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: ThemeColors.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 120,
            height: 120,
          ),
        ),
      );
    } catch (_) {
      return Container(
        width: 120,
        height: 120,
        color: ThemeColors.surface,
        child: const Icon(Icons.broken_image),
      );
    }
  }
}
