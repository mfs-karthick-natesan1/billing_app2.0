import 'package:flutter/material.dart';

class ExpenseIconService {
  ExpenseIconService._();

  static IconData iconForKey(String key) {
    switch (key) {
      case 'home':
        return Icons.home;
      case 'bolt':
        return Icons.bolt;
      case 'person':
        return Icons.person;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'build':
        return Icons.build;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'phone_android':
        return Icons.phone_android;
      case 'campaign':
        return Icons.campaign;
      case 'account_balance':
        return Icons.account_balance;
      case 'verified_user':
        return Icons.verified_user;
      case 'devices':
        return Icons.devices;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'description':
        return Icons.description;
      case 'assignment':
        return Icons.assignment;
      case 'payments':
        return Icons.payments;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'store':
        return Icons.storefront;
      case 'medical':
        return Icons.medical_services;
      case 'sell':
      default:
        return Icons.sell;
    }
  }
}
