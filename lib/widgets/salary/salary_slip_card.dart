import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/salary.dart';
import '../../config/theme.dart';
import '../../utils/helpers.dart';
import '../common/custom_card.dart';

class SalarySlipCard extends StatelessWidget {
  final SalarySlip salarySlip;
  final VoidCallback? onTap;

  const SalarySlipCard({
    Key? key,
    required this.salarySlip,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(DateTime(salarySlip.year, salarySlip.month)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Net Salary',
                    Helpers.formatCurrency(salarySlip.netSalary),
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Working Days',
                    '${salarySlip.presentDays}/${salarySlip.totalWorkingDays}',
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  'Generated: ${Helpers.formatDate(DateTime.parse(salarySlip.createdAt.toString()))}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (salarySlip.bonus > 0 || salarySlip.deductions > 0)
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[500],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    switch (salarySlip.basicSalary.toString().toLowerCase()) {
      case 'paid':
        chipColor = AppTheme.successColor;
        break;
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'processing':
        chipColor = AppTheme.accentColor;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        salarySlip.presentDays.toString(),
        style: TextStyle(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
