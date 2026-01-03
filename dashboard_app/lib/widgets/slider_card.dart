import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/slider_model.dart';
import '../controllers/slider_controller.dart';

class SliderCard extends StatelessWidget {
  final SliderModel slider;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const SliderCard({
    super.key,
    required this.slider,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة العرض
          _buildSliderImage(),
          
          // معلومات العرض
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان العرض
                Text(
                  slider.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                
                // حالة العرض
                _buildStatusChip(),
                SizedBox(height: 12),
                
                // أزرار الإجراءات
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
        child: CachedNetworkImage(
          imageUrl: slider.image,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.grey[400],
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  'خطأ في تحميل الصورة',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: slider.active ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: slider.active ? Colors.green[300]! : Colors.red[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            slider.active ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: slider.active ? Colors.green[700] : Colors.red[700],
          ),
          SizedBox(width: 4),
          Text(
            slider.active ? 'نشط' : 'غير نشط',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: slider.active ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // زر التعديل
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit,
            label: 'تعديل',
            color: Colors.blue,
            onTap: onEdit,
          ),
        ),
        SizedBox(width: 8),
        
        // زر تبديل الحالة
        Expanded(
          child: _buildActionButton(
            icon: slider.active ? Icons.visibility_off : Icons.visibility,
            label: slider.active ? 'إخفاء' : 'إظهار',
            color: slider.active ? Colors.orange : Colors.green,
            onTap: onToggleStatus,
          ),
        ),
        SizedBox(width: 8),
        
        // زر الحذف
        Expanded(
          child: _buildActionButton(
            icon: Icons.delete,
            label: 'حذف',
            color: Colors.red,
            onTap: onDelete,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
