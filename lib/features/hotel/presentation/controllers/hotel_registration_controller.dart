import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/hotel_registration_data.dart';
import '../../../../core/constants/app_colors.dart';

class HotelRegistrationController extends StatelessWidget {
  const HotelRegistrationController({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Hotel Registration')));
  }
}

// Route helper for step navigation
class HotelRegistrationRoutes {
  static const String step1 = '/hotel-registration/step-1';
  static const String step2 = '/hotel-registration/step-2';
  static const String step3 = '/hotel-registration/step-3';
  static const String step4 = '/hotel-registration/step-4';

  static Map<String, Widget Function(dynamic)> routes = {
    step1: (data) => const Scaffold(body: Center(child: Text('Step 1'))),
    step2: (data) => const Scaffold(body: Center(child: Text('Step 2'))),
    step3: (data) => const Scaffold(body: Center(child: Text('Step 3'))),
    step4: (data) => const Scaffold(body: Center(child: Text('Step 4'))),
  };
}

// Progress indicator widget that can be used across all steps
class RegistrationProgressIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> stepTitles;

  const RegistrationProgressIndicator({
    super.key,
    required this.currentStep,
    required this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(stepTitles.length * 2 - 1, (index) {
          if (index.isEven) {
            // Step circle
            final stepNumber = index ~/ 2 + 1;
            final isActive = stepNumber == currentStep;
            final isCompleted = stepNumber < currentStep;

            return Expanded(
              flex: 0,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isActive 
                        ? AppColors.info.shade600 
                        : isCompleted 
                            ? AppColors.success.shade600 
                            : AppColors.gray.shade300,
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : Text(
                            stepNumber.toString(),
                            style: TextStyle(
                              color: isActive || isCompleted 
                                  ? Colors.white 
                                  : AppColors.gray.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 60,
                    child: Text(
                      stepTitles[stepNumber - 1],
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive 
                            ? AppColors.info.shade600 
                            : isCompleted 
                                ? AppColors.success.shade600 
                                : AppColors.gray.shade600,
                        fontWeight: isActive || isCompleted 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Progress line
            final lineIndex = index ~/ 2;
            final isCompleted = lineIndex < currentStep - 1;

            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: isCompleted ? AppColors.success.shade600 : AppColors.gray.shade300,
              ),
            );
          }
        }),
      ),
    );
  }
}

// Common form field widgets that can be reused across steps
class RegistrationFormFields {
  static Widget buildRequiredFieldLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const Text(
          ' *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  static Widget buildOptionalFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGray,
      ),
    );
  }

  static Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.gray.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.info.shade600, width: 2),
        ),
        filled: true,
        fillColor: AppColors.gray.shade50,
      ),
    );
  }

  static Widget buildDropdownField({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    String? hintText,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      hint: hintText != null ? Text(hintText) : null,
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.gray.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.info.shade600, width: 2),
        ),
        filled: true,
        fillColor: AppColors.gray.shade50,
      ),
    );
  }
}

// Navigation buttons widget
class RegistrationNavigationButtons extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isNextEnabled;
  final String nextButtonText;
  final bool isLoading;

  const RegistrationNavigationButtons({
    super.key,
    this.onPrevious,
    this.onNext,
    required this.isNextEnabled,
    this.nextButtonText = 'Continue',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onPrevious != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: onPrevious,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.info.shade600),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, color: AppColors.info.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Previous',
                    style: TextStyle(
                      color: AppColors.info.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: ElevatedButton(
            onPressed: isNextEnabled && !isLoading ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nextButtonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
