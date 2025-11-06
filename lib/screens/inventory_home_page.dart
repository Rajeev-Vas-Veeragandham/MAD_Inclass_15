import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';
import 'add_edit_item_screen.dart';
import 'dashboard_screen.dart';
import 'bulk_operations_screen.dart';

class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({super.key});

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _defaultCategories = ['All', 'Electronics', 'Clothing', 'Food', 'Books', 'Other'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory Manager'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory_2), text: 'Inventory'),
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.playlist_add_check), text: 'Bulk Ops'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.data_usage),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Add Sample Data'),
                    content: const Text('This will add 12 sample items to your inventory. Continue?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Add Samples'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adding sample data...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                  await _firestoreService.addSampleData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sample data added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              tooltip: 'Add Sample Data',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Inventory Tab
            Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search items...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                // Category Filter
                StreamBuilder<List<String>>(
                  stream: _firestoreService.getCategories(),
                  builder: (context, snapshot) {
                    final categories = ['All', ...snapshot.data ?? []];
                    final allCategories = [..._defaultCategories, ...categories].toSet().toList();
                    
                    return SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: allCategories.length,
                        itemBuilder: (context, index) {
                          final category = allCategories[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? category : 'All';
                                });
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Inventory List
                Expanded(
                  child: StreamBuilder<List<Item>>(
                    stream: _searchQuery.isNotEmpty 
                        ? _firestoreService.searchItems(_searchQuery)
                        : _firestoreService.getItemsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading items...'),
                            ],
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}'),
                            ],
                          ),
                        );
                      }

                      final allItems = snapshot.data ?? [];
                      final filteredItems = _selectedCategory == 'All'
                          ? allItems
                          : allItems.where((item) => item.category == _selectedCategory).toList();

                      if (filteredItems.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No items found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              Text('Try adjusting your search or add new items'),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _buildInventoryItem(item, context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            
            // Dashboard Tab
            DashboardScreen(),
            
            // Bulk Operations Tab
            BulkOperationsScreen(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddEditItemScreen()),
            );
          },
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildInventoryItem(Item item, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getItemColor(item),
          child: Icon(
            _getItemIcon(item),
            color: Colors.white,
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${item.category}'),
            Text('Stock: ${item.quantity}'),
            if (item.isOutOfStock)
              const Text('OUT OF STOCK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            else if (item.isLowStock)
              const Text('LOW STOCK', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${item.price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Value: \$${item.totalValue.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditItemScreen(item: item)),
          );
        },
      ),
    );
  }

  Color _getItemColor(Item item) {
    if (item.isOutOfStock) return Colors.red;
    if (item.isLowStock) return Colors.orange;
    return Colors.green;
  }

  IconData _getItemIcon(Item item) {
    if (item.isOutOfStock) return Icons.warning;
    if (item.isLowStock) return Icons.warning_amber;
    return Icons.inventory_2;
  }
}