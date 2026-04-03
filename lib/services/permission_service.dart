import '../models/user_role.dart';

enum Permission {
  createBill,
  viewBills,
  voidBill,
  viewProducts,
  addProduct,
  editProduct,
  deleteProduct,
  adjustStock,
  viewCustomers,
  addCustomer,
  editCustomer,
  deleteCustomer,
  recordPayment,
  viewExpenses,
  addExpense,
  editExpense,
  deleteExpense,
  viewCashBook,
  editCashBook,
  closeDay,
  viewReports,
  exportData,
  manageUsers,
  editSettings,
  editInvoiceSettings,
  setupPrinter,
  shareBill,
}

enum AppSection {
  billing,
  products,
  customers,
  expenses,
  cashBook,
  reports,
  settings,
  userManagement,
}

class PermissionService {
  PermissionService._();

  static bool canPerform(UserRole role, Permission action) {
    return _permissionsByRole[role]?.contains(action) ?? false;
  }

  static bool hasAccessTo(UserRole role, AppSection section) {
    final sectionPermissions =
        _sectionAccessMap[section] ?? const <Permission>[];
    return sectionPermissions.any((permission) => canPerform(role, permission));
  }

  static List<Permission> getPermissions(UserRole role) {
    return List<Permission>.unmodifiable(
      _permissionsByRole[role] ?? const <Permission>{},
    );
  }

  static const Map<AppSection, List<Permission>> _sectionAccessMap = {
    AppSection.billing: [Permission.viewBills],
    AppSection.products: [Permission.viewProducts],
    AppSection.customers: [Permission.viewCustomers],
    AppSection.expenses: [Permission.viewExpenses],
    AppSection.cashBook: [Permission.viewCashBook],
    AppSection.reports: [Permission.viewReports],
    AppSection.settings: [Permission.setupPrinter, Permission.editSettings],
    AppSection.userManagement: [Permission.manageUsers],
  };

  static final Map<UserRole, Set<Permission>> _permissionsByRole = {
    UserRole.owner: Set<Permission>.from(Permission.values),
    UserRole.manager: {
      Permission.createBill,
      Permission.viewBills,
      Permission.voidBill,
      Permission.viewProducts,
      Permission.addProduct,
      Permission.editProduct,
      Permission.adjustStock,
      Permission.viewCustomers,
      Permission.addCustomer,
      Permission.editCustomer,
      Permission.deleteCustomer,
      Permission.recordPayment,
      Permission.viewExpenses,
      Permission.addExpense,
      Permission.editExpense,
      Permission.viewCashBook,
      Permission.editCashBook,
      Permission.viewReports,
      Permission.exportData,
      Permission.setupPrinter,
      Permission.shareBill,
    },
    UserRole.billing: {
      Permission.createBill,
      Permission.viewBills,
      Permission.viewProducts,
      Permission.viewCustomers,
      Permission.addCustomer,
      Permission.recordPayment,
      Permission.setupPrinter,
      Permission.shareBill,
    },
    UserRole.viewer: {
      Permission.viewBills,
      Permission.viewProducts,
      Permission.viewCustomers,
      Permission.viewExpenses,
      Permission.viewCashBook,
      Permission.viewReports,
    },
  };
}
