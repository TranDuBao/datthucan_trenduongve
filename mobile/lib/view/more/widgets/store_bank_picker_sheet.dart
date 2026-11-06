import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import '../../../services/bank_service.dart';

class StoreBankPickerSheet extends StatefulWidget {
  final String? currentBankCode;
  final Function(BankItem) onSelected;

  const StoreBankPickerSheet({
    super.key,
    this.currentBankCode,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    String? currentBankCode,
    required Function(BankItem) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StoreBankPickerSheet(
        currentBankCode: currentBankCode,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<StoreBankPickerSheet> createState() => _StoreBankPickerSheetState();
}

class _StoreBankPickerSheetState extends State<StoreBankPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<BankItem> _allBanks = [];
  List<BankItem> _filteredBanks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    final list = await BankService.getVietQRBanks();
    if (mounted) {
      setState(() {
        _allBanks = list;
        _filteredBanks = list;
        _isLoading = false;
      });
    }
  }

  void _onSearch(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = _allBanks;
      } else {
        _filteredBanks = _allBanks.where((b) {
          final code = b.code.toLowerCase();
          final shortName = b.shortName.toLowerCase();
          final name = b.name.toLowerCase();
          return code.contains(query) || shortName.contains(query) || name.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161920) : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF333846) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Chọn Ngân Hàng Thụ Hưởng",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Hỗ trợ tất cả ngân hàng trong hệ thống Napas247",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Box (Tone trắng, bo góc sắc nét)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF202532) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2D3545) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: "Tìm theo tên, mã hoặc viết tắt (VCB, MB, Techcombank...)",
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Bank List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredBanks.isEmpty
                    ? Center(
                        child: Text(
                          "Không tìm thấy ngân hàng phù hợp",
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        itemCount: _filteredBanks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final bank = _filteredBanks[index];
                          final isSelected = widget.currentBankCode != null &&
                              (widget.currentBankCode == bank.code ||
                                  widget.currentBankCode == bank.name ||
                                  widget.currentBankCode == bank.shortName);

                          return InkWell(
                            onTap: () {
                              widget.onSelected(bank);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? TColor.primary.withOpacity(0.06)
                                    : (isDark ? const Color(0xFF1E232E) : Colors.white),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? TColor.primary
                                      : (isDark ? const Color(0xFF2B3342) : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Official Bank Logo Box (White tone, sharp rounded)
                                  Container(
                                    width: 58,
                                    height: 38,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 1,
                                      ),
                                    ),
                                    child: bank.logo.isNotEmpty
                                        ? Image.network(
                                            bank.logo,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text(
                                                bank.code,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: TColor.primary,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              bank.code,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: TColor.primary,
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Names
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bank.shortName.isNotEmpty
                                              ? "${bank.shortName} (${bank.code})"
                                              : bank.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? TColor.primary
                                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          bank.name,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Selected Indicator
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: TColor.primary,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

