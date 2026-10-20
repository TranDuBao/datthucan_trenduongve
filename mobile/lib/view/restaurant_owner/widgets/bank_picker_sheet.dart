import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import '../../../services/bank_service.dart';

class BankPickerSheet extends StatefulWidget {
  final String currentBankName;
  final Function(BankItem selectedBank) onSelect;

  const BankPickerSheet({
    super.key,
    required this.currentBankName,
    required this.onSelect,
  });

  static void show(
    BuildContext context, {
    required String currentBankName,
    required Function(BankItem selectedBank) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BankPickerSheet(
        currentBankName: currentBankName,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<BankPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<BankItem> _allBanks = [];
  List<BankItem> _filteredBanks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBanks();
    _searchCtrl.addListener(_onSearchChanged);
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
        _loading = false;
      });
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filteredBanks = _allBanks);
      return;
    }
    setState(() {
      _filteredBanks = _allBanks.where((b) {
        return b.name.toLowerCase().contains(q) ||
            b.shortName.toLowerCase().contains(q) ||
            b.code.toLowerCase().contains(q) ||
            b.bin.contains(q);
      }).toList();
    });
  }

  bool _isSelected(BankItem b) {
    final current = widget.currentBankName.toLowerCase().trim();
    if (current.isEmpty) return false;
    final bCode = b.code.toLowerCase().trim();
    final bShort = b.shortName.toLowerCase().trim();
    final bDisp = b.displayName.toLowerCase().trim();
    return current == bCode ||
        current == bShort ||
        current == bDisp ||
        current.contains(bCode) ||
        current.contains(bShort);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_rounded, color: Color(0xFFFC6011), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Chọn ngân hàng thụ hưởng',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TColor.borderOf(context)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tên ngân hàng, mã, viết tắt...',
                  hintStyle: TextStyle(fontSize: 12.5, color: TColor.secondaryTextOf(context)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Bank List
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFC6011), strokeWidth: 2.5),
                  )
                : _filteredBanks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: TColor.secondaryTextOf(context)),
                              const SizedBox(height: 10),
                              Text(
                                'Không tìm thấy ngân hàng phù hợp',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TColor.secondaryTextOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _filteredBanks.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                        itemBuilder: (ctx, index) {
                          final bank = _filteredBanks[index];
                          final selected = _isSelected(bank);

                          return InkWell(
                            onTap: () {
                              widget.onSelect(bank);
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Row(
                                children: [
                                  // Bank Logo Container
                                  Container(
                                    width: 48,
                                    height: 36,
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: selected ? const Color(0xFFFC6011) : Colors.grey.shade200,
                                        width: selected ? 1.5 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: bank.logo.isNotEmpty
                                        ? Image.network(
                                            bank.logo,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.account_balance_rounded,
                                              size: 20,
                                              color: Color(0xFF64748B),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.account_balance_rounded,
                                            size: 20,
                                            color: Color(0xFF64748B),
                                          ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Names
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              bank.shortName,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: selected ? const Color(0xFFFC6011) : TColor.primaryTextOf(context),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: selected ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                bank.code,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: selected ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          bank.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: TColor.secondaryTextOf(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Radio or Selected Icon
                                  if (selected)
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFFFC6011), size: 20)
                                  else
                                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
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
