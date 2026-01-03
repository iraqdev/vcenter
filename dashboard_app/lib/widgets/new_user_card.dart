import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';

class NewUserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewDetails;

  const NewUserCard({
    super.key,
    required this.user,
    required this.onApprove,
    required this.onReject,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط جديد
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.new_releases, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'حساب جديد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  _formatDate(user.createdAt),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // معلومات المستخدم
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // صورة المستخدم
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      backgroundImage: user.profilePic != null 
                          ? NetworkImage(user.profilePic!)
                          : null,
                      child: user.profilePic == null
                          ? Icon(Icons.person, color: Colors.orange, size: 30)
                          : null,
                    ),
                    SizedBox(width: 15),
                    
                    // معلومات المستخدم الأساسية
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 6),
                              Text(
                                user.phone,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_city, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 6),
                              Text(
                                user.city,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 15),
                
                // معلومات إضافية
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('العنوان', user.address),
                      _buildDetailRow('المنطقة القريبة', user.near),
                      _buildDetailRow('النقاط', '${user.points}'),
                      if (user.shopLocation != null)
                        _buildDetailRow('موقع المحل', 
                          '${user.shopLocation!['lat']?.toStringAsFixed(4)}, ${user.shopLocation!['lng']?.toStringAsFixed(4)}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // أزرار المراجعة
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
                // الصف الأول - أزرار المراجعة
                Row(
                  children: [
                    // زر عرض التفاصيل
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.visibility,
                        label: 'التفاصيل',
                        color: Colors.blue,
                        onTap: onViewDetails,
                      ),
                    ),
                    SizedBox(width: 8),
                    
                    // زر الرفض
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.cancel,
                        label: 'رفض',
                        color: Colors.red,
                        onTap: onReject,
                      ),
                    ),
                    SizedBox(width: 8),
                    
                    // زر الموافقة
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.check_circle,
                        label: 'موافقة',
                        color: Colors.green,
                        onTap: onApprove,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
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
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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
      final googleMapsUrl = 'https://www.google.com/maps?q=$lat,$lng';
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('لا يمكن فتح خرائط جوجل');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'لا يمكن فتح خرائط جوجل: ${e.toString()}');
    }
  }

  Future<void> _openAppleMaps(double lat, double lng, BuildContext context) async {
    try {
      final appleMapsUrl = 'https://maps.apple.com/?q=$lat,$lng';
      if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(
          Uri.parse(appleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('لا يمكن فتح خرائط آبل');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'لا يمكن فتح خرائط آبل: ${e.toString()}');
    }
  }

  Future<void> _openWaze(double lat, double lng, BuildContext context) async {
    try {
      // رابط Waze للتطبيق
      final wazeAppUrl = 'waze://?ll=$lat,$lng&navigate=yes';
      // رابط Waze للويب كبديل
      final wazeWebUrl = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
      
      // محاولة فتح تطبيق Waze أولاً
      if (await canLaunchUrl(Uri.parse(wazeAppUrl))) {
        await launchUrl(Uri.parse(wazeAppUrl));
      } else if (await canLaunchUrl(Uri.parse(wazeWebUrl))) {
        // إذا فشل التطبيق، افتح الموقع
        await launchUrl(
          Uri.parse(wazeWebUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('لا يمكن فتح Waze');
      }
    } catch (e) {
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
