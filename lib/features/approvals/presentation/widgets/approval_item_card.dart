import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../material_requests/presentation/pages/material_request_detail_page.dart';
import '../../domain/entities/approval_item.dart';

class ApprovalItemCard extends StatelessWidget {
  final ApprovalItem item;

  const ApprovalItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isHigh = item.priority == 'High Priority';
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDE0D5)),
      ),
      child: InkWell(
        onTap: item.doctype == 'Material Request'
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MaterialRequestDetailPage(
                      requestName: item.name,
                    ),
                  ),
                );
              }
            : null, // Disabled click for Purchase Orders as requested
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF9F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.doctype == 'Purchase Order'
                            ? Icons.shopping_cart_outlined
                            : item.doctype == 'Material Request'
                                ? Icons.inventory_2_outlined
                                : Icons.description_outlined,
                        color: const Color(0xFF319F77),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.doctype,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusBadge(item.status),
                    const SizedBox(height: 4),
                    Text(
                      item.priority,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isHigh ? Colors.red.shade600 : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.project ?? 'No Project',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.owner ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  currencyFormatter.format(item.amount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor = Colors.orange.shade600;
    IconData icon = Icons.hourglass_bottom_outlined;

    final lower = status.toLowerCase();
    if (lower == 'approved' || lower == 'completed' || lower == 'closed' || lower == 'submitted') {
      badgeColor = AppColors.primary;
      icon = Icons.check_circle_outline;
    } else if (lower == 'rejected' || lower == 'cancelled') {
      badgeColor = Colors.red.shade600;
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            status,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
