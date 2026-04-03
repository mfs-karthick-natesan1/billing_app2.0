import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../providers/user_provider.dart';
import 'app_snackbar.dart';
import 'app_text_input.dart';

class AddEditUserSheet extends StatefulWidget {
  final AppUser? existingUser;
  final bool ownerSetup;

  const AddEditUserSheet({
    super.key,
    this.existingUser,
    this.ownerSetup = false,
  });

  static Future<void> show(
    BuildContext context, {
    AppUser? existingUser,
    bool ownerSetup = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          AddEditUserSheet(existingUser: existingUser, ownerSetup: ownerSetup),
    );
  }

  @override
  State<AddEditUserSheet> createState() => _AddEditUserSheetState();
}

class _AddEditUserSheetState extends State<AddEditUserSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  UserRole _role = UserRole.manager;
  bool _isActive = true;

  String? _nameError;
  String? _phoneError;
  String? _pinError;
  String? _confirmPinError;

  bool get _isEdit => widget.existingUser != null;

  @override
  void initState() {
    super.initState();
    if (widget.ownerSetup) {
      _role = UserRole.owner;
    }
    final user = widget.existingUser;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _role = user.role;
      _isActive = user.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.medium,
          AppSpacing.medium,
          AppSpacing.medium,
          AppSpacing.medium + bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_title, style: AppTypography.heading),
              const SizedBox(height: AppSpacing.medium),
              AppTextInput(
                label: AppStrings.name,
                required: true,
                controller: _nameController,
                maxLength: 60,
                errorText: _nameError,
                onChanged: (_) => setState(() => _nameError = null),
              ),
              const SizedBox(height: AppSpacing.small),
              AppTextInput(
                label: AppStrings.phoneLabel,
                required: true,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                errorText: _phoneError,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() => _phoneError = null),
              ),
              const SizedBox(height: AppSpacing.small),
              _buildRoleSelector(),
              if (_isEdit && !widget.ownerSetup && _role != UserRole.owner) ...[
                const SizedBox(height: AppSpacing.small),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.activeUser, style: AppTypography.body),
                    Switch(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      activeTrackColor: AppColors.primary,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.small),
              AppTextInput(
                label: _isEdit ? AppStrings.newPinOptional : AppStrings.pin,
                required: !_isEdit || widget.ownerSetup,
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                errorText: _pinError,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() => _pinError = null),
              ),
              const SizedBox(height: AppSpacing.small),
              AppTextInput(
                label: AppStrings.confirmPin,
                required: !_isEdit || widget.ownerSetup,
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                errorText: _confirmPinError,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() => _confirmPinError = null),
              ),
              const SizedBox(height: AppSpacing.medium),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.buttonRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    _isEdit ? AppStrings.updateUser : AppStrings.addUser,
                    style: AppTypography.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _title {
    if (widget.ownerSetup) return AppStrings.createOwnerAccount;
    if (_isEdit) return AppStrings.editUser;
    return AppStrings.addUser;
  }

  Widget _buildRoleSelector() {
    final roles = widget.ownerSetup
        ? const [UserRole.owner]
        : UserRole.values
              .where(
                (role) => role != UserRole.owner || _role == UserRole.owner,
              )
              .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.role, style: AppTypography.label),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<UserRole>(
              value: _role,
              isExpanded: true,
              items: roles
                  .map(
                    (role) => DropdownMenuItem<UserRole>(
                      value: role,
                      child: Text(role.label, style: AppTypography.body),
                    ),
                  )
                  .toList(growable: false),
              onChanged: widget.ownerSetup
                  ? null
                  : (role) {
                      if (role != null) {
                        setState(() => _role = role);
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }

  void _save() {
    final userProvider = context.read<UserProvider>();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    var hasError = false;

    if (name.length < 2) {
      _nameError = AppStrings.nameMinLength;
      hasError = true;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      _phoneError = AppStrings.phoneInvalid;
      hasError = true;
    } else {
      final excludeId = widget.existingUser?.id;
      if (userProvider.phoneExists(phone, excludeUserId: excludeId)) {
        _phoneError = AppStrings.phoneAlreadyUsed;
        hasError = true;
      }
    }

    final pinRequired = !_isEdit || widget.ownerSetup;
    if (pinRequired && !RegExp(r'^\d{4}$').hasMatch(pin)) {
      _pinError = AppStrings.pinInvalid;
      hasError = true;
    }

    if ((pinRequired || pin.isNotEmpty) && pin != confirmPin) {
      _confirmPinError = AppStrings.pinMismatch;
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    var success = false;

    if (widget.ownerSetup) {
      success = userProvider.createOwnerAndEnableManagement(
        name: name,
        phone: phone,
        pin: pin,
      );
    } else if (_isEdit) {
      final existing = widget.existingUser!;
      final updated = existing.copyWith(
        name: name,
        phone: phone,
        role: _role,
        isActive: _isActive,
      );
      success = userProvider.updateUser(updated);
      if (success && pin.isNotEmpty) {
        success = userProvider.resetUserPin(existing.id, pin);
      }
    } else {
      success = userProvider.addUser(
        name: name,
        phone: phone,
        pin: pin,
        role: _role,
      );
    }

    if (!mounted) return;

    if (success) {
      AppSnackbar.success(context, AppStrings.userSaved);
      Navigator.pop(context);
    } else {
      AppSnackbar.error(context, AppStrings.userSaveFailed);
    }
  }
}
