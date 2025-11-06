import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';

class FirestoreService {
  final CollectionReference _itemsCollection =
      FirebaseFirestore.instance.collection('items');

  // Create new item
  Future<void> addItem(Item item) async {
    try {
      await _itemsCollection.add(item.toMap());
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  // Get real-time stream of all items
  Stream<List<Item>> getItemsStream() {
    return _itemsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Item.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Update existing item
  Future<void> updateItem(Item item) async {
    try {
      await _itemsCollection.doc(item.id!).update(item.toMap());
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    try {
      await _itemsCollection.doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // Search items by name
  Stream<List<Item>> searchItems(String query) {
    return _itemsCollection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Item.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get all categories
  Stream<List<String>> getCategories() {
    return _itemsCollection.snapshots().map((snapshot) {
      final categories = snapshot.docs
          .map((doc) => doc['category'] as String)
          .toSet()
          .toList();
      categories.sort();
      return categories;
    });
  }

  // Get low stock items
  Stream<List<Item>> getLowStockItems() {
    return _itemsCollection
        .where('quantity', isLessThan: 10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Item.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get out of stock items
  Stream<List<Item>> getOutOfStockItems() {
    return _itemsCollection
        .where('quantity', isEqualTo: 0)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Item.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Bulk operations - Delete multiple items
  Future<void> deleteMultipleItems(List<String> itemIds) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final itemId in itemIds) {
        batch.delete(_itemsCollection.doc(itemId));
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete multiple items: $e');
    }
  }

  // Bulk operations - Update quantity for multiple items
  Future<void> updateMultipleItemsQuantity(List<String> itemIds, int newQuantity) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final itemId in itemIds) {
        batch.update(_itemsCollection.doc(itemId), {'quantity': newQuantity});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update multiple items: $e');
    }
  }

  // Add sample data for testing
  Future<void> addSampleData() async {
    final sampleItems = [
      Item(
        name: "Laptop",
        quantity: 8,
        price: 999.99,
        category: "Electronics",
        createdAt: DateTime.now(),
      ),
      Item(
        name: "Smartphone", 
        quantity: 15,
        price: 699.99,
        category: "Electronics",
        createdAt: DateTime.now(),
      ),
      Item(
        name: "Headphones",
        quantity: 25, 
        price: 149.99,
        category: "Electronics",
        createdAt: DateTime.now(),
      ),
      Item(
        name: "Tablet",
        quantity: 3,
        price: 449.99,
        category: "Electronics",
        createdAt: DateTime.now(),
      ),
      Item(
        name: "T-Shirt",
        quantity: 50,
        price: 19.99,
        category: "Clothing",
        createdAt: DateTime.now(),
      ),
      Item(
        name: "Jeans",
        quantity: 30,
        price: 49.99,
        category: "Clothing",
        createdAt: DateTime.now(),
      ),
      Item(
        name: "Jacket", 
        quantity: 2,
        price: 89.99,
        category: "Clothing",
        createdAt: DateTime.now(),
      ),
      Item(
        name: "Apples",
        quantity: 100,
        price: 0.99,
        category: "Food",
        createdAt: DateTime.now(),
      ),
      Item(
        name: "Soda",
        quantity: 0,
        price: 1.99,
        category: "Food", 
        createdAt: DateTime.now(),
      ),
      Item(
        name: "Chocolate",
        quantity: 5,
        price: 2.49,
        category: "Food",
        createdAt: DateTime.now(),
      ),
      Item(
        name: "Novel",
        quantity: 20,
        price: 12.99,
        category: "Books",
        createdAt: DateTime.now(),
      ),
      Item(
        name: "Textbook",
        quantity: 7,
        price: 89.99,
        category: "Books",
        createdAt: DateTime.now(),
      ),
    ];

    // Add all sample items to Firestore
    for (final item in sampleItems) {
      await addItem(item);
    }
  }
}