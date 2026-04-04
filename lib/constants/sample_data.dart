import 'dart:math';

import '../models/bill.dart';
import '../models/business_config.dart';
import '../models/customer.dart';
import '../models/line_item.dart';
import '../models/payment_info.dart';
import '../models/product.dart';
import '../models/product_batch.dart';

class SampleBillingData {
  final List<Customer> customers;
  final List<Bill> bills;

  const SampleBillingData({required this.customers, required this.bills});
}

class SampleData {
  SampleData._();

  // ─── General / Grocery ────────────────────────────────────────────────────

  static List<Product> get products => _withGeneratedBarcodes([
    Product(
      name: 'Basmati Rice 1kg',
      sellingPrice: 85,
      costPrice: 62,
      stockQuantity: 50,
      category: 'Grains & Pulses',
      unit: 'kg',
      minQuantity: 0.5,
      quantityStep: 0.5,
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Toor Dal 1kg',
      sellingPrice: 140,
      costPrice: 108,
      stockQuantity: 35,
      category: 'Grains & Pulses',
      unit: 'kg',
      minQuantity: 0.25,
      quantityStep: 0.25,
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Wheat Flour 5kg',
      sellingPrice: 210,
      costPrice: 165,
      stockQuantity: 25,
      category: 'Grains & Pulses',
      unit: 'kg',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Sugar 1kg',
      sellingPrice: 45,
      costPrice: 36,
      stockQuantity: 40,
      category: 'Grains & Pulses',
      unit: 'kg',
      minQuantity: 0.5,
      quantityStep: 0.5,
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Moong Dal 1kg',
      sellingPrice: 120,
      costPrice: 92,
      stockQuantity: 30,
      category: 'Grains & Pulses',
      unit: 'kg',
      minQuantity: 0.25,
      quantityStep: 0.25,
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Amul Butter 500g',
      sellingPrice: 280,
      costPrice: 245,
      stockQuantity: 15,
      category: 'Dairy',
      unit: 'pcs',
      gstSlabPercent: 12,
    ),
    Product(
      name: 'Amul Milk 1L',
      sellingPrice: 65,
      costPrice: 58,
      stockQuantity: 20,
      category: 'Dairy',
      unit: 'ltr',
      gstSlabPercent: 0,
    ),
    Product(
      name: 'Paneer 200g',
      sellingPrice: 90,
      costPrice: 72,
      stockQuantity: 8,
      category: 'Dairy',
      unit: 'pcs',
      gstSlabPercent: 0,
      lowStockThreshold: 10,
    ),
    Product(
      name: 'Curd 400g',
      sellingPrice: 35,
      costPrice: 28,
      stockQuantity: 12,
      category: 'Dairy',
      unit: 'pcs',
      gstSlabPercent: 0,
    ),
    Product(
      name: 'Parle-G Biscuits',
      sellingPrice: 10,
      costPrice: 7,
      stockQuantity: 100,
      category: 'Snacks & Beverages',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Maggi Noodles',
      sellingPrice: 14,
      costPrice: 10,
      stockQuantity: 80,
      category: 'Snacks & Beverages',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Lays Chips',
      sellingPrice: 20,
      costPrice: 14,
      stockQuantity: 60,
      category: 'Snacks & Beverages',
      unit: 'pcs',
      gstSlabPercent: 12,
    ),
    Product(
      name: 'Tata Tea 250g',
      sellingPrice: 110,
      costPrice: 88,
      stockQuantity: 25,
      category: 'Snacks & Beverages',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Coca Cola 750ml',
      sellingPrice: 40,
      costPrice: 28,
      stockQuantity: 30,
      category: 'Snacks & Beverages',
      unit: 'pcs',
      gstSlabPercent: 28,
    ),
    Product(
      name: 'Nescafe Coffee 50g',
      sellingPrice: 160,
      costPrice: 128,
      stockQuantity: 18,
      category: 'Snacks & Beverages',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Cooking Oil 1L',
      sellingPrice: 180,
      costPrice: 148,
      stockQuantity: 22,
      category: 'Cooking Essentials',
      unit: 'ltr',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Tata Salt 1kg',
      sellingPrice: 28,
      costPrice: 21,
      stockQuantity: 45,
      category: 'Cooking Essentials',
      unit: 'pcs',
      gstSlabPercent: 0,
    ),
    Product(
      name: 'Red Chilli Powder 100g',
      sellingPrice: 45,
      costPrice: 32,
      stockQuantity: 30,
      category: 'Cooking Essentials',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Turmeric Powder 100g',
      sellingPrice: 35,
      costPrice: 25,
      stockQuantity: 28,
      category: 'Cooking Essentials',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Mustard Oil 500ml',
      sellingPrice: 95,
      costPrice: 76,
      stockQuantity: 0,
      category: 'Cooking Essentials',
      unit: 'ml',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Lux Soap',
      sellingPrice: 48,
      costPrice: 36,
      stockQuantity: 35,
      category: 'Personal Care',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Clinic Plus Shampoo',
      sellingPrice: 120,
      costPrice: 90,
      stockQuantity: 5,
      category: 'Personal Care',
      unit: 'pcs',
      gstSlabPercent: 18,
      lowStockThreshold: 10,
    ),
    Product(
      name: 'Colgate Toothpaste',
      sellingPrice: 55,
      costPrice: 42,
      stockQuantity: 40,
      category: 'Personal Care',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Surf Excel 1kg',
      sellingPrice: 135,
      costPrice: 105,
      stockQuantity: 3,
      category: 'Household',
      unit: 'pcs',
      gstSlabPercent: 18,
      lowStockThreshold: 10,
    ),
    Product(
      name: 'Vim Dishwash Bar',
      sellingPrice: 30,
      costPrice: 22,
      stockQuantity: 50,
      category: 'Household',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
  ], prefix: '890100');

  // ─── Pharmacy ─────────────────────────────────────────────────────────────

  static List<Product> get pharmacyProducts {
    final now = DateTime.now();

    const paracetamolId = 'pharma-paracetamol';
    const amoxicillinId = 'pharma-amoxicillin';
    const crocinId = 'pharma-crocin';
    const cetirizineId = 'pharma-cetirizine';
    const omeprazoleId = 'pharma-omeprazole';
    const azithromycinId = 'pharma-azithromycin';
    const metforminId = 'pharma-metformin';
    const pantoprazoleId = 'pharma-pantoprazole';

    return _withGeneratedBarcodes([
      Product(
        id: paracetamolId,
        name: 'Paracetamol 500mg',
        sellingPrice: 30,
        costPrice: 18,
        stockQuantity: 150,
        category: 'Tablets',
        unit: 'pcs',
        gstSlabPercent: 12,
        batches: [
          ProductBatch(
            productId: paracetamolId,
            batchNumber: 'BN-2025-001',
            expiryDate: now.add(const Duration(days: 60)),
            stockQuantity: 50,
          ),
          ProductBatch(
            productId: paracetamolId,
            batchNumber: 'BN-2025-002',
            expiryDate: now.add(const Duration(days: 365)),
            stockQuantity: 100,
          ),
        ],
      ),
      Product(
        id: amoxicillinId,
        name: 'Amoxicillin 250mg',
        sellingPrice: 85,
        costPrice: 52,
        stockQuantity: 80,
        category: 'Tablets',
        unit: 'pcs',
        gstSlabPercent: 12,
        batches: [
          ProductBatch(
            productId: amoxicillinId,
            batchNumber: 'BN-2025-010',
            expiryDate: now.add(const Duration(days: 30)),
            stockQuantity: 30,
          ),
          ProductBatch(
            productId: amoxicillinId,
            batchNumber: 'BN-2025-011',
            expiryDate: now.add(const Duration(days: 540)),
            stockQuantity: 50,
          ),
        ],
      ),
      Product(
        id: crocinId,
        name: 'Crocin Advance',
        sellingPrice: 25,
        costPrice: 15,
        stockQuantity: 200,
        category: 'Tablets',
        unit: 'pcs',
        gstSlabPercent: 12,
        batches: [
          ProductBatch(
            productId: crocinId,
            batchNumber: 'BN-2025-020',
            expiryDate: now.add(const Duration(days: 180)),
            stockQuantity: 120,
          ),
          ProductBatch(
            productId: crocinId,
            batchNumber: 'BN-2025-021',
            expiryDate: now.add(const Duration(days: 730)),
            stockQuantity: 80,
          ),
        ],
      ),
      Product(
        id: cetirizineId,
        name: 'Cetirizine 10mg',
        sellingPrice: 35,
        costPrice: 22,
        stockQuantity: 100,
        category: 'Tablets',
        unit: 'pcs',
        gstSlabPercent: 12,
        batches: [
          ProductBatch(
            productId: cetirizineId,
            batchNumber: 'BN-2025-030',
            expiryDate: now.add(const Duration(days: 45)),
            stockQuantity: 40,
          ),
          ProductBatch(
            productId: cetirizineId,
            batchNumber: 'BN-2025-031',
            expiryDate: now.add(const Duration(days: 400)),
            stockQuantity: 60,
          ),
        ],
      ),
      Product(
        id: omeprazoleId,
        name: 'Omeprazole 20mg',
        sellingPrice: 65,
        costPrice: 40,
        stockQuantity: 90,
        category: 'Capsules',
        unit: 'pcs',
        gstSlabPercent: 12,
        batches: [
          ProductBatch(
            productId: omeprazoleId,
            batchNumber: 'BN-2025-040',
            expiryDate: now.add(const Duration(days: 120)),
            stockQuantity: 40,
          ),
          ProductBatch(
            productId: omeprazoleId,
            batchNumber: 'BN-2025-041',
            expiryDate: now.add(const Duration(days: 600)),
            stockQuantity: 50,
          ),
        ],
      ),
      Product(
        id: azithromycinId,
        name: 'Azithromycin 500mg',
        sellingPrice: 120,
        costPrice: 74,
        stockQuantity: 60,
        category: 'Tablets',
        unit: 'pcs',
        gstSlabPercent: 12,
        batches: [
          ProductBatch(
            productId: azithromycinId,
            batchNumber: 'BN-2025-050',
            expiryDate: now.add(const Duration(days: 75)),
            stockQuantity: 20,
          ),
          ProductBatch(
            productId: azithromycinId,
            batchNumber: 'BN-2025-051',
            expiryDate: now.add(const Duration(days: 500)),
            stockQuantity: 40,
          ),
        ],
      ),
      Product(
        id: metforminId,
        name: 'Metformin 500mg',
        sellingPrice: 45,
        costPrice: 28,
        stockQuantity: 180,
        category: 'Tablets',
        unit: 'pcs',
        gstSlabPercent: 12,
        batches: [
          ProductBatch(
            productId: metforminId,
            batchNumber: 'BN-2025-060',
            expiryDate: now.add(const Duration(days: 200)),
            stockQuantity: 80,
          ),
          ProductBatch(
            productId: metforminId,
            batchNumber: 'BN-2025-061',
            expiryDate: now.add(const Duration(days: 700)),
            stockQuantity: 100,
          ),
        ],
      ),
      Product(
        id: pantoprazoleId,
        name: 'Pantoprazole 40mg',
        sellingPrice: 55,
        costPrice: 34,
        stockQuantity: 70,
        category: 'Tablets',
        unit: 'pcs',
        gstSlabPercent: 12,
        batches: [
          ProductBatch(
            productId: pantoprazoleId,
            batchNumber: 'BN-2025-070',
            expiryDate: now.add(const Duration(days: 15)),
            stockQuantity: 20,
          ),
          ProductBatch(
            productId: pantoprazoleId,
            batchNumber: 'BN-2025-071',
            expiryDate: now.add(const Duration(days: 450)),
            stockQuantity: 50,
          ),
        ],
      ),
    ], prefix: '890200');
  }

  // ─── Clinic ───────────────────────────────────────────────────────────────

  static List<Product> get clinicProducts => _withGeneratedBarcodes([
    Product(
      name: 'General Consultation',
      sellingPrice: 500,
      costPrice: 80,
      category: 'Consultation',
      isService: true,
      durationMinutes: 15,
    ),
    Product(
      name: 'Follow-up Visit',
      sellingPrice: 300,
      costPrice: 50,
      category: 'Consultation',
      isService: true,
      durationMinutes: 10,
    ),
    Product(
      name: 'Blood Test',
      sellingPrice: 400,
      costPrice: 120,
      category: 'Lab',
      isService: true,
      durationMinutes: 15,
    ),
    Product(
      name: 'X-Ray',
      sellingPrice: 800,
      costPrice: 200,
      category: 'Imaging',
      isService: true,
      durationMinutes: 20,
    ),
    Product(
      name: 'Wound Dressing',
      sellingPrice: 200,
      costPrice: 60,
      category: 'Procedure',
      isService: true,
      durationMinutes: 15,
    ),
    Product(
      name: 'Injection/IV',
      sellingPrice: 150,
      costPrice: 40,
      category: 'Procedure',
      isService: true,
      durationMinutes: 10,
    ),
    Product(
      name: 'ECG',
      sellingPrice: 600,
      costPrice: 150,
      category: 'Diagnostic',
      isService: true,
      durationMinutes: 20,
    ),
    Product(
      name: 'Physiotherapy',
      sellingPrice: 500,
      costPrice: 100,
      category: 'Therapy',
      isService: true,
      durationMinutes: 30,
    ),
    Product(
      name: 'ORS Sachets',
      sellingPrice: 25,
      costPrice: 15,
      stockQuantity: 50,
      category: 'Supplies',
      unit: 'pcs',
    ),
    Product(
      name: 'Bandage Roll',
      sellingPrice: 40,
      costPrice: 22,
      stockQuantity: 30,
      category: 'Supplies',
      unit: 'pcs',
    ),
  ], prefix: '890300');

  // ─── Salon ────────────────────────────────────────────────────────────────

  static List<Product> get salonProducts => _withGeneratedBarcodes([
    Product(
      name: 'Haircut (Men\'s)',
      sellingPrice: 200,
      costPrice: 30,
      category: 'Hair',
      isService: true,
      durationMinutes: 30,
    ),
    Product(
      name: 'Haircut (Women\'s)',
      sellingPrice: 400,
      costPrice: 50,
      category: 'Hair',
      isService: true,
      durationMinutes: 45,
    ),
    Product(
      name: 'Hair Coloring',
      sellingPrice: 1500,
      costPrice: 480,
      category: 'Hair',
      isService: true,
      durationMinutes: 90,
    ),
    Product(
      name: 'Facial',
      sellingPrice: 800,
      costPrice: 200,
      category: 'Skin Care',
      isService: true,
      durationMinutes: 60,
    ),
    Product(
      name: 'Head Massage',
      sellingPrice: 300,
      costPrice: 40,
      category: 'Massage',
      isService: true,
      durationMinutes: 30,
    ),
    Product(
      name: 'Manicure',
      sellingPrice: 500,
      costPrice: 80,
      category: 'Nails',
      isService: true,
      durationMinutes: 45,
    ),
    Product(
      name: 'Pedicure',
      sellingPrice: 600,
      costPrice: 90,
      category: 'Nails',
      isService: true,
      durationMinutes: 45,
    ),
    Product(
      name: 'Hair Spa',
      sellingPrice: 1200,
      costPrice: 350,
      category: 'Hair',
      isService: true,
      durationMinutes: 60,
    ),
    Product(
      name: 'Threading',
      sellingPrice: 50,
      costPrice: 8,
      category: 'Skin Care',
      isService: true,
      durationMinutes: 10,
    ),
    Product(
      name: 'Shaving',
      sellingPrice: 100,
      costPrice: 15,
      category: 'Hair',
      isService: true,
      durationMinutes: 15,
    ),
    Product(
      name: 'Shampoo 200ml',
      sellingPrice: 350,
      costPrice: 230,
      stockQuantity: 15,
      category: 'Products',
      unit: 'pcs',
    ),
    Product(
      name: 'Hair Oil 100ml',
      sellingPrice: 250,
      costPrice: 160,
      stockQuantity: 20,
      category: 'Products',
      unit: 'pcs',
    ),
  ], prefix: '890400');

  // ─── Jewellery ────────────────────────────────────────────────────────────

  static List<Product> get jewelleryProducts => _withGeneratedBarcodes([
    Product(
      name: 'Gold Ring 22KT (5g)',
      sellingPrice: 29500,
      costPrice: 28200,
      stockQuantity: 10,
      category: 'Gold',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Gold Chain 22KT (10g)',
      sellingPrice: 59000,
      costPrice: 56400,
      stockQuantity: 8,
      category: 'Gold',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Gold Necklace 22KT (20g)',
      sellingPrice: 118000,
      costPrice: 112800,
      stockQuantity: 5,
      category: 'Gold',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Gold Bangle 22KT (15g)',
      sellingPrice: 88500,
      costPrice: 84600,
      stockQuantity: 6,
      category: 'Gold',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Gold Earrings 22KT (4g)',
      sellingPrice: 23600,
      costPrice: 22560,
      stockQuantity: 12,
      category: 'Gold',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Gold Pendant 22KT (3g)',
      sellingPrice: 17700,
      costPrice: 16920,
      stockQuantity: 15,
      category: 'Gold',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Silver Ring (8g)',
      sellingPrice: 720,
      costPrice: 580,
      stockQuantity: 25,
      category: 'Silver',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Silver Anklet (20g)',
      sellingPrice: 1800,
      costPrice: 1440,
      stockQuantity: 20,
      category: 'Silver',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Silver Chain (15g)',
      sellingPrice: 1350,
      costPrice: 1080,
      stockQuantity: 18,
      category: 'Silver',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Silver Bracelet (12g)',
      sellingPrice: 1080,
      costPrice: 864,
      stockQuantity: 22,
      category: 'Silver',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Diamond Ring (0.25ct)',
      sellingPrice: 35000,
      costPrice: 28000,
      stockQuantity: 4,
      category: 'Diamond',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Diamond Pendant (0.15ct)',
      sellingPrice: 22000,
      costPrice: 17600,
      stockQuantity: 6,
      category: 'Diamond',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Diamond Earrings (0.20ct)',
      sellingPrice: 28000,
      costPrice: 22400,
      stockQuantity: 5,
      category: 'Diamond',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Platinum Ring (5g)',
      sellingPrice: 21500,
      costPrice: 18900,
      stockQuantity: 3,
      category: 'Platinum',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Ruby Gemstone Pendant',
      sellingPrice: 8500,
      costPrice: 5500,
      stockQuantity: 8,
      category: 'Gemstones',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Jhumka Earrings (Fashion)',
      sellingPrice: 1200,
      costPrice: 580,
      stockQuantity: 30,
      category: 'Fashion Jewellery',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Pearl Necklace Set',
      sellingPrice: 2500,
      costPrice: 1200,
      stockQuantity: 15,
      category: 'Fashion Jewellery',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
    Product(
      name: 'Kundan Choker Set',
      sellingPrice: 3800,
      costPrice: 1900,
      stockQuantity: 10,
      category: 'Fashion Jewellery',
      unit: 'pcs',
      gstSlabPercent: 3,
      hsnCode: '7113',
    ),
  ], prefix: '890500');

  // ─── Restaurant ───────────────────────────────────────────────────────────
  // F&B cost ratio ~30–35% (industry standard)

  static List<Product> get restaurantProducts => _withGeneratedBarcodes([
    // Starters
    Product(
      name: 'Paneer Tikka',
      sellingPrice: 220,
      costPrice: 72,
      stockQuantity: 999,
      category: 'Starters',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Chicken Tandoori (Half)',
      sellingPrice: 280,
      costPrice: 105,
      stockQuantity: 999,
      category: 'Starters',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Veg Spring Rolls',
      sellingPrice: 140,
      costPrice: 45,
      stockQuantity: 999,
      category: 'Starters',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Samosa (2 pcs)',
      sellingPrice: 60,
      costPrice: 18,
      stockQuantity: 999,
      category: 'Starters',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'French Fries',
      sellingPrice: 90,
      costPrice: 28,
      stockQuantity: 999,
      category: 'Starters',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Garlic Bread',
      sellingPrice: 120,
      costPrice: 38,
      stockQuantity: 999,
      category: 'Starters',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    // Main Course
    Product(
      name: 'Dal Makhani',
      sellingPrice: 180,
      costPrice: 55,
      stockQuantity: 999,
      category: 'Main Course',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Paneer Butter Masala',
      sellingPrice: 220,
      costPrice: 78,
      stockQuantity: 999,
      category: 'Main Course',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Chicken Curry',
      sellingPrice: 260,
      costPrice: 105,
      stockQuantity: 999,
      category: 'Main Course',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Veg Fried Rice',
      sellingPrice: 160,
      costPrice: 48,
      stockQuantity: 999,
      category: 'Rice & Biryani',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Chicken Biryani',
      sellingPrice: 280,
      costPrice: 110,
      stockQuantity: 999,
      category: 'Rice & Biryani',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Veg Biryani',
      sellingPrice: 200,
      costPrice: 65,
      stockQuantity: 999,
      category: 'Rice & Biryani',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    // Breads
    Product(
      name: 'Butter Naan',
      sellingPrice: 40,
      costPrice: 12,
      stockQuantity: 999,
      category: 'Breads',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Tandoori Roti',
      sellingPrice: 25,
      costPrice: 8,
      stockQuantity: 999,
      category: 'Breads',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Paratha',
      sellingPrice: 55,
      costPrice: 18,
      stockQuantity: 999,
      category: 'Breads',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    // Beverages
    Product(
      name: 'Mango Lassi',
      sellingPrice: 80,
      costPrice: 25,
      stockQuantity: 999,
      category: 'Beverages',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Masala Chai',
      sellingPrice: 40,
      costPrice: 10,
      stockQuantity: 999,
      category: 'Beverages',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Fresh Lime Soda',
      sellingPrice: 60,
      costPrice: 15,
      stockQuantity: 999,
      category: 'Beverages',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Cold Coffee',
      sellingPrice: 120,
      costPrice: 38,
      stockQuantity: 999,
      category: 'Beverages',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    // Desserts
    Product(
      name: 'Gulab Jamun (2 pcs)',
      sellingPrice: 80,
      costPrice: 22,
      stockQuantity: 999,
      category: 'Desserts',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Ice Cream (2 scoops)',
      sellingPrice: 100,
      costPrice: 35,
      stockQuantity: 999,
      category: 'Desserts',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
    Product(
      name: 'Rasgulla (2 pcs)',
      sellingPrice: 60,
      costPrice: 18,
      stockQuantity: 999,
      category: 'Desserts',
      unit: 'pcs',
      gstSlabPercent: 5,
    ),
  ], prefix: '890600');

  // ─── Workshop / Bike Service ──────────────────────────────────────────────
  // Parts ~35% margin; Labour ~80% margin

  static List<Product> get workshopProducts => _withGeneratedBarcodes([
    // Parts
    Product(
      name: 'Engine Oil (1L)',
      sellingPrice: 420,
      costPrice: 280,
      stockQuantity: 30,
      category: 'Parts',
      unit: 'ltr',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Air Filter',
      sellingPrice: 180,
      costPrice: 110,
      stockQuantity: 20,
      category: 'Parts',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Brake Pads (Set)',
      sellingPrice: 650,
      costPrice: 400,
      stockQuantity: 15,
      category: 'Parts',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Spark Plug',
      sellingPrice: 220,
      costPrice: 130,
      stockQuantity: 25,
      category: 'Parts',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Chain Set',
      sellingPrice: 850,
      costPrice: 540,
      stockQuantity: 10,
      category: 'Parts',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Clutch Cable',
      sellingPrice: 180,
      costPrice: 105,
      stockQuantity: 18,
      category: 'Parts',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Accelerator Cable',
      sellingPrice: 160,
      costPrice: 92,
      stockQuantity: 18,
      category: 'Parts',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Tyre (Front)',
      sellingPrice: 1800,
      costPrice: 1260,
      stockQuantity: 8,
      category: 'Parts',
      unit: 'pcs',
      gstSlabPercent: 28,
    ),
    Product(
      name: 'Tyre (Rear)',
      sellingPrice: 2200,
      costPrice: 1540,
      stockQuantity: 8,
      category: 'Parts',
      unit: 'pcs',
      gstSlabPercent: 28,
    ),
    Product(
      name: 'Battery (12V)',
      sellingPrice: 1500,
      costPrice: 980,
      stockQuantity: 6,
      category: 'Parts',
      unit: 'pcs',
      gstSlabPercent: 28,
    ),
    Product(
      name: 'Coolant (500ml)',
      sellingPrice: 280,
      costPrice: 175,
      stockQuantity: 12,
      category: 'Parts',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    Product(
      name: 'Brake Fluid (500ml)',
      sellingPrice: 240,
      costPrice: 150,
      stockQuantity: 12,
      category: 'Parts',
      unit: 'pcs',
      gstSlabPercent: 18,
    ),
    // Labour
    Product(
      name: 'Oil Change Service',
      sellingPrice: 200,
      costPrice: 40,
      category: 'Labour',
      isService: true,
      durationMinutes: 30,
    ),
    Product(
      name: 'Tyre Rotation',
      sellingPrice: 150,
      costPrice: 30,
      category: 'Labour',
      isService: true,
      durationMinutes: 20,
    ),
    Product(
      name: 'Brake Inspection & Service',
      sellingPrice: 350,
      costPrice: 70,
      category: 'Labour',
      isService: true,
      durationMinutes: 45,
    ),
    Product(
      name: 'Full Service',
      sellingPrice: 800,
      costPrice: 160,
      category: 'Labour',
      isService: true,
      durationMinutes: 120,
    ),
    Product(
      name: 'Carburettor Cleaning',
      sellingPrice: 400,
      costPrice: 80,
      category: 'Labour',
      isService: true,
      durationMinutes: 60,
    ),
    Product(
      name: 'Chain Lubrication & Adjustment',
      sellingPrice: 120,
      costPrice: 25,
      category: 'Labour',
      isService: true,
      durationMinutes: 20,
    ),
    Product(
      name: 'Electrical Fault Diagnosis',
      sellingPrice: 300,
      costPrice: 60,
      category: 'Labour',
      isService: true,
      durationMinutes: 45,
    ),
    Product(
      name: 'Puncture Repair',
      sellingPrice: 100,
      costPrice: 20,
      category: 'Labour',
      isService: true,
      durationMinutes: 20,
    ),
  ], prefix: '890700');

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static List<Product> _withGeneratedBarcodes(
    List<Product> products, {
    required String prefix,
  }) {
    return products
        .asMap()
        .entries
        .map((entry) {
          final product = entry.value;
          if (product.barcode != null && product.barcode!.isNotEmpty) {
            return product;
          }
          final number = (entry.key + 1).toString().padLeft(6, '0');
          return product.copyWith(barcode: '$prefix$number');
        })
        .toList(growable: false);
  }

  // ─── Billing history ──────────────────────────────────────────────────────

  static SampleBillingData generateBillingHistory({
    required List<Product> products,
    required BusinessType businessType,
    int customerCount = 50,
    int invoiceCount = 100,
  }) {
    final safeCustomerCount = customerCount <= 0 ? 1 : customerCount;
    final safeInvoiceCount = invoiceCount <= 0 ? 1 : invoiceCount;

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - 2, 1);
    final daysSpan = max(1, now.difference(startDate).inDays);
    final random = Random(42);

    final effectiveProducts = products.isEmpty
        ? [
            Product(
              id: 'sample-fallback-product',
              name: 'Sample Item',
              sellingPrice: 100,
              costPrice: 65,
              stockQuantity: 500,
            ),
          ]
        : products;

    final customers = List<Customer>.generate(safeCustomerCount, (index) {
      final number = index + 1;
      final suffix = (100000000 + index).toString().padLeft(9, '0');
      return Customer(
        id: 'sample-customer-${number.toString().padLeft(3, '0')}',
        name: 'Sample Customer $number',
        phone: '9$suffix',
        outstandingBalance: 0,
        createdAt: startDate.add(Duration(days: index % daysSpan)),
      );
    });

    final bills = <Bill>[];
    for (var index = 0; index < safeInvoiceCount; index++) {
      final customer = customers[index % customers.length];
      final lineItems = _generateLineItems(
        products: effectiveProducts,
        random: random,
        businessType: businessType,
      );
      final subtotal = lineItems.fold<double>(
        0,
        (sum, item) => sum + item.subtotal,
      );
      final discount = index % 5 == 0 ? subtotal * 0.05 : 0.0;
      final discountRatio = subtotal <= 0
          ? 1.0
          : ((subtotal - discount) / subtotal).clamp(0.0, 1.0);
      final totalCgst = lineItems.fold<double>(
        0,
        (sum, item) => sum + item.cgstAmount,
      );
      final totalSgst = lineItems.fold<double>(
        0,
        (sum, item) => sum + item.sgstAmount,
      );
      final cgst = totalCgst * discountRatio;
      final sgst = totalSgst * discountRatio;
      final grandTotal = (subtotal - discount + cgst + sgst).clamp(
        0.0,
        double.infinity,
      );

      final isCreditBill = index % 4 == 0;
      final amountReceived = isCreditBill
          ? (index % 8 == 0 ? grandTotal * 0.5 : 0.0)
          : grandTotal;
      final creditAmount = isCreditBill
          ? (grandTotal - amountReceived).clamp(0.0, grandTotal)
          : 0.0;
      if (creditAmount > 0) {
        final customerIdx = index % customers.length;
        customers[customerIdx] = customers[customerIdx].copyWith(
          outstandingBalance: customers[customerIdx].outstandingBalance + creditAmount,
        );
      }

      final billDate = _buildTimestamp(
        base: startDate,
        now: now,
        random: random,
        index: index,
        daysSpan: daysSpan,
      );

      bills.add(
        Bill(
          id: 'sample-bill-${(index + 1).toString().padLeft(3, '0')}',
          billNumber:
              '${_financialYearFor(billDate)}/INV-${(index + 1).toString().padLeft(3, '0')}',
          lineItems: lineItems,
          subtotal: subtotal,
          discount: discount,
          cgst: cgst,
          sgst: sgst,
          grandTotal: grandTotal,
          paymentMode: isCreditBill ? PaymentMode.credit : PaymentMode.cash,
          amountReceived: amountReceived,
          creditAmount: creditAmount,
          customer: customer,
          timestamp: billDate,
          diagnosis: businessType == BusinessType.clinic
              ? _clinicDiagnoses[index % _clinicDiagnoses.length]
              : null,
          visitNotes: businessType == BusinessType.clinic && index % 3 == 0
              ? 'Follow-up in 3 days'
              : null,
        ),
      );
    }

    bills.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return SampleBillingData(customers: customers, bills: bills);
  }

  static List<LineItem> _generateLineItems({
    required List<Product> products,
    required Random random,
    required BusinessType businessType,
  }) {
    final itemCount = 1 + random.nextInt(3);
    final items = <LineItem>[];

    for (var index = 0; index < itemCount; index++) {
      final product = products[random.nextInt(products.length)];
      final quantity =
          product.isService ? 1.0 : (1 + random.nextInt(3)).toDouble();
      final batch = businessType == BusinessType.pharmacy
          ? product.nearestExpiryBatch
          : null;
      items.add(LineItem(product: product, quantity: quantity, batch: batch));
    }

    return items;
  }

  static DateTime _buildTimestamp({
    required DateTime base,
    required DateTime now,
    required Random random,
    required int index,
    required int daysSpan,
  }) {
    final dayOffset = random.nextInt(daysSpan + 1);
    final minuteOffset = (8 * 60) + random.nextInt(12 * 60);
    final value = DateTime(
      base.year,
      base.month,
      base.day,
    ).add(Duration(days: dayOffset, minutes: minuteOffset));
    if (value.isAfter(now)) {
      return now.subtract(Duration(minutes: index % 60));
    }
    return value;
  }

  static String _financialYearFor(DateTime date) {
    final startYear = date.month >= 4 ? date.year : date.year - 1;
    final endYear = (startYear + 1) % 100;
    return '$startYear-${endYear.toString().padLeft(2, '0')}';
  }

  static const List<String> _clinicDiagnoses = [
    'Viral fever',
    'Routine checkup',
    'Allergic rhinitis',
    'Back pain',
    'Gastritis',
  ];
}
