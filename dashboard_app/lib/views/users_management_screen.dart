import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';
import '../widgets/user_card.dart';
import '../widgets/user_edit_dialog.dart';

class UsersManagementScreen extends StatelessWidget {
  UsersManagementScreen({super.key});

  final UserController userController = Get.find<UserController>();
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'إدارة المستخدمين',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          // مؤشر المستخدمين الجدد
          Obx(() {
            if (userController.newUsersCount.value > 0) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      userController.clearNewUsersCount();
                      Get.snackbar(
                        'تم مسح العداد',
                        'تم مسح عداد المستخدمين الجدد',
                        backgroundColor: Colors.blue,
                        colorText: Colors.white,
                      );
                    },
                    icon: Icon(Icons.person_add, color: Colors.white),
                    tooltip: 'مستخدمين جدد',
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${userController.newUsersCount.value}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return SizedBox.shrink();
          }),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => userController.refreshData(),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث والإحصائيات
          _buildSearchAndStats(),
          
          // قائمة المستخدمين
          Expanded(
            child: Obx(() {
              if (userController.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.deepPurple,
                  ),
                );
              }

              if (userController.allUsers.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () => userController.refreshData(),
                color: Colors.deepPurple,
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: userController.allUsers.length,
                  itemBuilder: (context, index) {
                    final user = userController.allUsers[index];
                    return UserCard(
                      user: user,
                      onEdit: () => _showEditDialog(user),
                      onToggleStatus: () => _toggleUserStatus(user),
                      onDelete: () => _showDeleteConfirmation(user),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndStats() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'البحث في المستخدمين...',
              prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        userController.searchQuery.value = '';
                        userController.loadAllUsers();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.deepPurple),
              ),
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                userController.loadAllUsers();
              } else {
                userController.searchUsers(value);
              }
            },
          ),
          SizedBox(height: 15),
          
          // إحصائيات سريعة
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  'إجمالي',
                  '${userController.allUsers.length}',
                  Colors.blue,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  'نشط',
                  '${userController.activeUsers.length}',
                  Colors.green,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  'محظور',
                  '${userController.inactiveUsers.length}',
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'لا يوجد مستخدمين',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'لم يتم العثور على أي مستخدمين',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(UserModel user) {
    Get.dialog(
      UserEditDialog(
        user: user,
        onSave: (updatedUser) {
          userController.updateUser(updatedUser);
        },
      ),
    );
  }

  void _toggleUserStatus(UserModel user) {
    final newStatus = !user.isActive;
    final action = newStatus ? 'تفعيل' : 'حظر';
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(
              newStatus ? Icons.check_circle : Icons.block,
              color: newStatus ? Colors.green : Colors.red,
            ),
            SizedBox(width: 10),
            Text('$action المستخدم'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من $action المستخدم "${user.name}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              userController.updateUserStatus(user.id, newStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(UserModel user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 10),
            Text('حذف المستخدم'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف المستخدم "${user.name}"؟\nهذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              userController.deleteUser(user.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }
}
