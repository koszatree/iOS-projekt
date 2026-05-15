/*import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/city.dart';

List<City> filterCities(List<City> cities, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return [];
  return cities.where((c) => c.name.toLowerCase().contains(q)).toList();
}

void main() {
  test('filterCities zwraca pasujące miasta', () {
    final cities = [
      City(name: 'Warszawa'),
      City(name: 'Gdańsk'),
      City(name: 'Kraków'),
    ];

    final result = filterCities(cities, 'da');

    expect(result.length, 1);
    expect(result.first.name, 'Gdańsk');
  });
}*/
