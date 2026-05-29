import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:cims/core/constants/app_colors.dart';
import 'package:cims/core/constants/app_text_styles.dart';
import 'package:cims/core/widgets/app_scaffold.dart';
import 'package:cims/core/widgets/badge_chip.dart';
import 'package:cims/core/widgets/stat_card.dart';
import 'package:cims/features/admin/fees/create_invoice_modal.dart';
import 'package:cims/core/utils/modal_helpers.dart';
import 'package:cims/core/session/app_session.dart';

import 'package:cims/features/admin/fees/providers/fees_api_provider.dart';
import 'package:cims/features/admin/students/providers/student_provider.dart';
import 'package:cims/features/admin/students/models/student_api_model.dart';

class FeesScreen extends ConsumerStatefulWidget {
  final void Function(String route) onNavigate;

  const FeesScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(
      text: DateFormat('MM/dd/yyyy').format(DateTime.now()));

  StudentApiModel? _selectedStudent;
  Map<String, dynamic>? _selectedAssignment;
  List<Map<String, dynamic>> _assignments = [];
  bool _loadingAssignments = false;
  bool _savingPayment = false;
  bool _exporting = false;
  String _paymentMethod = 'Bank';
  DateTime? _startDate;
  DateTime? _endDate;
  int _currentPage = 1;
  int _rowsPerPage = 15;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAssignments(int studentId) async {
    setState(() {
      _loadingAssignments = true;
      _selectedAssignment = null;
      _assignments = [];
    });
    try {
      final repo = ref.read(feesRepositoryProvider);
      final list = await repo.listAssignments(
        studentId: studentId,
        statusIn: 'PENDING,PARTIAL,OVERDUE',
      );
      setState(() {
        _assignments = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load assignments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingAssignments = false;
        });
      }
    }
  }

  Future<void> _submitPayment() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student')),
      );
      return;
    }
    if (_selectedAssignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pending invoice/assignment')),
      );
      return;
    }

    final amountStr = _amountCtrl.text.replaceAll(',', '');
    final amountPaid = double.tryParse(amountStr);
    if (amountPaid == null || amountPaid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _savingPayment = true;
    });

    try {
      final repo = ref.read(feesRepositoryProvider);
      await repo.recordPayment({
        'assignment_id': _selectedAssignment!['id'],
        'student_id': _selectedStudent!.id,
        'amount_paid': amountPaid,
        'payment_method': _paymentMethod,
        'remarks': _notesCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully!')),
        );

        setState(() {
          _selectedStudent = null;
          _selectedAssignment = null;
          _assignments = [];
          _amountCtrl.clear();
          _notesCtrl.clear();
        });

        ref.invalidate(feesDashboardProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(feesTopDefaultersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingPayment = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null 
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null,
    );
    
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _currentPage = 1; // Reset pagination when filter is applied
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _currentPage = 1; // Reset pagination when filter is cleared
    });
  }

  Future<void> _exportTransactionsToPdf() async {
    setState(() {
      _exporting = true;
    });

    try {
      final repo = ref.read(feesRepositoryProvider);
      
      String? startStr;
      String? endStr;
      if (_startDate != null) {
        startStr = "${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}";
      }
      if (_endDate != null) {
        endStr = "${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}";
      }

      // Fetch all transactions without pagination limit
      final allTransactions = await repo.listPayments(
        startDate: startStr,
        endDate: endStr,
        page: 1,
        limit: 10000, // Large limit to get all data
      );

      if (allTransactions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No transactions to export')),
          );
        }
        return;
      }

      // Create PDF
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Fee Transactions Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated on: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                if (_startDate != null && _endDate != null)
                  pw.Text(
                    'Date Range: ${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                pw.SizedBox(height: 16),
                // Table header
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(80),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                    4: const pw.FlexColumnWidth(1),
                    5: const pw.FlexColumnWidth(1),
                    6: const pw.FixedColumnWidth(60),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Receipt', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Student', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Roll No', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Amount', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Method', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Date', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Status', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Data rows
                    ...allTransactions.map((item) {
                      final receiptNo = item['receipt_number']?.toString() ?? item['id']?.toString() ?? 'REC-000';
                      final student = item['student'] as Map<String, dynamic>?;
                      final name = student?['full_name']?.toString() ?? 'Student';
                      final rollNo = student?['student_id_code']?.toString() ?? student?['registration_number']?.toString() ?? '—';
                      final amountPaid = (num.tryParse(item['amount_paid'].toString()) ?? 0).toDouble();
                      final amountStr = 'PKR ${NumberFormat('#,##0').format(amountPaid)}';
                      final method = item['payment_method']?.toString() ?? 'Cash';
                      
                      String dateStr = '—';
                      final rawDate = item['payment_date'] ?? item['created_at'];
                      if (rawDate != null) {
                        try {
                          final parsed = DateTime.parse(rawDate.toString());
                          dateStr = DateFormat('MMM dd, yyyy').format(parsed);
                        } catch (_) {
                          dateStr = rawDate.toString();
                        }
                      }

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(receiptNo, style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(name, style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(rollNo, style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(amountStr, style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(method, style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(dateStr, style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Paid', style: pw.TextStyle(fontSize: 8)),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Total Records: ${allTransactions.length}',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            );
          },
        ),
      );

      // Print/Save PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdf.save(),
        name: 'transactions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;

    final dashboardAsync = ref.watch(feesDashboardProvider);

    // Helpers to safely format currency
    String formatCurrency(dynamic val, String fallback) {
      if (val == null) return fallback;
      final numValue = num.tryParse(val.toString())?.toDouble();
      if (numValue == null) return val.toString();
      if (numValue >= 1000000) {
        return 'PKR ${(numValue / 1000000).toStringAsFixed(1)}M';
      } else if (numValue >= 1000) {
        return 'PKR ${(numValue / 1000).toStringAsFixed(1)}K';
      }
      return 'PKR ${NumberFormat('#,##0').format(numValue)}';
    }

    final dashboardData = dashboardAsync.value;

    final collectionValue = formatCurrency(dashboardData?['collected_total'], 'PKR 0.0');
    final collectionTrend = 'Total collected';

    final outstandingValue = formatCurrency(dashboardData?['outstanding_total'], 'PKR 0.0');
    final outstandingTrend = "${dashboardData?['defaulters_total'] ?? 0} defaulters";

    final paidValue = NumberFormat('#,##0').format(dashboardData?['receipts_total'] ?? 0);
    final paidTrend = 'Receipts issued';

    final defaultersValue = NumberFormat('#,##0').format(dashboardData?['defaulters_total'] ?? 0);
    final defaultersTrend = 'Active defaulters';

    return AppScaffold(
      title: 'Fee Management',
      subtitle: 'Operations',
      currentRoute: '/fees',
      role: AppSession.currentRole,
      onNavigate: widget.onNavigate,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── STATS ────────────────────────────────────
          // Mobile: 2x2 grid, Tablet/Desktop: single row
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Monthly Collection',
                        value: collectionValue,
                        trend: collectionTrend,
                        tone: StatTone.success,
                        icon: const Icon(Icons.account_balance_wallet_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Outstanding Dues',
                        value: outstandingValue,
                        trend: outstandingTrend,
                        trendUp: false,
                        tone: StatTone.warning,
                        icon: const Icon(Icons.warning_amber_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Paid Students',
                        value: paidValue,
                        trend: paidTrend,
                        tone: StatTone.primary,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Defaulters',
                        value: defaultersValue,
                        trend: defaultersTrend,
                        tone: StatTone.purple,
                        icon: const Icon(Icons.people_outline_rounded),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Monthly Collection',
                    value: collectionValue,
                    trend: collectionTrend,
                    tone: StatTone.success,
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Outstanding Dues',
                    value: outstandingValue,
                    trend: outstandingTrend,
                    trendUp: false,
                    tone: StatTone.warning,
                    icon: const Icon(Icons.warning_amber_rounded),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Paid Students',
                    value: paidValue,
                    trend: paidTrend,
                    tone: StatTone.primary,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    label: 'Defaulters',
                    value: defaultersValue,
                    trend: defaultersTrend,
                    tone: StatTone.purple,
                    icon: const Icon(Icons.people_outline_rounded),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 18),

          // ── PAYMENT + DEFAULTERS ─────────────────────
          // Mobile/Tablet: stacked, Desktop: side by side
          if (isMobile || isTablet)
            Column(
              children: [
                _recordPaymentCard(),
                const SizedBox(height: 18),
                _topDefaultersCard(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _recordPaymentCard()),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: _topDefaultersCard()),
              ],
            ),

          const SizedBox(height: 18),

          // ── PENDING INVOICES / ASSIGNMENTS ───────────
          if (isMobile)
            _pendingAssignmentsMobileList()
          else
            _pendingAssignmentsCard(isTablet: isTablet),

          const SizedBox(height: 18),

          // ── TRANSACTIONS ─────────────────────────────
          // Mobile: card list, Tablet/Desktop: table
          if (isMobile)
            _transactionsMobileList()
          else
            _transactionsCard(isTablet: isTablet),
        ],
      ),
    );
  }

  Future<void> _markAsPaid(int assignmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: const Text('Are you sure you want to mark this invoice as PAID?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(feesRepositoryProvider);
      await repo.updateAssignmentStatus(assignmentId, 'PAID');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice status updated to PAID!')),
        );
        ref.invalidate(pendingAssignmentsProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(feesDashboardProvider);
        ref.invalidate(feesTopDefaultersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _deleteAssignment(int assignmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this invoice? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(feesRepositoryProvider);
      await repo.deleteAssignment(assignmentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice deleted successfully!')),
        );
        ref.invalidate(pendingAssignmentsProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(feesDashboardProvider);
        ref.invalidate(feesTopDefaultersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete invoice: $e')),
        );
      }
    }
  }

  Widget _pendingAssignmentsCard({required bool isTablet}) {
    final pendingAsync = ref.watch(pendingAssignmentsProvider);

    final pendingList = pendingAsync.when(
      data: (data) {
        if (data.isEmpty) return <PendingAssignmentItem>[];
        return data.map<PendingAssignmentItem>((item) {
          final id = (num.tryParse(item['id'].toString()) ?? 0).toInt();
          final student = item['student'] as Map<String, dynamic>?;
          final name = student?['full_name']?.toString() ?? 'Student';
          final rollNo = student?['student_id_code']?.toString() ?? student?['registration_number']?.toString() ?? '—';
          final feeType = item['fee_type']?.toString() ?? 'Fee';
          
          final totalAmount = (num.tryParse(item['amount'].toString()) ?? 0).toDouble();
          final paidAmount = (num.tryParse(item['paid_amount'].toString()) ?? 0).toDouble();
          final dueAmount = totalAmount - paidAmount;
          final amountStr = 'PKR ${NumberFormat('#,##0').format(dueAmount)}';

          String dateStr = '—';
          final rawDate = item['due_date'];
          if (rawDate != null) {
            try {
              final parsed = DateTime.parse(rawDate.toString());
              dateStr = DateFormat('MMM dd, yyyy').format(parsed);
            } catch (_) {
              dateStr = rawDate.toString();
            }
          }

          String initials = 'ST';
          if (name.isNotEmpty) {
            final parts = name.trim().split(' ');
            if (parts.length >= 2) {
              initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
            } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
              initials = parts[0][0].toUpperCase();
            }
          }

          final colors = [
            AppColors.primary,
            AppColors.info,
            AppColors.purple,
            AppColors.accent,
            AppColors.warning,
          ];
          final color = colors[name.hashCode % colors.length];

          return PendingAssignmentItem(
            id: id,
            invoiceNo: 'INV-$id',
            initials: initials,
            name: name,
            rollNo: rollNo,
            feeType: feeType,
            dueAmount: amountStr,
            dueDate: dateStr,
            status: item['status']?.toString() ?? 'PENDING',
            color: color,
          );
        }).toList();
      },
      loading: () => <PendingAssignmentItem>[],
      error: (_, __) => <PendingAssignmentItem>[],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pending Fees & Invoices', style: AppTextStyles.h3),
                      const SizedBox(height: 4),
                      Text(
                        'Assigned student fees awaiting payment',
                        style: AppTextStyles.body.copyWith(color: AppColors.darkTextMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          if (pendingList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No pending invoices found',
                  style: TextStyle(color: AppColors.darkTextMuted),
                ),
              ),
            )
          else ...[
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(color: AppColors.darkSurfaceAlt),
              child: Row(
                children: [
                  _headerCell('INVOICE', 14),
                  _headerCell('STUDENT', 24),
                  _headerCell('FEE TYPE', 14),
                  _headerCell('DUE AMOUNT', 14),
                  _headerCell('DUE DATE', 14),
                  _headerCell('STATUS', 12),
                  _headerCell('ACTION', 18),
                ],
              ),
            ),
            ...pendingList.map((e) => _pendingAssignmentRow(e, isTablet: isTablet)),
          ],
        ],
      ),
    );
  }

  Widget _pendingAssignmentRow(PendingAssignmentItem e, {required bool isTablet}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 14,
            child: Text(
              e.invoiceNo,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 24,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: e.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    e.initials,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        e.rollNo,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(color: AppColors.darkTextMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(e.feeType, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 14,
            child: Text(
              e.dueAmount,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(e.dueDate, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 12,
            child: BadgeChip.status(e.status),
          ),
          Expanded(
            flex: 18,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _markAsPaid(e.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 12, color: AppColors.success),
                        SizedBox(width: 4),
                        Text(
                          'Pay',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _deleteAssignment(e.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 12,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingAssignmentsMobileList() {
    final pendingAsync = ref.watch(pendingAssignmentsProvider);

    final pendingList = pendingAsync.when(
      data: (data) {
        if (data.isEmpty) return <PendingAssignmentItem>[];
        return data.map<PendingAssignmentItem>((item) {
          final id = (num.tryParse(item['id'].toString()) ?? 0).toInt();
          final student = item['student'] as Map<String, dynamic>?;
          final name = student?['full_name']?.toString() ?? 'Student';
          final rollNo = student?['student_id_code']?.toString() ?? student?['registration_number']?.toString() ?? '—';
          final feeType = item['fee_type']?.toString() ?? 'Fee';
          
          final totalAmount = (num.tryParse(item['amount'].toString()) ?? 0).toDouble();
          final paidAmount = (num.tryParse(item['paid_amount'].toString()) ?? 0).toDouble();
          final dueAmount = totalAmount - paidAmount;
          final amountStr = 'PKR ${NumberFormat('#,##0').format(dueAmount)}';

          String dateStr = '—';
          final rawDate = item['due_date'];
          if (rawDate != null) {
            try {
              final parsed = DateTime.parse(rawDate.toString());
              dateStr = DateFormat('MMM dd, yyyy').format(parsed);
            } catch (_) {
              dateStr = rawDate.toString();
            }
          }

          String initials = 'ST';
          if (name.isNotEmpty) {
            final parts = name.trim().split(' ');
            if (parts.length >= 2) {
              initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
            } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
              initials = parts[0][0].toUpperCase();
            }
          }

          final colors = [
            AppColors.primary,
            AppColors.info,
            AppColors.purple,
            AppColors.accent,
            AppColors.warning,
          ];
          final color = colors[name.hashCode % colors.length];

          return PendingAssignmentItem(
            id: id,
            invoiceNo: 'INV-$id',
            initials: initials,
            name: name,
            rollNo: rollNo,
            feeType: feeType,
            dueAmount: amountStr,
            dueDate: dateStr,
            status: item['status']?.toString() ?? 'PENDING',
            color: color,
          );
        }).toList();
      },
      loading: () => <PendingAssignmentItem>[],
      error: (_, __) => <PendingAssignmentItem>[],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Text('Pending Fees & Invoices', style: AppTextStyles.h3),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          if (pendingList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No pending invoices found',
                  style: TextStyle(color: AppColors.darkTextMuted),
                ),
              ),
            )
          else
            ...pendingList.map((e) => _pendingAssignmentMobileCard(e)),
        ],
      ),
    );
  }

  Widget _pendingAssignmentMobileCard(PendingAssignmentItem e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: e.color,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              e.initials,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${e.feeType} · ${e.invoiceNo}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: AppColors.darkTextMuted),
                ),
                Text(
                  'Due: ${e.dueDate}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(color: AppColors.darkTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                e.dueAmount,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  BadgeChip.status(e.status),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _markAsPaid(e.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.check_rounded, size: 12, color: AppColors.success),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _deleteAssignment(e.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, size: 12, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RECORD PAYMENT CARD
  // ─────────────────────────────────────────────


  Widget _recordPaymentCard() {
    final studentsAsync = ref.watch(studentsListProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅
          children: [
            Text('Record Payment', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text(
              'Generate receipt instantly',
              style: AppTextStyles.body.copyWith(color: AppColors.darkTextMuted),
            ),
            const SizedBox(height: 20),
            studentsAsync.when(
              data: (students) {
                return Autocomplete<StudentApiModel>(
                  displayStringForOption: (s) =>
                      "${s.fullName} - ${s.studentIdCode.isNotEmpty ? s.studentIdCode : s.registrationNumber}",
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<StudentApiModel>.empty();
                    }
                    final query = textEditingValue.text.toLowerCase();
                    return students.where((s) {
                      final nameMatch = s.fullName.toLowerCase().contains(query);
                      final codeMatch = (s.studentIdCode.isNotEmpty
                              ? s.studentIdCode
                              : s.registrationNumber)
                          .toLowerCase()
                          .contains(query);
                      return nameMatch || codeMatch;
                    });
                  },
                  onSelected: (option) {
                    setState(() {
                      _selectedStudent = option;
                    });
                    _loadAssignments(option.id);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'STUDENT',
                        hintText: 'Search by name or roll no...',
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: AppColors.darkSurface,
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.darkBorder),
                        ),
                        child: Container(
                          width: 320,
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(
                                  option.fullName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  option.studentIdCode.isNotEmpty
                                      ? option.studentIdCode
                                      : option.registrationNumber,
                                  style: const TextStyle(color: AppColors.darkTextMuted),
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'STUDENT',
                  hintText: 'Loading students...',
                  suffixIcon: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => const TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'STUDENT',
                  hintText: 'Error loading students',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _loadingAssignments
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedAssignment,
                          decoration: const InputDecoration(
                            labelText: 'PENDING INVOICE / ASSIGNMENT',
                          ),
                          dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
                          items: _assignments.isEmpty
                              ? [
                                  const DropdownMenuItem<Map<String, dynamic>>(
                                    value: null,
                                    child: Text(
                                      'No pending invoices found',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  )
                                ]
                              : _assignments.map((a) {
                                  final double totalAmount =
                                      (num.tryParse(a['amount'].toString()) ?? 0).toDouble();
                                  final double paidAmount =
                                      (num.tryParse(a['paid_amount'].toString()) ?? 0).toDouble();
                                  final double dueAmount = totalAmount - paidAmount;
                                  final dueDate = a['due_date']?.toString() ?? '';

                                  String formattedDate = '';
                                  if (dueDate.isNotEmpty) {
                                    try {
                                      formattedDate = DateFormat('MMM dd, yyyy')
                                          .format(DateTime.parse(dueDate));
                                    } catch (_) {
                                      formattedDate = dueDate;
                                    }
                                  }

                                  final label =
                                      "${a['fee_type'] ?? 'Fee'} — PKR ${NumberFormat('#,##0').format(dueAmount)} ${formattedDate.isNotEmpty ? '— Due $formattedDate' : ''}";

                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: a,
                                    child: SizedBox(
                                      width: 180, // Prevent dropdown text overflow
                                      child: Text(
                                        label,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          onChanged: _assignments.isEmpty
                              ? null
                              : (val) {
                                  setState(() {
                                    _selectedAssignment = val;
                                    if (val != null) {
                                      final double totalAmount =
                                          (num.tryParse(val['amount'].toString()) ?? 0).toDouble();
                                      final double paidAmount =
                                          (num.tryParse(val['paid_amount'].toString()) ?? 0).toDouble();
                                      final double dueAmount = totalAmount - paidAmount;
                                      _amountCtrl.text = dueAmount.toStringAsFixed(0);
                                    } else {
                                      _amountCtrl.clear();
                                    }
                                  });
                                },
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'AMOUNT (PKR)',
                      hintText: '25,000',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'PAYMENT METHOD'),
                    dropdownColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
                    items: const [
                      DropdownMenuItem(
                        value: 'Bank',
                        child: Text('Bank'),
                      ),
                      DropdownMenuItem(
                        value: 'Cash',
                        child: Text('Cash'),
                      ),
                      DropdownMenuItem(
                        value: 'Online',
                        child: Text('Online'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _paymentMethod = val;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _dateCtrl,
                    decoration: const InputDecoration(
                      labelText: 'DATE',
                      hintText: '05/08/2026',
                      suffixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    onTap: () async {
                      // Show Date Picker
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                surface: AppColors.darkSurface,
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _dateCtrl.text = DateFormat('MM/dd/yyyy').format(picked);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'NOTES (OPTIONAL)',
                hintText: 'Reference, late fee waiver, etc.',
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedStudent = null;
                        _selectedAssignment = null;
                        _assignments = [];
                        _amountCtrl.clear();
                        _notesCtrl.clear();
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _savingPayment ? null : _submitPayment,
                    icon: _savingPayment
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: const Text('Generate Receipt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TOP DEFAULTERS CARD
  // ─────────────────────────────────────────────

  Widget _topDefaultersCard() {
    final defaultersAsync = ref.watch(feesTopDefaultersProvider);

    final defaultersList = defaultersAsync.when(
      data: (data) {
        final list = data['defaulters'] as List? ?? [];
        if (list.isEmpty) return <DefaulterItem>[];
        return list.map<DefaulterItem>((item) {
          final name = item['full_name']?.toString() ?? 'Student';
          final rollNo = item['student_id_code']?.toString() ?? '—';
          final totalDue = (num.tryParse(item['total_due'].toString()) ?? 0).toDouble();
          final amountStr = 'PKR ${NumberFormat('#,##0').format(totalDue)}';

          String initials = 'ST';
          if (name.isNotEmpty) {
            final parts = name.trim().split(' ');
            if (parts.length >= 2) {
              initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
            } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
              initials = parts[0][0].toUpperCase();
            }
          }

          final colors = [
            AppColors.primary,
            AppColors.info,
            AppColors.purple,
            AppColors.accent,
            AppColors.warning,
          ];
          final color = colors[name.hashCode % colors.length];

          String overdueText = 'Outstanding';
          final days = item['days_overdue'] ?? item['overdue_days'];
          if (days != null) {
            final daysInt = int.tryParse(days.toString());
            if (daysInt != null) {
              overdueText = daysInt == 0 ? 'Due today' : '$daysInt days overdue';
            }
          } else {
            final prog = item['program_name']?.toString();
            if (prog != null) overdueText = prog;
          }

          return DefaulterItem(
            initials: initials,
            name: name,
            rollNo: rollNo,
            overdue: overdueText,
            amount: amountStr,
            color: color,
            amountColor: totalDue > 20000 ? AppColors.danger : AppColors.warning,
          );
        }).toList();
      },
      loading: () => <DefaulterItem>[],
      error: (_, __) => <DefaulterItem>[],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ✅
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Defaulters', style: AppTextStyles.h3),
                      const SizedBox(height: 4),
                      Text(
                        'Outstanding balance · current session',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.darkTextMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.darkTextMuted,
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (defaultersList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No defaulters found',
                    style: TextStyle(color: AppColors.darkTextMuted),
                  ),
                ),
              )
            else
              ...defaultersList.map((e) => _defaulterRow(e)),
          ],
        ),
      ),
    );
  }

  Widget _defaulterRow(DefaulterItem e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: e.color,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              e.initials,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  overflow: TextOverflow.ellipsis, // ✅
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${e.rollNo} · ${e.overdue}',
                  overflow: TextOverflow.ellipsis, // ✅
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.darkTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            e.amount,
            style: AppTextStyles.body.copyWith(
              color: e.amountColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TRANSACTIONS TABLE (tablet / desktop)
  // ─────────────────────────────────────────────

  Widget _transactionsCard({required bool isTablet}) {
    final transactionsAsync = ref.watch(recentTransactionsProvider(
      (DateFilterState(startDate: _startDate, endDate: _endDate), 
       PaginationState(page: _currentPage, limit: _rowsPerPage))
    ));

    final transactionsList = transactionsAsync.when(
      data: (data) {
        if (data.isEmpty) return <TransactionItem>[];
        return data.map<TransactionItem>((item) {
          final receiptNo = item['receipt_number']?.toString() ?? item['id']?.toString() ?? 'REC-000';
          final student = item['student'] as Map<String, dynamic>?;
          final name = student?['full_name']?.toString() ?? 'Student';
          final rollNo = student?['student_id_code']?.toString() ?? student?['registration_number']?.toString() ?? '—';

          final studentProgram = student?['program'];
          String program = '—';
          if (studentProgram is Map) {
            program = studentProgram['code']?.toString() ?? studentProgram['name']?.toString() ?? '—';
          } else if (studentProgram is String) {
            program = studentProgram;
          }

          final amountPaid = (num.tryParse(item['amount_paid'].toString()) ?? 0).toDouble();
          final amountStr = 'PKR ${NumberFormat('#,##0').format(amountPaid)}';
          final method = item['payment_method']?.toString() ?? 'Cash';

          String dateStr = '—';
          final rawDate = item['payment_date'] ?? item['created_at'];
          if (rawDate != null) {
            try {
              final parsed = DateTime.parse(rawDate.toString());
              dateStr = DateFormat('MMM dd, yyyy').format(parsed);
            } catch (_) {
              dateStr = rawDate.toString();
            }
          }

          String initials = 'ST';
          if (name.isNotEmpty) {
            final parts = name.trim().split(' ');
            if (parts.length >= 2) {
              initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
            } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
              initials = parts[0][0].toUpperCase();
            }
          }

          final colors = [
            AppColors.primary,
            AppColors.info,
            AppColors.purple,
            AppColors.accent,
            AppColors.warning,
          ];
          final color = colors[name.hashCode % colors.length];

          return TransactionItem(
            receiptNo: receiptNo,
            initials: initials,
            name: name,
            rollNo: rollNo,
            program: program,
            amount: amountStr,
            method: method,
            date: dateStr,
            status: 'Paid',
            color: color,
          );
        }).toList();
      },
      loading: () => <TransactionItem>[],
      error: (_, __) => <TransactionItem>[],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Transactions', style: AppTextStyles.h3),
                      const SizedBox(height: 4),
                      Text(
                        'All payment activity',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.darkTextMuted),
                      ),
                    ],
                  ),
                ),
                // ✅ Wrap buttons to prevent overflow on tablet
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _exporting ? null : _exportTransactionsToPdf,
                      icon: _exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(_exporting ? 'Exporting...' : 'Export'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _startDate != null ? _clearDateRange : _selectDateRange,
                      icon: Icon(_startDate != null ? Icons.clear : Icons.date_range),
                      label: Text(
                        _startDate != null && _endDate != null
                          ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                          : 'Filter Dates'
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showResponsiveModal(
                          context: context,
                          child: const CreateInvoiceModal(),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Invoice'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          if (transactionsList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No recent transactions found',
                  style: TextStyle(color: AppColors.darkTextMuted),
                ),
              ),
            )
          else ...[
            // Table header
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(color: AppColors.darkSurfaceAlt),
              child: Row(
                children: [
                  _headerCell('RECEIPT', 16),
                  _headerCell('STUDENT', 24),
                  if (!isTablet) _headerCell('PROGRAM', 14),
                  _headerCell('AMOUNT', 14),
                  if (!isTablet) _headerCell('METHOD', 14),
                  _headerCell('DATE', 14),
                  _headerCell('STATUS', 12),
                ],
              ),
            ),
            ...transactionsList.map((e) => _transactionRow(e, isTablet: isTablet)),
            // Pagination controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.darkBorder)),
              ),
              child: Row(
                children: [
                  // Rows per page dropdown
                  const Text(
                    'Show',
                    style: TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _rowsPerPage,
                            dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
                            style: TextStyle(color: isDark ? AppColors.darkText : AppColors.text, fontSize: 14),
                            icon: Icon(Icons.keyboard_arrow_down, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                            items: [15, 25, 50, 75, 100].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString(), style: TextStyle(color: isDark ? AppColors.darkText : AppColors.text)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _rowsPerPage = value;
                                  _currentPage = 1;
                                });
                              }
                            },
                          ),
                        ),
                      );
                    }
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'per page',
                    style: TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
                  ),
                  const Spacer(),
                  // Page navigation
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: _currentPage > 1 ? Colors.white : AppColors.darkTextMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Page $_currentPage',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: transactionsList.length >= _rowsPerPage
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: transactionsList.length >= _rowsPerPage ? Colors.white : AppColors.darkTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _transactionRow(TransactionItem e, {required bool isTablet}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 16,
            child: Text(
              e.receiptNo,
              overflow: TextOverflow.ellipsis, // ✅
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 24,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: e.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    e.initials,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded( // ✅ prevent name overflow
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        e.rollNo,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.darkTextMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isTablet)
            Expanded(
              flex: 14,
              child: Text(e.program, overflow: TextOverflow.ellipsis),
            ),
          Expanded(
            flex: 14,
            child: Text(
              e.amount,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (!isTablet)
            Expanded(
              flex: 14,
              child: Text(e.method, overflow: TextOverflow.ellipsis),
            ),
          Expanded(
            flex: 14,
            child: Text(e.date, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 12,
            child: BadgeChip.status(e.status),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TRANSACTIONS MOBILE (card list)
  // ─────────────────────────────────────────────

  Widget _transactionsMobileList() {
    final transactionsAsync = ref.watch(recentTransactionsProvider(
      (DateFilterState(startDate: _startDate, endDate: _endDate), 
       PaginationState(page: _currentPage, limit: _rowsPerPage))
    ));

    final transactionsList = transactionsAsync.when(
      data: (data) {
        if (data.isEmpty) return <TransactionItem>[];
        return data.map<TransactionItem>((item) {
          final receiptNo = item['receipt_number']?.toString() ?? item['id']?.toString() ?? 'REC-000';
          final student = item['student'] as Map<String, dynamic>?;
          final name = student?['full_name']?.toString() ?? 'Student';
          final rollNo = student?['student_id_code']?.toString() ?? student?['registration_number']?.toString() ?? '—';

          final studentProgram = student?['program'];
          String program = '—';
          if (studentProgram is Map) {
            program = studentProgram['code']?.toString() ?? studentProgram['name']?.toString() ?? '—';
          } else if (studentProgram is String) {
            program = studentProgram;
          }

          final amountPaid = (num.tryParse(item['amount_paid'].toString()) ?? 0).toDouble();
          final amountStr = 'PKR ${NumberFormat('#,##0').format(amountPaid)}';
          final method = item['payment_method']?.toString() ?? 'Cash';

          String dateStr = '—';
          final rawDate = item['payment_date'] ?? item['created_at'];
          if (rawDate != null) {
            try {
              final parsed = DateTime.parse(rawDate.toString());
              dateStr = DateFormat('MMM dd, yyyy').format(parsed);
            } catch (_) {
              dateStr = rawDate.toString();
            }
          }

          String initials = 'ST';
          if (name.isNotEmpty) {
            final parts = name.trim().split(' ');
            if (parts.length >= 2) {
              initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
            } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
              initials = parts[0][0].toUpperCase();
            }
          }

          final colors = [
            AppColors.primary,
            AppColors.info,
            AppColors.purple,
            AppColors.accent,
            AppColors.warning,
          ];
          final color = colors[name.hashCode % colors.length];

          return TransactionItem(
            receiptNo: receiptNo,
            initials: initials,
            name: name,
            rollNo: rollNo,
            program: program,
            amount: amountStr,
            method: method,
            date: dateStr,
            status: 'Paid',
            color: color,
          );
        }).toList();
      },
      loading: () => <TransactionItem>[],
      error: (_, __) => <TransactionItem>[],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Text('Recent Transactions', style: AppTextStyles.h3),
                ),
                IconButton(
                  onPressed: _exporting ? null : _exportTransactionsToPdf,
                  icon: _exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded, size: 20),
                  tooltip: 'Export PDF',
                ),
                IconButton(
                  onPressed: _startDate != null ? _clearDateRange : _selectDateRange,
                  icon: Icon(_startDate != null ? Icons.clear : Icons.date_range, size: 20),
                  tooltip: 'Filter Dates',
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    showResponsiveModal(
                      context: context,
                      child: const CreateInvoiceModal(),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Create Invoice'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorder),
          if (transactionsList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No recent transactions found',
                  style: TextStyle(color: AppColors.darkTextMuted),
                ),
              ),
            )
          else ...[
            ...transactionsList.map((e) => _transactionMobileCard(e)),
            // Pagination controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.darkBorder)),
              ),
              child: Row(
                children: [
                  // Rows per page dropdown
                  const Text(
                    'Show',
                    style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _rowsPerPage,
                            dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
                            style: TextStyle(color: isDark ? AppColors.darkText : AppColors.text, fontSize: 12),
                            icon: Icon(Icons.keyboard_arrow_down, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted, size: 16),
                            items: [15, 25, 50, 75, 100].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString(), style: TextStyle(color: isDark ? AppColors.darkText : AppColors.text)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _rowsPerPage = value;
                                  _currentPage = 1;
                                });
                              }
                            },
                          ),
                        ),
                      );
                    }
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'per page',
                    style: TextStyle(color: AppColors.darkTextMuted, fontSize: 12),
                  ),
                  const Spacer(),
                  // Page navigation
                  IconButton(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: _currentPage > 1 ? Colors.white : AppColors.darkTextMuted,
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_currentPage',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: transactionsList.length >= _rowsPerPage
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: transactionsList.length >= _rowsPerPage ? Colors.white : AppColors.darkTextMuted,
                      padding: const EdgeInsets.all(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _transactionMobileCard(TransactionItem e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: e.color,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              e.initials,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${e.receiptNo} · ${e.date}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.darkTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                e.amount,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              BadgeChip.status(e.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(fontSize: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class TransactionItem {
  final String receiptNo;
  final String initials;
  final String name;
  final String rollNo;
  final String program;
  final String amount;
  final String method;
  final String date;
  final String status;
  final Color color;

  TransactionItem({
    required this.receiptNo,
    required this.initials,
    required this.name,
    required this.rollNo,
    required this.program,
    required this.amount,
    required this.method,
    required this.date,
    required this.status,
    required this.color,
  });
}

class PendingAssignmentItem {
  final int id;
  final String invoiceNo;
  final String initials;
  final String name;
  final String rollNo;
  final String feeType;
  final String dueAmount;
  final String dueDate;
  final String status;
  final Color color;

  PendingAssignmentItem({
    required this.id,
    required this.invoiceNo,
    required this.initials,
    required this.name,
    required this.rollNo,
    required this.feeType,
    required this.dueAmount,
    required this.dueDate,
    required this.status,
    required this.color,
  });
}

class DefaulterItem {
  final String initials;
  final String name;
  final String rollNo;
  final String overdue;
  final String amount;
  final Color color;
  final Color amountColor;

  DefaulterItem({
    required this.initials,
    required this.name,
    required this.rollNo,
    required this.overdue,
    required this.amount,
    required this.color,
    required this.amountColor,
  });
}