import '../constants/app_strings.dart';

enum ExpenseCategory {
  rent,
  electricity,
  salary,
  transport,
  rawMaterial,
  maintenance,
  packaging,
  telephone,
  marketing,
  taxes,
  insurance,
  equipment,
  foodBeverage,
  miscellaneous,
  professionalFees,
  loan,
  custom,
}

extension ExpenseCategoryX on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.rent:
        return AppStrings.expenseCategoryRent;
      case ExpenseCategory.electricity:
        return AppStrings.expenseCategoryElectricity;
      case ExpenseCategory.salary:
        return AppStrings.expenseCategorySalary;
      case ExpenseCategory.transport:
        return AppStrings.expenseCategoryTransport;
      case ExpenseCategory.rawMaterial:
        return AppStrings.expenseCategoryRawMaterial;
      case ExpenseCategory.maintenance:
        return AppStrings.expenseCategoryMaintenance;
      case ExpenseCategory.packaging:
        return AppStrings.expenseCategoryPackaging;
      case ExpenseCategory.telephone:
        return AppStrings.expenseCategoryTelephone;
      case ExpenseCategory.marketing:
        return AppStrings.expenseCategoryMarketing;
      case ExpenseCategory.taxes:
        return AppStrings.expenseCategoryTaxes;
      case ExpenseCategory.insurance:
        return AppStrings.expenseCategoryInsurance;
      case ExpenseCategory.equipment:
        return AppStrings.expenseCategoryEquipment;
      case ExpenseCategory.foodBeverage:
        return AppStrings.expenseCategoryFoodBeverage;
      case ExpenseCategory.miscellaneous:
        return AppStrings.expenseCategoryMiscellaneous;
      case ExpenseCategory.professionalFees:
        return AppStrings.expenseCategoryProfessionalFees;
      case ExpenseCategory.loan:
        return AppStrings.expenseCategoryLoan;
      case ExpenseCategory.custom:
        return AppStrings.expenseCategoryCustom;
    }
  }

  String get iconKey {
    switch (this) {
      case ExpenseCategory.rent:
        return 'home';
      case ExpenseCategory.electricity:
        return 'bolt';
      case ExpenseCategory.salary:
        return 'person';
      case ExpenseCategory.transport:
        return 'local_shipping';
      case ExpenseCategory.rawMaterial:
        return 'inventory_2';
      case ExpenseCategory.maintenance:
        return 'build';
      case ExpenseCategory.packaging:
        return 'shopping_bag';
      case ExpenseCategory.telephone:
        return 'phone_android';
      case ExpenseCategory.marketing:
        return 'campaign';
      case ExpenseCategory.taxes:
        return 'account_balance';
      case ExpenseCategory.insurance:
        return 'verified_user';
      case ExpenseCategory.equipment:
        return 'devices';
      case ExpenseCategory.foodBeverage:
        return 'local_cafe';
      case ExpenseCategory.miscellaneous:
        return 'description';
      case ExpenseCategory.professionalFees:
        return 'assignment';
      case ExpenseCategory.loan:
        return 'payments';
      case ExpenseCategory.custom:
        return 'sell';
    }
  }
}

ExpenseCategory expenseCategoryFromString(String? value) {
  if (value == null) return ExpenseCategory.miscellaneous;
  for (final category in ExpenseCategory.values) {
    if (category.name == value) return category;
  }
  return ExpenseCategory.miscellaneous;
}
