import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_card.dart';
import '../services/db_service.dart';

class JobCardProvider extends ChangeNotifier {
  final List<JobCard> _jobCards = [];
  final VoidCallback? _onChanged;
  int _jobCounter = 1;

  DbService? dbService;

  JobCardProvider({
    List<JobCard>? initialJobCards,
    VoidCallback? onChanged,
  }) : _onChanged = onChanged {
    if (initialJobCards != null) {
      _jobCards.addAll(initialJobCards);
      // Derive counter from existing job numbers
      for (final jc in initialJobCards) {
        final num = int.tryParse(jc.jobNumber.replaceAll(RegExp(r'[^0-9]'), ''));
        if (num != null && num >= _jobCounter) {
          _jobCounter = num + 1;
        }
      }
    }
  }

  List<JobCard> get jobCards => List.unmodifiable(_jobCards);

  List<JobCard> getByStatus(JobStatus? status) {
    if (status == null) return jobCards;
    return _jobCards.where((jc) => jc.status == status).toList();
  }

  List<JobCard> searchJobCards(String query, {JobStatus? status}) {
    if (query.length < 2) return getByStatus(status);
    final lower = query.toLowerCase();
    return _jobCards.where((jc) {
      if (status != null && jc.status != status) return false;
      return jc.jobNumber.toLowerCase().contains(lower) ||
          jc.vehicleReg.toLowerCase().contains(lower) ||
          jc.customerName.toLowerCase().contains(lower) ||
          jc.vehicleMake.toLowerCase().contains(lower) ||
          jc.vehicleModel.toLowerCase().contains(lower);
    }).toList();
  }

  String _nextJobNumber() {
    final num = _jobCounter++;
    return 'JOB-${num.toString().padLeft(4, '0')}';
  }

  JobCard createJobCard({
    required String vehicleReg,
    String vehicleMake = '',
    String vehicleModel = '',
    String kmReading = '',
    String? customerId,
    required String customerName,
    String customerPhone = '',
    required String problemDescription,
    double? estimatedCost,
  }) {
    final jobCard = JobCard(
      jobNumber: _nextJobNumber(),
      vehicleReg: vehicleReg,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      kmReading: kmReading,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      problemDescription: problemDescription,
      estimatedCost: estimatedCost,
    );
    _jobCards.add(jobCard);
    dbService?.saveJobCards([jobCard]);
    _persistAndNotify();
    return jobCard;
  }

  void updateStatus(String jobId, JobStatus status) {
    final idx = _jobCards.indexWhere((jc) => jc.id == jobId);
    if (idx == -1) return;
    _jobCards[idx] = _jobCards[idx].copyWith(status: status);
    dbService?.saveJobCards([_jobCards[idx]]);
    _persistAndNotify();
  }

  void updateDiagnosis(String jobId, {String? diagnosis, double? estimatedCost}) {
    final idx = _jobCards.indexWhere((jc) => jc.id == jobId);
    if (idx == -1) return;
    _jobCards[idx] = _jobCards[idx].copyWith(
      diagnosis: diagnosis,
      estimatedCost: estimatedCost,
    );
    dbService?.saveJobCards([_jobCards[idx]]);
    _persistAndNotify();
  }

  void addItem(String jobId, JobLineItem item) {
    final idx = _jobCards.indexWhere((jc) => jc.id == jobId);
    if (idx == -1) return;
    final updatedItems = List<JobLineItem>.from(_jobCards[idx].items)..add(item);
    _jobCards[idx] = _jobCards[idx].copyWith(items: updatedItems);
    dbService?.saveJobCards([_jobCards[idx]]);
    _persistAndNotify();
  }

  void removeItem(String jobId, String itemId) {
    final idx = _jobCards.indexWhere((jc) => jc.id == jobId);
    if (idx == -1) return;
    final updatedItems = _jobCards[idx]
        .items
        .where((i) => i.id != itemId)
        .toList();
    _jobCards[idx] = _jobCards[idx].copyWith(items: updatedItems);
    dbService?.saveJobCards([_jobCards[idx]]);
    _persistAndNotify();
  }

  Future<void> notifyCustomerWhatsApp(JobCard jobCard) async {
    if (jobCard.customerPhone.isEmpty) return;
    final phone = jobCard.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Hi ${jobCard.customerName}, your vehicle ${jobCard.vehicleReg} is ready for pickup at our workshop. Job#: ${jobCard.jobNumber}',
    );
    final url = Uri.parse('https://wa.me/91$phone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void clearAllData() {
    _jobCards.clear();
    _jobCounter = 1;
    _persistAndNotify();
  }

  void _persistAndNotify() {
    _onChanged?.call();
    notifyListeners();
  }
}
