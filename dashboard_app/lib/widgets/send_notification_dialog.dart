import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../controllers/user_controller.dart';

class SendNotificationDialog extends StatefulWidget {
  const SendNotificationDialog({super.key});

  @override
  State<SendNotificationDialog> createState() => _SendNotificationDialogState();
}

class _SendNotificationDialogState extends State<SendNotificationDialog> {
  final NotificationController notificationController = Get.find<NotificationController>();
  final UserController userController = Get.find<UserController>();
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _actionUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _selectedType = 'all';
  String _selectedTarget = 'all_users';

  final List<Map<String, dynamic>> _notificationTypes = [
    {'value': 'all', 'label': 'عام', 'icon': Icons.notifications, 'color': Colors.blue},
    {'value': 'offer', 'label': 'عرض خاص', 'icon': Icons.local_offer, 'color': Colors.orange},
    {'value': 'promotion', 'label': 'ترويج', 'icon': Icons.campaign, 'color': Colors.purple},
    {'value': 'announcement', 'label': 'إعلان', 'icon': Icons.announcement, 'color': Colors.green},
    {'value': 'reminder', 'label': 'تذكير', 'icon': Icons.alarm, 'color': Colors.red},
  ];

  final List<Map<String, dynamic>> _targetTypes = [
    {'value': 'all_users', 'label': 'جميع المستخدمين', 'icon': Icons.group},
    {'value': 'specific_user', 'label': 'مستخدم محدد', 'icon': Icons.person},
  ];

  @override
  void initState() {
    super.initState();
    // جلب قائمة المستخدمين للبحث بعد انتهاء البناء
    Future.delayed(Duration.zero, () {
      if (mounted) {
        userController.loadAllUsers();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _phoneController.dispose();
    _actionUrlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            // رأس الدايلوج
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.send,
                    color: Colors.deepPurple,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'إرسال إشعار جديد',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),

            // محتوى الدايلوج
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // نوع الإشعار
                      Text(
                        'نوع الإشعار',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      ..._notificationTypes.map((type) => Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedType = type['value'];
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedType == type['value']
                                    ? (type['color'] as Color).withOpacity(0.2)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedType == type['value']
                                      ? type['color'] as Color
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _selectedType == type['value']
                                          ? type['color'] as Color
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      type['icon'] as IconData,
                                      color: _selectedType == type['value']
                                          ? Colors.white
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      type['label'] as String,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedType == type['value']
                                            ? type['color'] as Color
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (_selectedType == type['value'])
                                    Icon(
                                      Icons.check_circle, 
                                      color: type['color'] as Color, 
                                      size: 24
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )).toList(),

                      SizedBox(height: 20),

                      // نوع المستهدف
                      Text(
                        'المستهدف',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      ..._targetTypes.map((target) => Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTarget = target['value'];
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedTarget == target['value']
                                    ? Colors.blue.withOpacity(0.2)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedTarget == target['value']
                                      ? Colors.blue
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    target['icon'] as IconData,
                                    color: _selectedTarget == target['value']
                                        ? Colors.blue
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    target['label'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedTarget == target['value']
                                          ? Colors.blue
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (_selectedTarget == target['value'])
                                    Spacer(),
                                  if (_selectedTarget == target['value'])
                                    Icon(Icons.check_circle, color: Colors.blue, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )).toList(),

                      SizedBox(height: 20),

                      // رقم الهاتف (إذا كان المستهدف مستخدم محدد)
                      if (_selectedTarget == 'specific_user') ...[
                        Text(
                          'رقم الهاتف',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            hintText: 'أدخل رقم الهاتف',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (_selectedTarget == 'specific_user' && (value == null || value.isEmpty)) {
                              return 'يرجى إدخال رقم الهاتف';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                      ],

                      // عنوان الإشعار
                      Text(
                        'عنوان الإشعار',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'أدخل عنوان الإشعار',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال عنوان الإشعار';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // رسالة الإشعار
                      Text(
                        'رسالة الإشعار',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'أدخل رسالة الإشعار',
                          prefixIcon: Icon(Icons.message),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال رسالة الإشعار';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // رابط العمل (اختياري)
                      Text(
                        'رابط العمل (اختياري)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _actionUrlController,
                        decoration: InputDecoration(
                          hintText: 'https://example.com',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // رابط الصورة (اختياري)
                      Text(
                        'رابط الصورة (اختياري)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/image.jpg',
                          prefixIcon: Icon(Icons.image),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // أزرار الإجراءات
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text('إلغاء'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _sendNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('إرسال الإشعار'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      Map<String, dynamic> result;

      if (_selectedTarget == 'all_users') {
        // استخدام الدالة الجديدة لإرسال إشعار مخصص
        result = await notificationController.sendCustomNotificationToAll(
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null,
          actionUrl: _actionUrlController.text.trim().isNotEmpty ? _actionUrlController.text.trim() : null,
          data: {
            'type': _selectedType,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      } else {
        // استخدام الدالة الجديدة لإرسال إشعار مخصص للمستخدم المحدد
        result = await notificationController.sendCustomNotificationToSpecificUser(
          phoneNumber: _phoneController.text.trim(),
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isNotEmpty ? _imageUrlController.text.trim() : null,
          actionUrl: _actionUrlController.text.trim().isNotEmpty ? _actionUrlController.text.trim() : null,
          data: {
            'type': _selectedType,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      }

      if (result['success']) {
        Get.back();
        Get.snackbar(
          'نجح',
          'تم إرسال الإشعار بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في إرسال الإشعار: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
