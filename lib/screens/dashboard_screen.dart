import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: StreamBuilder<List<Item>>(
        stream: _firestoreService.getItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading dashboard...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading dashboard',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];
          
          // Calculate statistics
          final totalItems = items.length;
          final totalValue = items.fold(0.0, (sum, item) => sum + item.totalValue);
          final outOfStockItems = items.where((item) => item.isOutOfStock).toList();
          final lowStockItems = items.where((item) => item.isLowStock && !item.isOutOfStock).toList();
          final wellStockedItems = items.where((item) => !item.isLowStock && !item.isOutOfStock).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Text(
                  'Inventory Overview',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Real-time analytics and insights',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Statistics Cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      'Total Items',
                      totalItems.toString(),
                      Icons.inventory_2,
                      Colors.blue,
                      'All products in inventory',
                    ),
                    _buildStatCard(
                      'Total Value',
                      '\$${totalValue.toStringAsFixed(2)}',
                      Icons.attach_money,
                      Colors.green,
                      'Total inventory worth',
                    ),
                    _buildStatCard(
                      'Out of Stock',
                      outOfStockItems.length.toString(),
                      Icons.warning,
                      Colors.red,
                      'Items needing restock',
                    ),
                    _buildStatCard(
                      'Low Stock',
                      lowStockItems.length.toString(),
                      Icons.warning_amber,
                      Colors.orange,
                      'Items below minimum stock',
                    ),
                    _buildStatCard(
                      'Well Stocked',
                      wellStockedItems.length.toString(),
                      Icons.check_circle,
                      Colors.green,
                      'Adequately stocked items',
                    ),
                    _buildStatCard(
                      'Categories',
                      items.map((item) => item.category).toSet().length.toString(),
                      Icons.category,
                      Colors.purple,
                      'Unique categories',
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Out of Stock Items Section
                if (outOfStockItems.isNotEmpty) ...[
                  _buildItemSection(
                    '🚨 Out of Stock Items (${outOfStockItems.length})',
                    outOfStockItems, 
                    Colors.red,
                    Icons.error_outline,
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Low Stock Items Section
                if (lowStockItems.isNotEmpty) ...[
                  _buildItemSection(
                    '⚠️ Low Stock Items (${lowStockItems.length})',
                    lowStockItems, 
                    Colors.orange,
                    Icons.warning_amber,
                  ),
                  const SizedBox(height: 24),
                ],

                // Inventory Health Status
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📊 Inventory Health',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildHealthIndicator('Out of Stock', outOfStockItems.length, totalItems, Colors.red),
                        _buildHealthIndicator('Low Stock', lowStockItems.length, totalItems, Colors.orange),
                        _buildHealthIndicator('Well Stocked', wellStockedItems.length, totalItems, Colors.green),
                      ],
                    ),
                  ),
                ),
                
                // Empty State
                if (outOfStockItems.isEmpty && lowStockItems.isEmpty && items.isNotEmpty)
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.celebration, size: 64, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text(
                            'Excellent Inventory Health!',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All ${items.length} items are properly stocked and ready for sale.',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                // No Items State
                if (items.isEmpty)
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No Inventory Items',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start by adding your first inventory item using the + button.',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String description) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemSection(String title, List<Item> items, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: color.withOpacity(0.1),
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${item.category}'),
                Text('Current Stock: ${item.quantity} units'),
                Text('Price: \$${item.price.toStringAsFixed(2)}'),
                Text('Total Value: \$${item.totalValue.toStringAsFixed(2)}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Stock: ${item.quantity}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildHealthIndicator(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: total > 0 ? count / total : 0,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 8,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
