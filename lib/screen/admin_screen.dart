import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _adminMenus = [
    {
      'title': 'Artikel',
      'icon': Icons.article_outlined,
      'color': Colors.blue,
      'count': 12,
    },
    {
      'title': 'Produk',
      'icon': Icons.inventory_2_outlined,
      'color': Colors.green,
      'count': 145,
    },
    {
      'title': 'Orders',
      'icon': Icons.shopping_bag_outlined,
      'color': Colors.orange,
      'count': 89,
    },
    {
      'title': 'Users',
      'icon': Icons.people_outline,
      'color': Colors.purple,
      'count': 234,
    },
    {
      'title': 'Sellers',
      'icon': Icons.store_outlined,
      'color': Colors.teal,
      'count': 45,
    },
    {
      'title': 'Promo',
      'icon': Icons.local_offer_outlined,
      'color': Colors.red,
      'count': 8,
    },
    {
      'title': 'Complaints',
      'icon': Icons.report_outlined,
      'color': Colors.amber,
      'count': 5,
    },
    {
      'title': 'Payment Methods',
      'icon': Icons.payment_outlined,
      'color': Colors.indigo,
      'count': 4,
    },
    {
      'title': 'Shipping Methods',
      'icon': Icons.local_shipping_outlined,
      'color': Colors.cyan,
      'count': 8,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildManagementTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Petopia Management Dashboard',
                  style: TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Logout admin
              Navigator.of(context).pushReplacementNamed('/login');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'Management'),
          Tab(text: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Management',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _adminMenus.length,
            itemBuilder: (context, index) {
              final menu = _adminMenus[index];
              return _buildManagementCard(menu);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Settings',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsCard('App Configuration', Icons.settings, () {}),
          _buildSettingsCard('User Management', Icons.people, () {}),
          _buildSettingsCard('Security Settings', Icons.security, () {}),
          _buildSettingsCard('Backup & Restore', Icons.backup, () {}),
          _buildSettingsCard('System Logs', Icons.description, () {}),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('Total Users', '234', Icons.people, Colors.blue),
        _buildStatCard('Total Products', '145', Icons.inventory, Colors.green),
        _buildStatCard('Active Orders', '89', Icons.shopping_bag, Colors.orange),
        _buildStatCard('Total Revenue', 'Rp 15.2M', Icons.monetization_on, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up, color: Colors.green, size: 16),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(Map<String, dynamic> menu) {
    return GestureDetector(
      onTap: () {
        // Navigate to specific management screen
        _handleManagementTap(menu['title']);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: menu['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                menu['icon'],
                color: menu['color'],
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              menu['title'],
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: menu['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${menu['count']}',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: menu['color'],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.white,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      {'action': 'New user registered', 'time': '2 minutes ago', 'icon': Icons.person_add},
      {'action': 'Product "Royal Canin" updated', 'time': '15 minutes ago', 'icon': Icons.edit},
      {'action': 'Order #INV-1234567 completed', 'time': '1 hour ago', 'icon': Icons.check_circle},
      {'action': 'New article published', 'time': '2 hours ago', 'icon': Icons.article},
      {'action': 'Seller "Pet Store ABC" verified', 'time': '3 hours ago', 'icon': Icons.verified},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                activity['icon'] as IconData,
                color: AppColors.primaryColor,
                size: 16,
              ),
            ),
            title: Text(
              activity['action'] as String,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              activity['time'] as String,
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleManagementTap(String title) {
    // Navigate to specific management screens
    switch (title) {
      case 'Artikel':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ArticleManagementScreen()),
        );
        break;
      case 'Produk':
        _showComingSoonDialog('Product Management');
        break;
      case 'Orders':
        _showComingSoonDialog('Order Management');
        break;
      case 'Users':
        _showComingSoonDialog('User Management');
        break;
      case 'Sellers':
        _showComingSoonDialog('Seller Management');
        break;
      case 'Promo':
        _showComingSoonDialog('Promo Management');
        break;
      case 'Complaints':
        _showComingSoonDialog('Complaint Management');
        break;
      case 'Payment Methods':
        _showComingSoonDialog('Payment Method Management');
        break;
      case 'Shipping Methods':
        _showComingSoonDialog('Shipping Method Management');
        break;
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature feature will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Basic Article Management Screen
class ArticleManagementScreen extends StatefulWidget {
  const ArticleManagementScreen({Key? key}) : super(key: key);

  @override
  State<ArticleManagementScreen> createState() => _ArticleManagementScreenState();
}

class _ArticleManagementScreenState extends State<ArticleManagementScreen> {
  final List<Map<String, dynamic>> _articles = [
    {
      'title': 'Kucing: Hewan Peliharaan yang Menggemaskan',
      'category': 'Cat',
      'author': 'Admin',
      'published': true,
      'date': '2024-03-15',
    },
    {
      'title': 'Tips Merawat Anak Anjing',
      'category': 'Dog',
      'author': 'Admin',
      'published': false,
      'date': '2024-03-14',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Article Management',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: () {
              // Add new article
              _showAddArticleDialog();
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                article['title'],
                style: const TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Category: ${article['category']}'),
                  Text('Date: ${article['date']}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: article['published'] ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      article['published'] ? 'Published' : 'Draft',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditArticleDialog(article);
                      } else if (value == 'delete') {
                        _deleteArticle(index);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddArticleDialog() {
    // Show dialog to add new article
    showDialog(
      context: context,
      builder: (context) => const AddArticleDialog(),
    );
  }

  void _showEditArticleDialog(Map<String, dynamic> article) {
    // Show dialog to edit article
    showDialog(
      context: context,
      builder: (context) => EditArticleDialog(article: article),
    );
  }

  void _deleteArticle(int index) {
    setState(() {
      _articles.removeAt(index);
    });
  }
}

// Add Article Dialog
class AddArticleDialog extends StatefulWidget {
  const AddArticleDialog({Key? key}) : super(key: key);

  @override
  State<AddArticleDialog> createState() => _AddArticleDialogState();
}

class _AddArticleDialogState extends State<AddArticleDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'Cat';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Article'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ['Cat', 'Dog', 'Birds', 'Fishes', 'General']
                  .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Add article logic here
            Navigator.pop(context);
          },
          child: const Text('Add Article'),
        ),
      ],
    );
  }
}

// Edit Article Dialog
class EditArticleDialog extends StatefulWidget {
  final Map<String, dynamic> article;

  const EditArticleDialog({Key? key, required this.article}) : super(key: key);

  @override
  State<EditArticleDialog> createState() => _EditArticleDialogState();
}

class _EditArticleDialogState extends State<EditArticleDialog> {
  late TextEditingController _titleController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article['title']);
    _selectedCategory = widget.article['category'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Article'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ['Cat', 'Dog', 'Birds', 'Fishes', 'General']
                  .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Published'),
              value: widget.article['published'],
              onChanged: (value) {
                setState(() {
                  widget.article['published'] = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Update article logic here
            Navigator.pop(context);
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}