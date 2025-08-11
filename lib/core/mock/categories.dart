import 'package:remalux_ar/core/types/categories.dart';

// Main categories
final List<Category> mockCategories = [
  Category(
    name: 'AI Помощь',
    iconPath: 'lib/core/assets/images/categories/ai.png',
    route: '/ai-help',
    onTap: () {},
  ),
  Category(
    name: 'Врачи',
    iconPath: 'lib/core/assets/images/categories/stetoscope2.png',
    route: '/doctors',
    onTap: () {},
  ),
  Category(
    name: 'Анализы',
    iconPath: 'lib/core/assets/images/categories/stetoscope.png',
    route: '/analyses',
    onTap: () {},
  ),
  Category(
    name: 'SOS',
    iconPath: 'lib/core/assets/images/categories/pharma.png',
    route: '/emergency',
    onTap: () {},
  ),
];

// Horizontal categories
final List<Category> horizontalCategories = [
  Category(
    name: 'Медработники',
    iconPath: 'lib/core/assets/images/categories/employees.png',
    route: '/medical-staff',
    onTap: () {},
  ),
  Category(
    name: 'Стоматологии',
    iconPath: 'lib/core/assets/images/categories/stom.png',
    route: '/dentists',
    onTap: () {},
  ),
  Category(
    name: 'SOS',
    iconPath: 'lib/core/assets/images/categories/bus.png',
    route: '/emergency',
    onTap: () {},
  ),
  Category(
    name: 'Мед. карта',
    iconPath: 'lib/core/assets/images/categories/card.png',
    route: '/medical-card',
    onTap: () {},
  ),
];

final List<SaleCategory> doctorsCategories = [
  SaleCategory(
    name: 'Общее здоровье',
    iconPath: 'lib/core/assets/images/doctors/categories/1.png',
    route: '/medical-staff',
    sale: true,
    saleValue: 20,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Ухо, горло, нос ',
    iconPath: 'lib/core/assets/images/doctors/categories/2.png',
    route: '/dentists',
    sale: false,
    saleValue: 20,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Живот, печень, пищеварение',
    iconPath: 'lib/core/assets/images/doctors/categories/3.png',
    route: '/emergency',
    sale: true,
    saleValue: 10,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Сердце и сосуды',
    iconPath: 'lib/core/assets/images/doctors/categories/4.png',
    route: '/medical-card',
    sale: true,
    saleValue: 5,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Женское и мужское здоровье',
    iconPath: 'lib/core/assets/images/doctors/categories/5.png',
    route: '/medical-card',
    sale: false,
    saleValue: 20,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Кожа и волосы',
    iconPath: 'lib/core/assets/images/doctors/categories/6.png',
    route: '/medical-card',
    sale: false,
    saleValue: 20,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Кости и суставы',
    iconPath: 'lib/core/assets/images/doctors/categories/7.png',
    route: '/medical-card',
    sale: true,
    saleValue: 15,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Хирурги и травматологи',
    iconPath: 'lib/core/assets/images/doctors/categories/8.png',
    route: '/medical-card',
    sale: true,
    saleValue: 25,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Зубы',
    iconPath: 'lib/core/assets/images/doctors/categories/9.png',
    route: '/medical-card',
    sale: true,
    saleValue: 10,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Зрение и слух',
    iconPath: 'lib/core/assets/images/doctors/categories/10.png',
    route: '/medical-card',
    sale: true,
    saleValue: 20,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Нервы и психика',
    iconPath: 'lib/core/assets/images/doctors/categories/11.png',
    route: '/medical-card',
    sale: true,
    saleValue: 20,
    onTap: () {},
  ),
];

final List<SaleCategory> analysesCategories = [
  SaleCategory(
    name: 'Анализы',
    iconPath: 'lib/core/assets/images/analyses/categories/1.png',
    route: '/analyses',
    sale: true,
    saleValue: 20,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Чекапы',
    iconPath: 'lib/core/assets/images/analyses/categories/2.png',
    route: '/analyses',
    sale: true,
    saleValue: 20,
    onTap: () {},
  ),
  SaleCategory(
    name: 'Скидки',
    iconPath: 'lib/core/assets/images/analyses/categories/3.png',
    route: '/analyses',
    sale: true,
    saleValue: 20,
    onTap: () {},
  ),
];
