import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      final hasBio = rawBio.isNotEmpty &&
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

      if (user?.dob != null && user?.dob != 'Chưa cập nhật') {
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
        final theme = Theme.of(dialogContext);
        final l10n = AppLocalizations.of(dialogContext);

        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.15),
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
                    color: (isSuccess ? Colors.green : theme.colorScheme.error)
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    size: 36,
                    color: isSuccess ? Colors.green : theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isSuccess
                      ? l10n.dailyLoginSuccessTitle
                      : l10n.profileEditFailureTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccess
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
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
                    child: Text(
                      l10n.profileEditConfirm,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final primary = theme.colorScheme.primary;
    final cardColor = theme.cardColor;
    final backgroundColor = theme.scaffoldBackgroundColor;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HeaderButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () {
                            if (!isProfileLoading) Navigator.pop(context);
                          },
                        ),
                        Text(
                          l10n.profileEditTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
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
                                      color: primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: backgroundColor,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(55),
                                        // CƠ CHẾ HIỂN THỊ THÔNG MINH 3 TẦNG:
                                        child: _localImagePath != null
                                            ? ( // ── KIỂM TRA NẾU CHẠY TRÊN WEB THÌ DÙNG IMAGE.NETWORK CHO ĐƯỜNG DẪN TẠM ──
                                              _localImagePath!.startsWith(
                                                        'http',
                                                      ) ||
                                                      _localImagePath!
                                                          .startsWith('blob:')
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
                                                errorBuilder: (_, __, ___) =>
                                                    Text(
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
                                                        color: theme
                                                            .colorScheme
                                                            .onPrimary,
                                                      ),
                                                    ),
                                              )
                                            : Text(
                                                _nameController.text.isNotEmpty
                                                    ? _nameController.text[0]
                                                          .toUpperCase()
                                                    : 'U', // Trống hết thì hiện chữ cái đầu
                                                style: TextStyle(
                                                  fontSize: 48,
                                                  fontWeight: FontWeight.w800,
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimary,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.dividerColor.withValues(
                                            alpha: 0.15,
                                          ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.camera_alt_rounded,
                                          size: 18,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        onPressed: isProfileLoading
                                            ? null
                                            : _pickAvatar, // Kích hoạt gọi hàm chọn ảnh từ điện thoại
                                      ),
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
                                          label: l10n.profileEditGenderFemale,
                                        ),
                                        DropdownOption(
                                          value: 'other',
                                          label: l10n.profileEditGenderOther,
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
                                  ? theme.disabledColor
                                  : primary,
                              foregroundColor: theme.colorScheme.onPrimary,
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
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _FieldWrapper extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldWrapper({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
    this.keyboardType,
    this.maxLines = 1,
    this.isTextArea = false,
    this.enabled = true,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isTextArea ? 12 : 4,
      ),
      decoration: BoxDecoration(
        color: enabled
            ? theme.cardColor
            : theme.disabledColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(isTextArea ? 24 : 32),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: isTextArea
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: isTextArea ? 4 : 0),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(
                alpha: enabled ? 0.5 : 0.25,
              ),
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: enabled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              validator: validator,
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: enabled
            ? theme.cardColor
            : theme.disabledColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          dropdownColor: theme.cardColor,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.colorScheme.onSurface.withValues(
              alpha: enabled ? 0.5 : 0.2,
            ),
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 15,
          ),
          onChanged: enabled ? onChanged : null,
          items: items.map<DropdownMenuItem<String>>((option) {
            return DropdownMenuItem<String>(
              value: option.value,
              child: Text(option.label),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _PillDatePicker extends StatelessWidget {
  final String dateText;
  final VoidCallback onTap;

  const _PillDatePicker({required this.dateText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dateText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
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
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: widget.foregroundColor,
                        letterSpacing: 0.5,
                      ),
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
