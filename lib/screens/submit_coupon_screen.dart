// lib/screens/submit_coupon_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class SubmitCouponScreen extends StatefulWidget {
  const SubmitCouponScreen({super.key});

  @override
  State<SubmitCouponScreen> createState() => _SubmitCouponScreenState();
}

class _SubmitCouponScreenState extends State<SubmitCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _storeNameController = TextEditingController();
  final _couponCodeController = TextEditingController();
  final _discountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storeUrlController = TextEditingController();

  bool _isSubmitting = false;
  List<Map<String, dynamic>> _mySubmissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _couponCodeController.dispose();
    _discountController.dispose();
    _descriptionController.dispose();
    _storeUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subsStr = prefs.getString('my_coupon_submissions');
      if (subsStr != null) {
        final List<dynamic> decoded = jsonDecode(subsStr);
        setState(() {
          _mySubmissions = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading submissions: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // محاكاة الاتصال بالسيرفر
    await Future.delayed(const Duration(seconds: 2));

    final newSubmission = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'storeName': _storeNameController.text.trim(),
      'couponCode': _couponCodeController.text.trim().toUpperCase(),
      'discount': _discountController.text.trim(),
      'description': _descriptionController.text.trim(),
      'storeUrl': _storeUrlController.text.trim(),
      'date': DateTime.now().toIso8601String(),
      'status': 'قيد المراجعة', // Pending review
    };

    setState(() {
      _mySubmissions.insert(0, newSubmission);
      _isSubmitting = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('my_coupon_submissions', jsonEncode(_mySubmissions));
      
      // Clear inputs
      _storeNameController.clear();
      _couponCodeController.clear();
      _discountController.clear();
      _descriptionController.clear();
      _storeUrlController.clear();

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Error saving submission: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.accent,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'شكراً لمشاركتك! 🎉',
              style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              'لقد تم تقديم الكوبون بنجاح وهو قيد المراجعة الآن بواسطة فريقنا الفني للتحقق من صلاحيته ونشره لجميع المستخدمين.',
              style: AppTheme.tajawal(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'موافق',
                      style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDateStr) {
    try {
      final date = DateTime.parse(isoDateStr);
      return '${date.year}/${date.month}/${date.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('اقترح كوبون جديد',
            style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD84315),
                AppTheme.primary,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              _buildInfoBanner(),
              const SizedBox(height: 20),

              // Form
              _buildForm(),
              const SizedBox(height: 32),

              // Submissions History Header
              Text(
                'كوبوناتي المقترحة',
                style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF444444)),
              ),
              const SizedBox(height: 12),

              // Submissions list
              _buildSubmissionsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هل لديك كود خصم تود مشاركته؟',
                  style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'ساعد المتسوقين الآخرين على التوفير! أدخل تفاصيل كوبون الخصم وسنقوم بفحصه وتفعيله فوراً في التطبيق.',
                  style: AppTheme.tajawal(fontSize: 12, color: Colors.grey.shade700, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEBEB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Name
            _customTextFormField(
              controller: _storeNameController,
              label: 'اسم المتجر الالكتروني *',
              hint: 'مثال: نون، شي إن، أمازون',
              icon: Icons.storefront_rounded,
              validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم المتجر' : null,
            ),
            const SizedBox(height: 14),

            // Coupon Code
            _customTextFormField(
              controller: _couponCodeController,
              label: 'كود الكوبون *',
              hint: 'مثال: DISCOUNT10',
              icon: Icons.qr_code_rounded,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال كود الكوبون' : null,
            ),
            const SizedBox(height: 14),

            // Discount
            _customTextFormField(
              controller: _discountController,
              label: 'قيمة أو نسبة الخصم *',
              hint: 'مثال: خصم 15% أو خصم 50 ريال',
              icon: Icons.percent_rounded,
              validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال قيمة الخصم' : null,
            ),
            const SizedBox(height: 14),

            // Description
            _customTextFormField(
              controller: _descriptionController,
              label: 'تفاصيل العرض / شروط الكوبون *',
              hint: 'مثال: يعمل على جميع المنتجات، بحد أدنى للشراء 200 ريال',
              icon: Icons.description_outlined,
              maxLines: 2,
              validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال تفاصيل الكوبون' : null,
            ),
            const SizedBox(height: 14),

            // Store URL
            _customTextFormField(
              controller: _storeUrlController,
              label: 'رابط المتجر (اختياري)',
              hint: 'https://example.com',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Submit Button
            GestureDetector(
              onTap: _isSubmitting ? null : _submitForm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _isSubmitting ? Colors.grey : AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isSubmitting
                      ? null
                      : [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'تقديم الاقتراح للمراجعة',
                              style: AppTheme.tajawal(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.tajawal(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: AppTheme.tajawal(fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.tajawal(fontSize: 13, color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorStyle: AppTheme.tajawal(color: Colors.redAccent, fontSize: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionsList() {
    if (_mySubmissions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: Column(
          children: [
            Icon(Icons.discount_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'لم تقترح أي كوبون بعد',
              style: AppTheme.tajawal(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _mySubmissions.length,
      itemBuilder: (context, index) {
        final item = _mySubmissions[index];
        final store = item['storeName'] ?? '';
        final code = item['couponCode'] ?? '';
        final discount = item['discount'] ?? '';
        final date = _formatDate(item['date'] ?? '');
        final status = item['status'] ?? 'قيد المراجعة';

        Color statusColor = Colors.orange;
        if (status == 'نشط') {
          statusColor = AppTheme.accent;
        } else if (status == 'مرفوض') {
          statusColor = Colors.redAccent;
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stars_rounded, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        store,
                        style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: AppTheme.tajawal(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade100, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('كود الكوبون', style: AppTheme.tajawal(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(code, style: AppTheme.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('قيمة الخصم', style: AppTheme.tajawal(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(discount, style: AppTheme.tajawal(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تاريخ الاقتراح', style: AppTheme.tajawal(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(date, style: AppTheme.tajawal(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
