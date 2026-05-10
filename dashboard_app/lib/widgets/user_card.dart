import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // معلومات المستخدم الأساسية
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // صورة المستخدم أو أيقونة افتراضية
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.deepPurple.withOpacity(0.1),
                      backgroundImage: user.profilePic != null 
                          ? NetworkImage(user.profilePic!)
                          : null,
                      child: user.profilePic == null
                          ? Icon(Icons.person, color: Colors.deepPurple)
                          : null,
                    ),
                    SizedBox(width: 12),
                    
                    // معلومات المستخدم
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            user.phone,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            user.city,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // حالة المستخدم
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.isActive ? 'نشط' : 'محظور',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // معلومات إضافية
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.stars,
                      '${user.points} نقطة',
                      Colors.amber,
                    ),
                    SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.location_on,
                      user.near,
                      Colors.blue,
                    ),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // تاريخ التسجيل
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      'تاريخ التسجيل: ${_formatDate(user.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                if (user.shopPic != null && user.shopPic!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Text(
                    'صورة المحل',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      user.shopPic!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: Colors.grey[100],
                        alignment: Alignment.center,
                        child: Icon(Icons.broken_image, color: Colors.grey[500]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // أزرار التحكم
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Column(
              children: [
                // الصف الأول - أزرار أساسية
                Row(
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
                    
                    // زر تفعيل/حظر
                    Expanded(
                      child: _buildActionButton(
                        icon: user.isActive ? Icons.block : Icons.check_circle,
                        label: user.isActive ? 'حظر' : 'تفعيل',
                        color: user.isActive ? Colors.red : Colors.green,
                        onTap: onToggleStatus,
                      ),
                    ),
                    SizedBox(width: 8),
                    
                    // زر الحذف
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete,
                        label: 'حذف',
                        color: Colors.red[700]!,
                        onTap: onDelete,
                      ),
                    ),
                  ],
                ),
                
                // الصف الثاني - زر الموقع (إذا كان متوفراً)
                if (user.shopLocation != null) ...[
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(
                      icon: Icons.location_on,
                      label: 'عرض موقع المحل',
                      color: Colors.purple,
                      onTap: () => _openLocationOnMaps(user, context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // فتح الموقع على خرائط جوجل
  Future<void> _openLocationOnMaps(UserModel user, BuildContext context) async {
    if (user.shopLocation == null) return;
    
    final lat = user.shopLocation!['lat'];
    final lng = user.shopLocation!['lng'];
    
    if (lat == null || lng == null) return;
    
    // عرض خيارات الخرائط للمستخدم
    _showMapOptionsDialog(context, lat, lng);
  }

  void _showMapOptionsDialog(BuildContext context, double lat, double lng) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Text('اختر تطبيق الخرائط'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر التطبيق الذي تريد فتح الموقع به:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              
              // زر خرائط جوجل
              _buildMapOptionButton(
                context: context,
                title: 'خرائط جوجل',
                subtitle: 'Google Maps',
                icon: Icons.map,
                color: Colors.blue,
                onTap: () {
                  Get.back();
                  _openGoogleMaps(lat, lng, context);
                },
              ),
              
              SizedBox(height: 12),
              
              // زر خرائط آبل
              _buildMapOptionButton(
                context: context,
                title: 'خرائط آبل',
                subtitle: 'Apple Maps',
                icon: Icons.location_on,
                color: Colors.green,
                onTap: () {
                  Get.back();
                  _openAppleMaps(lat, lng, context);
                },
              ),
              
              SizedBox(height: 12),
              
              // زر Waze
              _buildMapOptionButton(
                context: context,
                title: 'Waze',
                subtitle: 'ملاحة واتجاهات',
                icon: Icons.navigation,
                color: Colors.purple,
                onTap: () {
                  Get.back();
                  _openWaze(lat, lng, context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapOptionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(double lat, double lng, BuildContext context) async {
    try {
      // محاولة فتح تطبيق خرائط جوجل مباشرة
      final googleMapsAppUrl = 'comgooglemaps://?q=$lat,$lng&center=$lat,$lng&zoom=14';
      final googleMapsWebUrl = 'https://www.google.com/maps?q=$lat,$lng';
      
      print('🗺️ محاولة فتح خرائط جوجل للموقع: $lat, $lng');
      
      // محاولة فتح التطبيق أولاً
      if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
        print('✅ فتح تطبيق خرائط جوجل');
        await launchUrl(Uri.parse(googleMapsAppUrl));
      } else if (await canLaunchUrl(Uri.parse(googleMapsWebUrl))) {
        print('✅ فتح خرائط جوجل في المتصفح');
        await launchUrl(
          Uri.parse(googleMapsWebUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('لا يمكن فتح خرائط جوجل');
      }
    } catch (e) {
      print('❌ خطأ في فتح خرائط جوجل: $e');
      _showErrorSnackBar(context, 'لا يمكن فتح خرائط جوجل: ${e.toString()}');
    }
  }

  Future<void> _openAppleMaps(double lat, double lng, BuildContext context) async {
    try {
      // محاولة فتح تطبيق خرائط آبل مباشرة
      final appleMapsAppUrl = 'maps://?q=$lat,$lng';
      final appleMapsWebUrl = 'https://maps.apple.com/?q=$lat,$lng';
      
      print('🍎 محاولة فتح خرائط آبل للموقع: $lat, $lng');
      
      // محاولة فتح التطبيق أولاً
      if (await canLaunchUrl(Uri.parse(appleMapsAppUrl))) {
        print('✅ فتح تطبيق خرائط آبل');
        await launchUrl(Uri.parse(appleMapsAppUrl));
      } else if (await canLaunchUrl(Uri.parse(appleMapsWebUrl))) {
        print('✅ فتح خرائط آبل في المتصفح');
        await launchUrl(
          Uri.parse(appleMapsWebUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('لا يمكن فتح خرائط آبل');
      }
    } catch (e) {
      print('❌ خطأ في فتح خرائط آبل: $e');
      _showErrorSnackBar(context, 'لا يمكن فتح خرائط آبل: ${e.toString()}');
    }
  }

  Future<void> _openWaze(double lat, double lng, BuildContext context) async {
    try {
      // رابط Waze للتطبيق
      final wazeAppUrl = 'waze://?ll=$lat,$lng&navigate=yes';
      // رابط Waze للويب كبديل
      final wazeWebUrl = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
      
      print('🚗 محاولة فتح Waze للموقع: $lat, $lng');
      
      // محاولة فتح تطبيق Waze أولاً
      if (await canLaunchUrl(Uri.parse(wazeAppUrl))) {
        print('✅ فتح تطبيق Waze');
        await launchUrl(Uri.parse(wazeAppUrl));
      } else if (await canLaunchUrl(Uri.parse(wazeWebUrl))) {
        print('✅ فتح Waze في المتصفح');
        // إذا فشل التطبيق، افتح الموقع
        await launchUrl(
          Uri.parse(wazeWebUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('لا يمكن فتح Waze');
      }
    } catch (e) {
      print('❌ خطأ في فتح Waze: $e');
      _showErrorSnackBar(context, 'لا يمكن فتح Waze: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
