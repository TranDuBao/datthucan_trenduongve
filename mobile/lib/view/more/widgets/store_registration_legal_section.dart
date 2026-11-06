import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import '../../../common/legal_config.dart';
import '../../../model/legal_document_model.dart';
import 'legal_document_sheet.dart';
import 'store_registration_section_card.dart';

class StoreRegistrationLegalSection extends StatelessWidget {
  final LoaiHinhPhapLy selectedLoaiHinh;
  final ValueChanged<LoaiHinhPhapLy> onLoaiHinhChanged;
  final TextEditingController maSoThueCtrl;
  final TextEditingController soGiayPhepCtrl;
  final TextEditingController soGiayAttpCtrl;

  final bool agreedTerms;
  final ValueChanged<bool> onAgreedTermsChanged;
  final bool agreedPrivacy;
  final ValueChanged<bool> onAgreedPrivacyChanged;

  final ActiveLegalDocumentsResponse? activeLegalDocs;
  final bool isLoadingLegalDocs;
  final String? legalDocsError;
  final VoidCallback onRetryLoadDocs;
  final void Function(String) showToast;

  const StoreRegistrationLegalSection({
    super.key,
    required this.selectedLoaiHinh,
    required this.onLoaiHinhChanged,
    required this.maSoThueCtrl,
    required this.soGiayPhepCtrl,
    required this.soGiayAttpCtrl,
    required this.agreedTerms,
    required this.onAgreedTermsChanged,
    required this.agreedPrivacy,
    required this.onAgreedPrivacyChanged,
    required this.activeLegalDocs,
    required this.isLoadingLegalDocs,
    required this.legalDocsError,
    required this.onRetryLoadDocs,
    required this.showToast,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final req = LegalConfig.getRequirement(selectedLoaiHinh);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section 4 Card
        StoreRegistrationSectionCard(
          title: "4. Thông tin pháp lý & Nghĩa vụ thuế",
          subtitle: "Cung cấp mã số thuế và giấy phép theo quy định",
          icon: Icons.business_rounded,
          children: [
            // Legal Type Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Loại hình kinh doanh pháp lý *",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1F29) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LoaiHinhPhapLy>(
                      value: selectedLoaiHinh,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1E232E) : Colors.white,
                      items: LoaiHinhPhapLy.values.map((type) {
                        final itemReq = LegalConfig.getRequirement(type);
                        return DropdownMenuItem<LoaiHinhPhapLy>(
                          value: type,
                          child: Text(
                            itemReq.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) onLoaiHinhChanged(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tax Code
            _buildTextField(
              context,
              controller: maSoThueCtrl,
              label: "Mã số thuế (MST)${req.requireTaxCode ? ' *' : ''}",
              hint: "Nhập mã số thuế 10 hoặc 13 chữ số",
              keyboardType: TextInputType.number,
              validator: (v) {
                if (req.requireTaxCode) {
                  if (v == null || v.trim().isEmpty) return "Vui lòng nhập mã số thuế";
                  if (!LegalConfig.validateMaSoThue(v)) return "MST không hợp lệ (10 hoặc 13 chữ số)";
                } else if (v != null && v.trim().isNotEmpty && !LegalConfig.validateMaSoThue(v)) {
                  return "MST không hợp lệ (10 hoặc 13 chữ số)";
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Business License
            _buildTextField(
              context,
              controller: soGiayPhepCtrl,
              label: "Số Giấy phép ĐKKD${req.requireBusinessLicense ? ' *' : ' (Tùy chọn)'}",
              hint: "Ví dụ: 01A8012345",
              validator: (v) {
                if (req.requireBusinessLicense && (v == null || v.trim().isEmpty)) {
                  return "Vui lòng nhập số Giấy phép ĐKKD cho ${req.label}";
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Food Safety Cert
            _buildTextField(
              context,
              controller: soGiayAttpCtrl,
              label: "Số Giấy chứng nhận ATTP${req.requireFoodSafetyCert ? ' *' : ' (Tùy chọn)'}",
              hint: "Ví dụ: 123/2024/ATTP-CNĐK",
              validator: (v) {
                if (req.requireFoodSafetyCert && (v == null || v.trim().isEmpty)) {
                  return "Vui lòng nhập số Giấy chứng nhận ATTP cho ${req.label}";
                }
                return null;
              },
            ),
          ],
        ),

        // Section 5 Card
        StoreRegistrationSectionCard(
          title: "5. Cam kết & Điều khoản hợp tác",
          subtitle: "Xác nhận các điều khoản dịch vụ và chính sách dữ liệu",
          icon: Icons.verified_user_rounded,
          children: [
            if (isLoadingLegalDocs)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text("Đang tải nội dung điều khoản từ máy chủ...", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              )
            else if (legalDocsError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        legalDocsError!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                      ),
                    ),
                    TextButton(
                      onPressed: onRetryLoadDocs,
                      child: const Text("Thử lại", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            // Checkbox 1: Terms
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: agreedTerms,
                    activeColor: TColor.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (activeLegalDocs?.isReady == true)
                        ? (v) => onAgreedTermsChanged(v ?? false)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    children: [
                      Text(
                        "Tôi đã đọc và đồng ý ",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (activeLegalDocs?.dieuKhoan != null) {
                            LegalDocumentSheet.show(context, document: activeLegalDocs!.dieuKhoan!);
                          } else {
                            showToast("Điều khoản đang được tải...");
                          }
                        },
                        child: Text(
                          "Điều khoản đối tác cửa hàng",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: TColor.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        " *",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Checkbox 2: Privacy
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: agreedPrivacy,
                    activeColor: TColor.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (activeLegalDocs?.isReady == true)
                        ? (v) => onAgreedPrivacyChanged(v ?? false)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Wrap(
                    children: [
                      Text(
                        "Tôi đồng ý cho Food Route thu thập và xử lý thông tin cá nhân (CCCD, ngày sinh, tài khoản ngân hàng) để xác minh và vận hành cửa hàng. ",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (activeLegalDocs?.chinhSach != null) {
                            LegalDocumentSheet.show(context, document: activeLegalDocs!.chinhSach!);
                          } else {
                            showToast("Chính sách đang được tải...");
                          }
                        },
                        child: Text(
                          "(Xem chính sách dữ liệu)",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: TColor.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        " *",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1F29) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TColor.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
