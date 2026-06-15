import re

file_path = r'f:\host\HotelSewa\flutter\lib\core\services\owner\features\hotel\presentation\screens\registration_review_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix the import line - remove any corrupted imports
content = content.replace("import 'dart:io';\\r\\nimport 'package:shared_preferences/shared_preferences.dart';", "import 'dart:io';\nimport 'package:shared_preferences/shared_preferences.dart';")
content = content.replace("import 'dart:io';\\nimport 'package:shared_preferences/shared_preferences.dart';", "import 'dart:io';\nimport 'package:shared_preferences/shared_preferences.dart';")

# Add the import if it doesn't exist
if "import 'package:shared_preferences/shared_preferences.dart';" not in content:
    content = content.replace("import 'dart:io';", "import 'dart:io';\nimport 'package:shared_preferences/shared_preferences.dart';")

# Add hotelId saving code
old_code = """// Step 2: Upload images using the returned hotel ID
      final hotelId = response['data']?['id']?.toString() ?? '';
      if (hotelId.isNotEmpty) {
        final imagesToUpload = [
          if (widget.exteriorPhoto != null) widget.exteriorPhoto!,
          if (widget.receptionPhoto != null) widget.receptionPhoto!,
          ...widget.galleryPhotos,
        ];
        if (imagesToUpload.isNotEmpty) {
          await _uploadImages(imagesToUpload, hotelId);
        }
      }"""

new_code = """// Step 2: Upload images using the returned hotel ID
      final hotelId = response['data']?['id']?.toString() ?? '';
      if (hotelId.isNotEmpty) {
        // Save hotelId to SharedPreferences
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('hotelId', hotelId);
          debugPrint('Saved hotelId to SharedPreferences: $hotelId');
        } catch (e) {
          debugPrint('Error saving hotelId: $e');
        }
        
        final imagesToUpload = [
          if (widget.exteriorPhoto != null) widget.exteriorPhoto!,
          if (widget.receptionPhoto != null) widget.receptionPhoto!,
          ...widget.galleryPhotos,
        ];
        if (imagesToUpload.isNotEmpty) {
          await _uploadImages(imagesToUpload, hotelId);
        }
      }"""

content = content.replace(old_code, new_code)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('File updated successfully')
