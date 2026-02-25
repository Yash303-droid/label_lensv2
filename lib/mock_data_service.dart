final mockScanResult = {
  'productName': 'Hazelnut Wafer Cookies',
  'overallStatus': 'danger',
  'summary': 'Non-Vegan • Contains Allergens',
  'dietaryTags': [
    {'label': 'Vegetarian', 'color': 'emerald'},
    {'label': 'Contains Dairy', 'color': 'rose'},
    {'label': 'Contains Nuts', 'color': 'rose'},
    {'label': 'High Sugar', 'color': 'amber'}
  ],
  'ingredients': [
    {'name': 'Wheat Flour', 'status': 'safe', 'description': 'Standard baking flour.', 'isVegan': true},
    {'name': 'Sugar', 'status': 'warning', 'description': 'High glycemic index. Flagged.', 'isVegan': true},
    {'name': 'Whey Powder', 'status': 'danger', 'description': 'Derived from milk. Not vegan.', 'isVegan': false},
    {'name': 'Hazelnuts', 'status': 'danger', 'description': 'Tree nut allergen.', 'isVegan': true},
    {'name': 'Soy Lecithin', 'status': 'safe', 'description': 'Emulsifier. Derived from soy.', 'isVegan': true}
  ]
};

final fullMockHistory = [
  {'id': 1, 'name': 'Organic Oat Milk', 'status': 'safe', 'date': 'Today, 10:30 AM'},
  {'id': 2, 'name': 'Hazelnut Wafer Cookies', 'status': 'danger', 'date': 'Yesterday'},
  {'id': 3, 'name': 'Protein Energy Bar', 'status': 'warning', 'date': 'Feb 20'},
  {'id': 4, 'name': 'Almond Flour Tortillas', 'status': 'safe', 'date': 'Feb 19'},
  {'id': 5, 'name': 'Spicy Kimchi', 'status': 'safe', 'date': 'Feb 18'},
  {'id': 6, 'name': 'Greek Yogurt', 'status': 'danger', 'date': 'Feb 17'},
];

final recentMockHistory = fullMockHistory.take(3).toList();

final mockSavedItems = [
  {'id': 1, 'name': 'Organic Oat Milk', 'status': 'safe'},
  {'id': 3, 'name': 'Protein Energy Bar', 'status': 'warning'},
  {'id': 4, 'name': 'Almond Flour Tortillas', 'status': 'safe'},
];