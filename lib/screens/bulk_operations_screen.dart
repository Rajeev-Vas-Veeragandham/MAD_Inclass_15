import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';
import '../services/firestore_service.dart';

class BulkOperationsScreen extends StatefulWidget {
  const BulkOperationsScreen({super.key});

  @override
  State<BulkOperationsScreen> createState() => _BulkOperationsScreenState();
}

class _BulkOperationsScreenState extends State<BulkOperationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, bool> _selectedItems = {};
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isLoading = false;
  int _selectedOperation = 0;

  void _toggleItemSelection(String itemId, bool selected) {
    setState(() {
      _selectedItems[itemId] = selected;
    });
  }

  void _selectAll(List<Item> items, bool selected) {
    setState(() {
      for (final item in items) {
        _selectedItems[item.id!] = selected;
      }
    });
  }

  List<String> get _selectedItemIds {
    return _selectedItems.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  int get _selectedCount => _selectedItemIds.length;

  Future<void> _performBulkOperation() async {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      switch (_selectedOperation) {
        case 0: // Update Quantity
          final newQuantity = int.tryParse(_quantityController.text);
          if (newQuantity == null || newQuantity < 0) {
            throw Exception('Please enter a valid quantity');
          }
          await _firestoreService.updateMultipleItemsQuantity(_selectedItemIds, newQuantity);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated quantity to $newQuantity for $_selectedCount items'),
              backgroundColor: Colors.green,
            ),
          );
          _quantityController.clear();
          break;

        case 1: // Update Price
          final newPrice = double.tryParse(_priceController.text);
          if (newPrice == null || newPrice < 0) {
            throw Exception('Please enter a valid price');
          }
          final batch = FirebaseFirestore.instance.batch();
          for (final itemId in _selectedItemIds) {
            batch.update(FirebaseFirestore.instance.collection('items').doc(itemId), {'price': newPrice});
          }
          await batch.commit();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated price to \$$newPrice for $_selectedCount items'),
              backgroundColor: Colors.green,
            ),
          );
          _priceController.clear();
          break;

        case 2: // Delete
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Bulk Delete'),
              content: Text('Are you sure you want to permanently delete $_selectedCount items? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await _firestoreService.deleteMultipleItems(_selectedItemIds);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully deleted $_selectedCount items'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() => _selectedItems.clear());
          }
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Operations'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Item>>(
        stream: _firestoreService.getItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bulk Operations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedCount > 0 ? Colors.purple : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_selectedCount selected',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Update Qty'), icon: Icon(Icons.numbers)),
                          ButtonSegment(value: 1, label: Text('Update Price'), icon: Icon(Icons.attach_money)),
                          ButtonSegment(value: 2, label: Text('Delete'), icon: Icon(Icons.delete)),
                        ],
                        selected: {_selectedOperation},
                        onSelectionChanged: (Set<int> newSelection) {
                          setState(() => _selectedOperation = newSelection.first);
                        },
                      ),
                      const SizedBox(height: 16),

                      if (_selectedOperation == 0)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _quantityController,
                                decoration: const InputDecoration(
                                  labelText: 'New Quantity',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.numbers),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        )
                      else if (_selectedOperation == 1)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  labelText: 'New Price',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading || _selectedCount == 0 ? null : _performBulkOperation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedOperation == 2 ? Colors.red : Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : Text(
                                  _selectedOperation == 0 ? 'Update Quantities' :
                                  _selectedOperation == 1 ? 'Update Prices' : 'Delete Selected',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _selectAll(items, true),
                          child: const Text('Select All'),
                        ),
                        TextButton(
                          onPressed: () => _selectAll(items, false),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No Inventory Items', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            Text('Add items to use bulk operations'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected = _selectedItems[item.id!] ?? false;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            color: isSelected ? Colors.purple[50] : null,
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (selected) => _toggleItemSelection(item.id!, selected ?? false),
                              title: Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.purple[800] : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Category: ${item.category}'),
                                  Text('Stock: ${item.quantity} | Price: \$${item.price.toStringAsFixed(2)}'),
                                  if (item.isOutOfStock)
                                    const Text('OUT OF STOCK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                                  else if (item.isLowStock)
                                    const Text('LOW STOCK', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              secondary: CircleAvatar(
                                backgroundColor: item.isOutOfStock ? Colors.red : item.isLowStock ? Colors.orange : Colors.green,
                                child: Icon(
                                  item.isOutOfStock ? Icons.warning : item.isLowStock ? Icons.warning_amber : Icons.inventory_2,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}