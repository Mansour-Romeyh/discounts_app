// lib/screens/savings_calculator_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class SavingsCalculatorScreen extends StatefulWidget {
  const SavingsCalculatorScreen({super.key});

  @override
  State<SavingsCalculatorScreen> createState() => _SavingsCalculatorScreenState();
}

class _SavingsCalculatorScreenState extends State<SavingsCalculatorScreen> {
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _storeController = TextEditingController();

  bool _isPercentage = true;
  double _originalPrice = 0.0;
  double _discountValue = 0.0;
  double _savedAmount = 0.0;
  double _finalPrice = 0.0;

  List<Map<String, dynamic>> _history = [];
  double _totalSaved = 0.0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _priceController.addListener(_calculateSavings);
    _discountController.addListener(_calculateSavings);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _discountController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  void _calculateSavings() {
    final priceText = _priceController.text.trim();
    final discountText = _discountController.text.trim();

    if (priceText.isEmpty) {
      setState(() {
        _originalPrice = 0.0;
        _savedAmount = 0.0;
        _finalPrice = 0.0;
      });
      return;
    }

    final price = double.tryParse(priceText) ?? 0.0;
    final discount = double.tryParse(discountText) ?? 0.0;

    double saved = 0.0;
    if (_isPercentage) {
      saved = price * (discount.clamp(0, 100) / 100);
    } else {
      saved = discount.clamp(0, price);
    }

    setState(() {
      _originalPrice = price;
      _discountValue = discount;
      _savedAmount = saved;
      _finalPrice = (price - saved).clamp(0, price);
    });
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('savings_history');
      if (historyStr != null) {
        final List<dynamic> decoded = jsonDecode(historyStr);
        setState(() {
          _history = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
          _calculateTotalSaved();
        });
      }
    } catch (e) {
      debugPrint('Error loading savings history: $e');
    }
  }

  void _calculateTotalSaved() {
    double total = 0.0;
    for (var item in _history) {
      total += (item['savedAmount'] as num).toDouble();
    }
    setState(() {
      _totalSaved = total;
    });
  }

  Future<void> _saveToHistory() async {
    if (_originalPrice <= 0 || _savedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('الرجاء إدخال قيم صحيحة للحساب',
            style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final storeName = _storeController.text.trim().isNotEmpty 
        ? _storeController.text.trim() 
        : 'تسوق عام';

    final newCalculation = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'store': storeName,
      'originalPrice': _originalPrice,
      'discountValue': _discountValue,
      'isPercentage': _isPercentage,
      'savedAmount': _savedAmount,
      'finalPrice': _finalPrice,
      'date': DateTime.now().toIso8601String(),
    };

    setState(() {
      _history.insert(0, newCalculation);
      _calculateTotalSaved();
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('savings_history', jsonEncode(_history));
      
      _storeController.clear();
      _priceController.clear();
      _discountController.clear();
      FocusScope.of(context).unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم حفظ العملية في سجل التوفير بنجاح! 🎉',
              style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }

  Future<void> _deleteItem(String id) async {
    setState(() {
      _history.removeWhere((element) => element['id'] == id);
      _calculateTotalSaved();
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('savings_history', jsonEncode(_history));
    } catch (e) {
      debugPrint('Error deleting history item: $e');
    }
  }

  Future<void> _clearHistory() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('مسح السجل',
            style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('هل أنت متأكد من رغبتك في مسح سجل التوفير بالكامل؟',
            style: AppTheme.tajawal(fontSize: 14, color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء',
                style: AppTheme.tajawal(color: Colors.grey, fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _history.clear();
                _totalSaved = 0.0;
              });
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('savings_history');
              } catch (e) {
                debugPrint('Error clearing history: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('مسح الكل',
                style: AppTheme.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
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
        title: Text('حاسبة التوفير الذكية',
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
              // ─── Cumulative Stats Card ─────────────────────────────────────
              _buildStatsCard(),
              const SizedBox(height: 16),

              // ─── Calculator Live Display Card ──────────────────────────────
              _buildLiveDisplayCard(),
              const SizedBox(height: 20),

              // ─── Input Fields Form ──────────────────────────────────────────
              _buildFormFields(),
              const SizedBox(height: 24),

              // ─── Save Button ────────────────────────────────────────────────
              _buildSaveButton(),
              const SizedBox(height: 32),

              // ─── History Header ─────────────────────────────────────────────
              _buildHistoryHeader(),
              const SizedBox(height: 12),

              // ─── History List ───────────────────────────────────────────────
              _buildHistoryList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E24), Color(0xFF2E2E38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي التوفير مع كوبوني',
                  style: AppTheme.tajawal(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _totalSaved.toStringAsFixed(2),
                  style: AppTheme.tajawal(
                    color: AppTheme.secondary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calculate_rounded, color: AppTheme.primary, size: 24),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(
                      'العمليات',
                      style: AppTheme.tajawal(color: Colors.white60, fontSize: 10),
                    ),
                    Text(
                      '${_history.length}',
                      style: AppTheme.tajawal(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDisplayCard() {
    return Container(
      width: double.infinity,
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
      child: Column(
        children: [
          Text(
            'نتائج التوفير الفورية',
            style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'السعر النهائي',
                        style: AppTheme.tajawal(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _finalPrice.toStringAsFixed(2),
                        style: AppTheme.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'المبلغ الموفر',
                        style: AppTheme.tajawal(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _savedAmount.toStringAsFixed(2),
                        style: AppTheme.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفاصيل العملية',
          style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF444444)),
        ),
        const SizedBox(height: 12),

        // Store Name input
        _customTextField(
          controller: _storeController,
          label: 'اسم المتجر / كوبون الخصم (اختياري)',
          hint: 'مثال: نون، نمشي، COUPON10',
          icon: Icons.storefront_rounded,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 14),

        // Price Input
        _customTextField(
          controller: _priceController,
          label: 'السعر الأصلي للمنتج',
          hint: '0.00',
          icon: Icons.money_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        ),
        const SizedBox(height: 14),

        // Discount value input
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _customTextField(
                controller: _discountController,
                label: _isPercentage ? 'نسبة الخصم (%)' : 'قيمة الخصم الثابتة',
                hint: '0.00',
                icon: Icons.percent_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نوع الخصم',
                    style: AppTheme.tajawal(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFDCDCDC)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPercentage = true;
                                _calculateSavings();
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _isPercentage ? AppTheme.primary : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                              ),
                              child: Text(
                                '%',
                                style: AppTheme.tajawal(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _isPercentage ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isPercentage = false;
                                _calculateSavings();
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: !_isPercentage ? AppTheme.primary : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                              ),
                              child: Text(
                                'قيمة',
                                style: AppTheme.tajawal(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: !_isPercentage ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.tajawal(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AppTheme.tajawal(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.tajawal(fontSize: 13, color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveToHistory,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'حفظ العملية في السجل',
              style: AppTheme.tajawal(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'سجل العمليات السابقة',
          style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF444444)),
        ),
        if (_history.isNotEmpty)
          GestureDetector(
            onTap: _clearHistory,
            child: Row(
              children: [
                const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                const SizedBox(width: 4),
                Text(
                  'مسح السجل',
                  style: AppTheme.tajawal(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
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
            Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'السجل فارغ حالياً',
              style: AppTheme.tajawal(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final id = item['id'].toString();
        final store = item['store'] ?? 'تسوق عام';
        final original = (item['originalPrice'] as num).toDouble();
        final saved = (item['savedAmount'] as num).toDouble();
        final finalPrice = (item['finalPrice'] as num).toDouble();
        final date = _formatDate(item['date'] ?? '');
        final discountVal = (item['discountValue'] as num).toDouble();
        final isPct = item['isPercentage'] as bool? ?? true;

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.startToEnd,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
          ),
          onDismissed: (direction) {
            _deleteItem(id);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('تم حذف العملية من السجل', style: AppTheme.tajawal()),
              duration: const Duration(seconds: 2),
            ));
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBEBEB)),
            ),
            child: Column(
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
                          child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          store,
                          style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                        ),
                      ],
                    ),
                    Text(
                      date,
                      style: AppTheme.tajawal(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('السعر الأصلي', style: AppTheme.tajawal(fontSize: 11, color: Colors.grey)),
                        Text(original.toStringAsFixed(2), style: AppTheme.tajawal(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('الخصم المطبق', style: AppTheme.tajawal(fontSize: 11, color: Colors.grey)),
                        Text(
                          isPct ? '${discountVal.toStringAsFixed(0)}%' : discountVal.toStringAsFixed(2),
                          style: AppTheme.tajawal(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المبلغ الموفر', style: AppTheme.tajawal(fontSize: 11, color: Colors.grey)),
                        Text(saved.toStringAsFixed(2), style: AppTheme.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('السعر النهائي', style: AppTheme.tajawal(fontSize: 11, color: Colors.grey)),
                        Text(finalPrice.toStringAsFixed(2), style: AppTheme.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
