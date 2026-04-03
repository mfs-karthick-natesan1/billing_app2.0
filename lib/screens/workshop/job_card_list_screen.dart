import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';
import '../../models/business_config.dart';
import '../../models/job_card.dart';
import '../../providers/business_config_provider.dart';
import '../../providers/job_card_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_input.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/empty_state.dart';

class JobCardListScreen extends StatefulWidget {
  const JobCardListScreen({super.key});

  @override
  State<JobCardListScreen> createState() => _JobCardListScreenState();
}

class _JobCardListScreenState extends State<JobCardListScreen> {
  JobStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobCardProvider>();
    final jobs = _filter == null
        ? provider.jobCards
        : provider.getByStatus(_filter!);

    return Scaffold(
      appBar: const AppTopBar(title: AppStrings.jobsTitle),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-job',
        onPressed: () => _showNewJobSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Status filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
                vertical: 8,
              ),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                ...JobStatus.values
                    .where((s) => s != JobStatus.cancelled)
                    .map(
                      (s) => _FilterChip(
                        label: s.label,
                        selected: _filter == s,
                        onTap: () => setState(() => _filter = s),
                      ),
                    ),
              ],
            ),
          ),
          // Job card list
          Expanded(
            child: jobs.isEmpty
                ? EmptyState(
                    icon: Icons.build_circle_outlined,
                    title: AppStrings.noJobCards,
                    description: AppStrings.noJobCardsDesc,
                    ctaLabel: AppStrings.newJobCard,
                    onCtaTap: () => _showNewJobSheet(context),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return _JobCardListTile(
                        jobCard: job,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/job-detail',
                          arguments: {'jobId': job.id},
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showNewJobSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewJobCardSheet(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.muted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: selected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _JobCardListTile extends StatelessWidget {
  final JobCard jobCard;
  final VoidCallback onTap;

  const _JobCardListTile({required this.jobCard, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysOpen = DateTime.now().difference(jobCard.createdAt).inDays;
    final statusColor = _statusColor(jobCard.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          jobCard.jobNumber,
                          style: AppTypography.label.copyWith(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            jobCard.status.label,
                            style: AppTypography.label.copyWith(
                              color: statusColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jobCard.vehicleReg,
                      style: AppTypography.body
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (jobCard.vehicleMake.isNotEmpty ||
                        jobCard.vehicleModel.isNotEmpty)
                      Text(
                        '${jobCard.vehicleMake} ${jobCard.vehicleModel}'.trim(),
                        style: AppTypography.label
                            .copyWith(color: AppColors.muted),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      jobCard.customerName,
                      style: AppTypography.label
                          .copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$daysOpen day${daysOpen == 1 ? '' : 's'}',
                    style: AppTypography.label.copyWith(
                      color: daysOpen > 3 ? AppColors.error : AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.received:
        return AppColors.muted;
      case JobStatus.diagnosed:
        return AppColors.warning;
      case JobStatus.inProgress:
        return AppColors.primary;
      case JobStatus.readyForPickup:
        return AppColors.success;
      case JobStatus.delivered:
        return AppColors.success;
      case JobStatus.cancelled:
        return AppColors.error;
    }
  }
}

// ─── New Job Card Sheet ───────────────────────────────────────────────────────

class _NewJobCardSheet extends StatefulWidget {
  const _NewJobCardSheet();

  @override
  State<_NewJobCardSheet> createState() => _NewJobCardSheetState();
}

class _NewJobCardSheetState extends State<_NewJobCardSheet> {
  final _vehicleRegController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _kmReadingController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _problemController = TextEditingController();
  String? _vehicleRegError;
  String? _customerNameError;
  String? _problemError;

  @override
  void dispose() {
    _vehicleRegController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _kmReadingController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.read<BusinessConfigProvider>().isMobileShop;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                    vertical: AppSpacing.small,
                  ),
                  child: Text(
                    AppStrings.newJobCard,
                    style: AppTypography.heading,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      children: [
                        AppTextInput(
                          label: isMobile ? AppStrings.deviceImei : AppStrings.vehicleReg,
                          hint: isMobile ? AppStrings.deviceImeiHint : AppStrings.vehicleRegHint,
                          required: true,
                          controller: _vehicleRegController,
                          autoUppercase: !isMobile,
                          errorText: _vehicleRegError,
                          onChanged: (_) =>
                              setState(() => _vehicleRegError = null),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextInput(
                                label: isMobile ? AppStrings.deviceBrand : AppStrings.vehicleMake,
                                hint: isMobile ? AppStrings.deviceBrandHint : AppStrings.vehicleMakeHint,
                                controller: _vehicleMakeController,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: AppTextInput(
                                label: AppStrings.vehicleModel,
                                hint: isMobile ? 'e.g. Galaxy A55' : AppStrings.vehicleModelHint,
                                controller: _vehicleModelController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        AppTextInput(
                          label: isMobile ? AppStrings.deviceStorage : AppStrings.kmReading,
                          hint: isMobile ? AppStrings.deviceStorageHint : AppStrings.kmReadingHint,
                          controller: _kmReadingController,
                          keyboardType: isMobile ? TextInputType.text : TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        AppTextInput(
                          label: AppStrings.customerName,
                          hint: 'e.g. Ravi Kumar',
                          required: true,
                          controller: _customerNameController,
                          errorText: _customerNameError,
                          onChanged: (_) =>
                              setState(() => _customerNameError = null),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        AppTextInput(
                          label: AppStrings.customerPhone,
                          hint: AppStrings.phoneHint,
                          controller: _customerPhoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        AppTextInput(
                          label: AppStrings.problemDescription,
                          hint: AppStrings.problemDescriptionHint,
                          required: true,
                          controller: _problemController,
                          errorText: _problemError,
                          onChanged: (_) =>
                              setState(() => _problemError = null),
                        ),
                        const SizedBox(height: AppSpacing.large),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(AppStrings.jobCardSaved),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    bool hasError = false;
    if (_vehicleRegController.text.trim().isEmpty) {
      setState(() => _vehicleRegError = AppStrings.vehicleRegRequired);
      hasError = true;
    }
    if (_customerNameController.text.trim().isEmpty) {
      setState(() => _customerNameError = AppStrings.customerNameRequired);
      hasError = true;
    }
    if (_problemController.text.trim().isEmpty) {
      setState(() => _problemError = AppStrings.problemRequired);
      hasError = true;
    }
    if (hasError) return;

    context.read<JobCardProvider>().createJobCard(
      vehicleReg: _vehicleRegController.text.trim(),
      vehicleMake: _vehicleMakeController.text.trim(),
      vehicleModel: _vehicleModelController.text.trim(),
      kmReading: _kmReadingController.text.trim(),
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      problemDescription: _problemController.text.trim(),
    );
    Navigator.pop(context);
    AppSnackbar.success(context, AppStrings.jobCardSaved);
  }
}
