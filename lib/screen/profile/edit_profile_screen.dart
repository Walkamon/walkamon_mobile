import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/widgets/common/app_icon.dart';
import 'package:walkamon_mobile/widgets/common/asset_only_icon_button.dart';
import 'package:walkamon_mobile/widgets/common/game_back_button.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/game_state_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các trường nhập chữ
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  // Biến trạng thái cho Giới tính, Ngày sinh và Ảnh cục bộ vừa chọn
  String _selectedGender = 'male';
  DateTime _selectedDate = DateTime(2000, 1, 1);
  String? _localImagePath; // Lưu đường dẫn ảnh tạm khi chọn từ máy
  Uint8List?
  _webImageBytes; // Lưu dữ liệu byte thực tế của ảnh để upload trên Web

  // Animation mượt mà khi mở màn hình
  late final AnimationController _animController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _formInitialized = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
    _initializeFormAfterBuild();
  }

  // The form reads inherited widgets only after the first frame. This avoids
  // accessing Localizations while the State is still being initialized.
  void _initializeFormAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _formInitialized) return;

      final user = context.read<GameStateProvider>().user;
      final l10n = AppLocalizations.of(context);
      final rawBio = user?.bio.trim() ?? '';
      final hasBio =
          rawBio.isNotEmpty &&
          rawBio.toLowerCase() != 'chưa cập nhật' &&
          rawBio.toLowerCase() != 'chưa có tiểu sử' &&
          rawBio.toLowerCase() != 'not updated' &&
          rawBio.toLowerCase() != 'no bio';

      _nameController.text = user?.name ?? l10n.profileEditDefaultName;
      _emailController.text = user?.email ?? 'user@walkamon.vn';
      _bioController.text = hasBio ? user!.bio : '';

      final rawGen = user?.gender.toLowerCase().trim() ?? '';
      if (rawGen == 'male' || rawGen == 'nam') {
        _selectedGender = 'male';
      } else if (rawGen == 'female' || rawGen == 'nữ' || rawGen == 'nu') {
        _selectedGender = 'female';
      } else {
        _selectedGender = 'other';
      }

      if (user?.dob.trim().isNotEmpty == true) {
        try {
          final parts = user!.dob.split('/');
          if (parts.length == 3) {
            _selectedDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (_) {}
      }

      _formInitialized = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Hàm kích hoạt bộ chọn ảnh từ Album máy máy điện thoại
  Future<void> _pickAvatar() async {
    if (context.read<GameStateProvider>().isProfileLoading) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // ĐỌC DỮ LIỆU BYTES THỰC TẾ CỦA FILE ẢNH
      final imageBytes = await pickedFile.readAsBytes();

      setState(() {
        _localImagePath = pickedFile.path; // Để Render UI Preview (thẻ blob://)
        _webImageBytes = imageBytes; // Lưu bytes để tí nữa truyền đi upload
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (context.read<GameStateProvider>().isProfileLoading) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showStatusDialog({
    required BuildContext context,
    required bool isSuccess,
    required String message,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (dialogContext, anim, anim2, child) {
        final l10n = AppLocalizations.of(dialogContext);
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : AppColors.authCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.wood,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark
                        ? (isSuccess
                              ? AppColors.darkPrimary
                              : AppColors.darkMuted)
                        : (isSuccess ? AppColors.leafLight : AppColors.blossom),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : (isSuccess
                                ? AppColors.oliveDeep
                                : AppColors.danger),
                      width: 2,
                    ),
                  ),
                  child: AppIcon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    size: 36,
                    color: isDark
                        ? AppColors.darkForeground
                        : (isSuccess ? AppColors.oliveDeep : AppColors.danger),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isSuccess
                      ? l10n.dailyLoginSuccessTitle
                      : l10n.profileEditFailureTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.woodDeep,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.outlineBrown,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? (isSuccess
                                ? AppColors.darkPrimary
                                : AppColors.darkBorder)
                          : (isSuccess
                                ? AppColors.buttonGreen
                                : AppColors.buttonYellow),
                      foregroundColor: isDark
                          ? AppColors.darkForeground
                          : AppColors.buttonText,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.woodDeep,
                          width: 2,
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (isSuccess) {
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.pop(dialogContext);
                        }
                        if (context.mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      } else {
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.pop(dialogContext);
                        }
                      }
                    },
                    child: GameButtonLabel(
                      l10n.profileEditConfirm,
                      fontSize: 15,
                      color: isDark
                          ? AppColors.darkForeground
                          : AppColors.buttonText,
                      outlineColor: isDark
                          ? AppColors.darkTextOutline
                          : AppColors.woodDeep,
                      outlineWidth: 2.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Xử lý khi nhấn nút Lưu Thay Đổi
  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<GameStateProvider>();
    if (provider.isProfileLoading) return;

    // TRUYỀN BIẾN ẢNH cục bộ xuống hàm updateProfile của provider để tải lên API
    final success = await provider.updateProfile(
      name: _nameController.text.trim(),
      gender: _selectedGender,
      dob: _selectedDate,
      bio: _bioController.text.trim(),
      imageBytes: _webImageBytes,
    );

    if (!mounted) return;

    if (success) {
      await provider.fetchProfileDetail();

      if (!mounted) return;

      _showStatusDialog(
        context: context,
        isSuccess: true,
        message: AppLocalizations.of(context).profileEditSuccessMessage,
      );
    } else {
      _showStatusDialog(
        context: context,
        isSuccess: false,
        message:
            provider.profileErrorMessage ??
            AppLocalizations.of(context).profileEditFailureMessage,
      );
    }
  }

  String get _formattedDate {
    return "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Colors.transparent;

    final isProfileLoading = context
        .watch<GameStateProvider>()
        .isProfileLoading;
    final userAvatarUrl =
        context.watch<GameStateProvider>().user?.avatarUrl ?? '';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HeaderButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () {
                            if (!isProfileLoading) Navigator.pop(context);
                          },
                        ),
                        GameButtonLabel(
                          l10n.profileEditTitle,
                          fontSize: 20,
                          color: isDark
                              ? AppColors.darkForeground
                              : AppColors.woodDeep,
                          outlineColor: isDark
                              ? AppColors.darkTextOutline
                              : AppColors.authCard,
                          outlineWidth: 4,
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.darkMuted
                                      : AppColors.leafLight)
                                  .withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.oliveDeep,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.woodDeep.withValues(alpha: 0.2),
                              blurRadius: 9,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? AppColors.darkCard
                                        : AppColors.authCard)
                                    .withValues(alpha: 0.97),
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.wood,
                              width: 1.5,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkMuted
                                              : AppColors.leafLight,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? AppColors.darkBorder
                                                      .withValues(alpha: 0.45)
                                                : AppColors.woodDeep,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.woodDeep
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              55,
                                            ),
                                            // CƠ CHẾ HIỂN THỊ THÔNG MINH 3 TẦNG:
                                            child: _localImagePath != null
                                                ? ( // ── KIỂM TRA NẾU CHẠY TRÊN WEB THÌ DÙNG IMAGE.NETWORK CHO ĐƯỜNG DẪN TẠM ──
                                                  _localImagePath!.startsWith(
                                                            'http',
                                                          ) ||
                                                          _localImagePath!
                                                              .startsWith(
                                                                'blob:',
                                                              )
                                                      ? Image.network(
                                                          _localImagePath!,
                                                          width: 110,
                                                          height: 110,
                                                          fit: BoxFit.cover,
                                                        )
                                                      : Image.file(
                                                          File(
                                                            _localImagePath!,
                                                          ), // Chạy trên Android/iOS thật thì vẫn dùng file bình thường
                                                          width: 110,
                                                          height: 110,
                                                          fit: BoxFit.cover,
                                                        ))
                                                : userAvatarUrl.isNotEmpty
                                                ? Image.network(
                                                    userAvatarUrl, // Ảnh cũ kéo từ Server về
                                                    width: 110,
                                                    height: 110,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) => Text(
                                                          _nameController
                                                                  .text
                                                                  .isNotEmpty
                                                              ? _nameController
                                                                    .text[0]
                                                                    .toUpperCase()
                                                              : 'U',
                                                          style: TextStyle(
                                                            fontSize: 48,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: isDark
                                                                ? AppColors
                                                                      .darkForeground
                                                                : AppColors
                                                                      .woodDeep,
                                                          ),
                                                        ),
                                                  )
                                                : Text(
                                                    _nameController
                                                            .text
                                                            .isNotEmpty
                                                        ? _nameController
                                                              .text[0]
                                                              .toUpperCase()
                                                        : 'U', // Trống hết thì hiện chữ cái đầu
                                                    style: TextStyle(
                                                      fontSize: 48,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: isDark
                                                          ? AppColors
                                                                .darkForeground
                                                          : AppColors.woodDeep,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: AssetOnlyIconButton(
                                          onPressed: isProfileLoading
                                              ? null
                                              : _pickAvatar,
                                          semanticLabel: l10n.profileEditTitle,
                                          icon: Icons.camera_alt_rounded,
                                          buttonSize: 36,
                                          assetSize: 32,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _FieldWrapper(
                                  label: l10n.profileEditDisplayName,
                                  child: _PillInput(
                                    controller: _nameController,
                                    icon: Icons.person_rounded,
                                    asset: AppAssets.iconAvatar,
                                    hint: l10n.profileEditDisplayNameHint,
                                    enabled: !isProfileLoading,
                                    onChanged: (val) => setState(() {}),
                                    validator: (val) => val!.trim().isEmpty
                                        ? l10n.profileEditRequiredName
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _FieldWrapper(
                                  label: l10n.profileEditEmailLabel,
                                  child: _PillInput(
                                    controller: _emailController,
                                    icon: Icons.email_rounded,
                                    hint: l10n.profileEditEmailHint,
                                    enabled: false,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _FieldWrapper(
                                        label: l10n.profileEditGenderLabel,
                                        child: _PillDropdown(
                                          value: _selectedGender,
                                          items: [
                                            DropdownOption(
                                              value: 'male',
                                              label: l10n.profileEditGenderMale,
                                            ),
                                            DropdownOption(
                                              value: 'female',
                                              label:
                                                  l10n.profileEditGenderFemale,
                                            ),
                                            DropdownOption(
                                              value: 'other',
                                              label:
                                                  l10n.profileEditGenderOther,
                                            ),
                                          ],
                                          enabled: !isProfileLoading,
                                          onChanged: (val) => setState(
                                            () => _selectedGender = val!,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _FieldWrapper(
                                        label: l10n.profileEditBirthLabel,
                                        child: _PillDatePicker(
                                          dateText: _formattedDate,
                                          onTap: () => _selectDate(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _FieldWrapper(
                                  label: l10n.profileEditBioLabel,
                                  child: _PillInput(
                                    controller: _bioController,
                                    icon: Icons.info_outline_rounded,
                                    hint: l10n.profileEditBioHint,
                                    enabled: !isProfileLoading,
                                    maxLines: 3,
                                    isTextArea: true,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                _TapScaleButton(
                                  onPressed: _handleSave,
                                  backgroundColor: isProfileLoading
                                      ? (isDark
                                            ? AppColors.darkMuted
                                            : AppColors.panelMuted)
                                      : (isDark
                                            ? AppColors.darkPrimary
                                            : AppColors.buttonGreen),
                                  foregroundColor: isDark
                                      ? AppColors.darkForeground
                                      : AppColors.buttonText,
                                  label: isProfileLoading
                                      ? l10n.profileEditSaveLoading
                                      : l10n.profileEditSave,
                                  isLoading: isProfileLoading,
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GameBackButton(
      key: ValueKey(icon),
      semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onTap,
    );
  }
}

class _FieldWrapper extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldWrapper({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkForeground : AppColors.woodDeep,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PillInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? asset;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool isTextArea;
  final bool enabled;
  final Function(String)? onChanged;
  final FormFieldValidator<String>? validator;

  const _PillInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.asset,
    this.keyboardType,
    this.maxLines = 1,
    this.isTextArea = false,
    this.enabled = true,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isTextArea ? 10 : 4,
      ),
      decoration: BoxDecoration(
        color: enabled
            ? (isDark ? AppColors.darkCard : AppColors.creamLight)
            : (isDark ? AppColors.darkMuted : AppColors.panelMuted).withValues(
                alpha: 0.58,
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.wood,
          width: 1.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: isTextArea
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: isTextArea ? 4 : 0),
            child: AppIcon(
              icon,
              asset: asset,
              size: 22,
              color: enabled
                  ? (isDark ? AppColors.darkForeground : AppColors.woodDeep)
                  : AppColors.outlineBrown.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              onChanged: onChanged,
              enabled: enabled,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: enabled
                    ? (isDark ? AppColors.darkForeground : AppColors.inkBrown)
                    : (isDark
                          ? AppColors.darkMutedForeground
                          : AppColors.outlineBrown.withValues(alpha: 0.65)),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkMutedForeground
                      : AppColors.outlineBrown.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              validator: validator,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: EdgeInsets.only(top: isTextArea ? 4 : 0),
            child: AppIcon(
              enabled ? Icons.edit_rounded : Icons.lock_rounded,
              size: enabled ? 23 : 19,
              color: enabled
                  ? (isDark ? AppColors.darkBorder : AppColors.woodLight)
                  : (isDark
                        ? AppColors.darkMutedForeground
                        : AppColors.outlineBrown.withValues(alpha: 0.55)),
            ),
          ),
        ],
      ),
    );
  }
}

class DropdownOption {
  const DropdownOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _PillDropdown extends StatelessWidget {
  final String value;
  final List<DropdownOption> items;
  final bool enabled;
  final Function(String?) onChanged;

  const _PillDropdown({
    required this.value,
    required this.items,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectedOption = items.firstWhere(
          (option) => option.value == value,
          orElse: () => items.first,
        );
        return PopupMenuButton<String>(
          enabled: enabled,
          initialValue: value,
          position: PopupMenuPosition.under,
          offset: const Offset(0, 6),
          color: isDark ? AppColors.darkCard : AppColors.authCard,
          surfaceTintColor: Colors.transparent,
          elevation: 7,
          constraints: BoxConstraints.tightFor(width: constraints.maxWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.wood,
              width: 2,
            ),
          ),
          onSelected: (selected) => onChanged(selected),
          itemBuilder: (context) => items.map((option) {
            final selected = option.value == value;
            return PopupMenuItem<String>(
              value: option.value,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark ? AppColors.darkPrimary : AppColors.leafLight)
                      : (isDark ? AppColors.darkMuted : AppColors.creamLight)
                            .withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? (isDark ? AppColors.darkBorder : AppColors.oliveDeep)
                        : (isDark ? AppColors.darkBorder : AppColors.creamDeep),
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkForeground
                              : AppColors.woodDeep,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      AppIcon(
                        Icons.check_rounded,
                        size: 22,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.oliveDeep,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: enabled
                  ? (isDark ? AppColors.darkCard : AppColors.creamLight)
                  : (isDark ? AppColors.darkMuted : AppColors.panelMuted)
                        .withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.wood,
                width: 1.8,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedOption.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? (isDark
                                ? AppColors.darkForeground
                                : AppColors.inkBrown)
                          : AppColors.outlineBrown.withValues(alpha: 0.65),
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AppIcon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 23,
                  color: enabled
                      ? (isDark ? AppColors.darkForeground : AppColors.woodDeep)
                      : AppColors.outlineBrown.withValues(alpha: 0.55),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PillDatePicker extends StatelessWidget {
  final String dateText;
  final VoidCallback onTap;

  const _PillDatePicker({required this.dateText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.creamLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.wood,
              width: 1.8,
            ),
          ),
          child: Row(
            children: [
              AppIcon(
                Icons.calendar_month_rounded,
                size: 20,
                color: isDark ? AppColors.darkForeground : AppColors.woodDeep,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dateText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkForeground
                        : AppColors.inkBrown,
                    fontSize: 15,
                  ),
                ),
              ),
              AppIcon(
                Icons.edit_rounded,
                size: 23,
                color: isDark ? AppColors.darkBorder : AppColors.woodLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapScaleButton extends StatefulWidget {
  const _TapScaleButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;
  final bool isLoading;

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => widget.isLoading ? null : setState(() => _scale = 0.95),
      onTapUp: (_) => widget.isLoading ? null : setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.woodDeep,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.25),
                offset: const Offset(0, 8),
                blurRadius: 20,
              ),
            ],
          ),
          child: Material(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(32),
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: widget.isLoading ? null : widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading) ...[
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.foregroundColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    GameButtonLabel(
                      widget.label,
                      fontSize: 16,
                      color: widget.foregroundColor,
                      outlineColor: AppColors.woodDeep,
                      outlineWidth: 2.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
