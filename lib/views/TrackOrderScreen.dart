import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ecommerce/models/Bill.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/controllers/OrdersController.dart';
import 'package:ecommerce/controllers/Landing_controller.dart';

class TrackOrderScreen extends StatefulWidget {
  final Bill order;

  const TrackOrderScreen({Key? key, required this.order}) : super(key: key);

  @override
  _TrackOrderScreenState createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  Timer? _statusUpdateTimer;

  // بيانات الطلب (سيتم تحديثها تلقائياً)
  String get deliveryTime => widget.order.deliveryTime ?? "لم يتم تحديد الوقت بعد";
  String get orderStatus => widget.order.orderstatus ?? "جاري التجهيز";

  @override
  void initState() {
    super.initState();
    
    // تهيئة الفيديو مع معالجة الأخطاء
    try {
      _videoController = VideoPlayerController.asset('order.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            // تشغيل الفيديو في حلقة
            _videoController.setLooping(true);
            _videoController.play();
          }
        }).catchError((error) {
          print('⚠️ TrackOrderScreen - خطأ في تحميل الفيديو: $error');
          if (mounted) {
            setState(() {
              _isVideoInitialized = false;
            });
          }
        });
    } catch (e) {
      print('⚠️ TrackOrderScreen - خطأ في تهيئة الفيديو: $e');
      _isVideoInitialized = false;
    }
    
    // بدء التحديث الدوري لحالة الطلب كل 10 ثوان
    _startStatusUpdate();
  }

  @override
  void dispose() {
    try {
      _videoController.dispose();
    } catch (e) {
      print('⚠️ TrackOrderScreen - خطأ في dispose الفيديو: $e');
    }
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  // بدء التحديث الدوري لحالة الطلب
  void _startStatusUpdate() {
    _statusUpdateTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        _updateOrderStatus();
      }
    });
  }

  // تحديث حالة الطلب من Firebase
  Future<void> _updateOrderStatus() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('bills')
          .where('originalId', isEqualTo: widget.order.id)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final newStatus = data['orderstatus'] ?? 'جاري التجهيز';
        final newDeliveryTime = data['deliveryTime'];
        
        // تحديث حالة الطلب ووقت التوصيل في widget.order
        bool needsUpdate = false;
        if (widget.order.orderstatus != newStatus) {
          widget.order.orderstatus = newStatus;
          needsUpdate = true;
        }
        if (widget.order.deliveryTime != newDeliveryTime) {
          widget.order.deliveryTime = newDeliveryTime;
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          setState(() {
            // إعادة بناء الواجهة لتحديث حالة الطلب ووقت التوصيل
          });
          
          // تحديث OrdersController أيضاً
          try {
            final ordersController = Get.find<OrdersController>();
            final orderIndex = ordersController.ordersList.indexWhere(
              (order) => order.id == widget.order.id
            );
            
            if (orderIndex != -1) {
              ordersController.ordersList[orderIndex].orderstatus = newStatus;
              ordersController.ordersList[orderIndex].deliveryTime = newDeliveryTime;
              ordersController.ordersList.refresh();
            }
          } catch (e) {
            print('⚠️ TrackOrderScreen - خطأ في تحديث OrdersController: $e');
          }
        }
      }
    } catch (e) {
      print('❌ TrackOrderScreen - خطأ في تحديث حالة الطلب: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'تتبع الطلب',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[800]),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // فيديو إصلاح الهواتف
            _buildOrderVideo(),
            
            SizedBox(height: 20),
            
            // رسالة وقت الوصول
            _buildDeliveryTimeMessage(),
            
            SizedBox(height: 30),
            
            // مراحل التوصيل
            _buildDeliverySteps(),
            
            SizedBox(height: 20),
            
            // حالة الطلب
            _buildOrderStatus(),
            
            SizedBox(height: 30),
            
            // تفاصيل الطلب
            _buildOrderDetails(),
            
            SizedBox(height: 20),
            
            // زر إلغاء الطلب (يظهر فقط للطلبات القابلة للإلغاء)
            if (_canCancelOrder()) _buildCancelOrderButton(),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderVideo() {
    return Container(
      height: 250,
      width: double.infinity,
                  decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: _isVideoInitialized
            ? VideoPlayer(_videoController)
            : Container(
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'جاري تحميل الفيديو...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDeliveryTimeMessage() {
    // إخفاء رسالة الوقت في حالة "جاري التجهيز"
    if (orderStatus == 'جاري التجهيز' || orderStatus == 'قيد التحضير') {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.access_time,
            size: 40,
            color: Colors.blue[600],
          ),
          SizedBox(height: 10),
          Text(
            'سيصل طلبك خلال',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 5),
          Text(
            deliveryTime,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySteps() {
    // تحديد المراحل النشطة بناءً على حالة الطلب
    bool isPreparing = orderStatus == 'جاري التجهيز' || orderStatus == 'قيد التحضير';
    bool isDelivering = orderStatus == 'جاري التوصيل';
    bool isDelivered = orderStatus == 'تم الاستلام';
    bool isCancelled = orderStatus == 'ملغي';
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStep(
            icon: Icons.inventory_2,
            label: 'التجهيز',
            isActive: isPreparing,
            isCompleted: isDelivering || isDelivered,
          ),
          _buildArrow(),
          _buildStep(
            icon: Icons.motorcycle,
            label: 'التوصيل',
            isActive: isDelivering,
            isCompleted: isDelivered,
          ),
          _buildArrow(),
          _buildStep(
            icon: Icons.check_circle,
            label: 'الاستلام',
            isActive: isDelivered,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({required IconData icon, required String label, required bool isActive, bool isCompleted = false}) {
    Color stepColor;
    Color textColor;
    
    if (isCompleted) {
      stepColor = Colors.green[600]!;
      textColor = Colors.green[600]!;
    } else if (isActive) {
      stepColor = Colors.blue[600]!;
      textColor = Colors.blue[600]!;
    } else {
      stepColor = Colors.grey[300]!;
      textColor = Colors.grey[500]!;
    }
    
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: stepColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Icon(
      Icons.arrow_forward,
      color: Colors.grey[400],
      size: 20,
    );
  }

  Widget _buildOrderStatus() {
    // تحديد اللون والأيقونة بناءً على حالة الطلب
    Color statusColor;
    IconData statusIcon;
    
    switch (orderStatus) {
      case 'جاري التجهيز':
      case 'قيد التحضير':
        statusColor = Colors.orange[600]!;
        statusIcon = Icons.access_time;
        break;
      case 'جاري التوصيل':
        statusColor = Colors.blue[600]!;
        statusIcon = Icons.motorcycle;
        break;
      case 'تم الاستلام':
        statusColor = Colors.green[600]!;
        statusIcon = Icons.check_circle;
        break;
      case 'ملغي':
        statusColor = Colors.red[600]!;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey[600]!;
        statusIcon = Icons.info_outline;
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          SizedBox(width: 10),
          Text(
            'حالة الطلب: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            orderStatus,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل الطلب',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 15),
          
          // قائمة المنتجات
          if (widget.order.items != null && widget.order.items!.isNotEmpty)
            ...widget.order.items!.map((item) => _buildProductItem(item)).toList(),
          
          Divider(color: Colors.grey[300]),
          
          // المجموع الكلي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الكلي',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '${_calculateTotal().toStringAsFixed(0)} د.ع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    final productName = item['title'] ?? item['name'] ?? 'منتج غير محدد';
    final quantity = item['count'] ?? item['quantity'] ?? 1;
    final price = item['price'] ?? item['lastprice'] ?? 0;
    final totalPrice = (price * quantity).toDouble();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // صورة المنتج
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: item['image'] != null && item['image'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['image'].toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.shopping_bag,
                          color: Colors.grey[400],
                          size: 20,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.shopping_bag,
                    color: Colors.grey[400],
                    size: 20,
                  ),
          ),
          SizedBox(width: 12),
          
          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  'الكمية: $quantity',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // السعر
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${price.toStringAsFixed(0)} د.ع',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${totalPrice.toStringAsFixed(0)} د.ع',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    if (widget.order.items == null) return 0.0;
    
    double total = 0.0;
    for (var item in widget.order.items!) {
      final quantity = item['count'] ?? item['quantity'] ?? 1;
      final price = item['price'] ?? item['lastprice'] ?? 0;
      total += (price * quantity).toDouble();
    }
    return total;
  }

  // تحديد ما إذا كان يمكن إلغاء الطلب
  bool _canCancelOrder() {
    // يمكن إلغاء الطلب فقط إذا كان في حالة "جاري التجهيز" أو "قيد التحضير"
    return orderStatus == 'جاري التجهيز' || 
           orderStatus == 'قيد التحضير' ||
           orderStatus == null || 
           orderStatus.isEmpty;
  }

  Widget _buildCancelOrderButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showCancelOrderDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'إلغاء الطلب',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showCancelOrderDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => true, // السماح بالإغلاق بالضغط على زر الرجوع
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // أيقونة التحذير مع انيميشن
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.1),
                          Colors.red.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // العنوان
                  Text(
                    'إلغاء الطلب',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // الرسالة
                  Text(
                    'هل أنت متأكد من إلغاء هذا الطلب؟\nسيتم تحديث حالة الطلب إلى "ملغي" ولن يمكن التراجع عن هذا الإجراء.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // تحذير إضافي
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سيتم إلغاء الطلب نهائياً ولن يتم إرساله',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  
                  // الأزرار
                  Row(
                    children: [
                      // زر الإلغاء
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop(); // إغلاق الدايلوج
                            },
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.grey.withOpacity(0.1),
                            highlightColor: Colors.grey.withOpacity(0.05),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      
                      // زر التأكيد
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop(); // إغلاق الدايلوج فوراً
                              // تنفيذ إلغاء الطلب بعد إغلاق الدايلوج مباشرة
                              _cancelOrder();
            },
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.white.withOpacity(0.2),
                            highlightColor: Colors.white.withOpacity(0.1),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red,
                                    Colors.red.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
            child: Text(
              'تأكيد الإلغاء',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
            ),
          ),
        ],
      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelOrder() async {
    try {
      print('🔍 TrackOrderScreen - بدء إلغاء الطلب: ${widget.order.id}');
      
      // تحديث حالة الطلب في Firebase مع timeout
      final query = await FirebaseFirestore.instance
          .collection('bills')
          .where('originalId', isEqualTo: widget.order.id)
          .limit(1)
          .get()
          .timeout(Duration(seconds: 10));
      
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        print('✅ TrackOrderScreen - تم العثور على الطلب: ${doc.id}');
        
        // تحديث حالة الطلب مع timeout
        await doc.reference.update({
          'status': 'ملغي',
          'orderstatus': 'ملغي',
          'updatedAt': FieldValue.serverTimestamp(),
          'cancelledAt': FieldValue.serverTimestamp(),
        }).timeout(Duration(seconds: 10));
        
        print('✅ TrackOrderScreen - تم تحديث حالة الطلب إلى "ملغي"');
        
        // تحديث القائمة المحلية
        try {
          final ordersController = Get.find<OrdersController>();
          final orderIndex = ordersController.ordersList.indexWhere(
            (order) => order.id == widget.order.id
          );
          
          if (orderIndex != -1) {
            ordersController.ordersList[orderIndex].orderstatus = 'ملغي';
            ordersController.ordersList.refresh();
          }
        } catch (e) {
          print('⚠️ TrackOrderScreen - خطأ في تحديث القائمة المحلية: $e');
        }
        
        // العودة إلى شاشة الطلبات مباشرة بدون أي رسائل
        Get.back(); // العودة من شاشة تتبع الطلب
        
      } else {
        print('❌ TrackOrderScreen - لم يتم العثور على الطلب');
        
        // إظهار رسالة خطأ
        Get.snackbar(
          'خطأ',
          'لم يتم العثور على الطلب في قاعدة البيانات',
          backgroundColor: Colors.red[600],
          colorText: Colors.white,
          icon: Icon(Icons.error, color: Colors.white),
          duration: Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('❌ TrackOrderScreen - خطأ في إلغاء الطلب: $e');
      
      // تحديد نوع الخطأ
      String errorMessage = 'حدث خطأ أثناء إلغاء الطلب';
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى';
      } else if (e.toString().contains('network')) {
        errorMessage = 'خطأ في الاتصال بالإنترنت';
      }
      
      // إظهار رسالة خطأ
      Get.snackbar(
        'خطأ',
        errorMessage,
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        icon: Icon(Icons.error, color: Colors.white),
        duration: Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
