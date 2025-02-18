class Food {
  final int id;
  final String name;
  final int? weight;
  final int? kcalPerHundred;
  final int? kcalTotal;

  Food({
    required this.id,
    required this.name,
    this.weight,
    this.kcalPerHundred,
    this.kcalTotal,
  });

  factory Food.fromMap(Map<String, dynamic> map) => Food(
        id: map['id'],
        name: map['name'],
        weight: map['weight'],
        kcalPerHundred: map['kcal_per_hundred'],
        kcalTotal: map['kcal_total'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'weight': weight,
        'kcal_per_hundred': kcalPerHundred,
        'kcal_total': kcalTotal,
      };
}

class DiaryEntry {
  final int id;
  final Food food;
  final DateTime date;
  final int weight;
  final String type;

  DiaryEntry(
      {required this.id,
      required this.food,
      required this.date,
      required this.weight,
      required this.type});

  int get kcalTotal {
    if (food.kcalPerHundred != null) {
      return (weight * food.kcalPerHundred! ~/ 100);
    } else if (food.kcalTotal != null) {
      return food.kcalTotal! * weight;
    }
    return 0;
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map, Food food) => DiaryEntry(
        id: map['id'],
        food: food,
        date: DateTime.parse(map['date']),
        weight: map['weight'],
        type: map['type'] ?? 'Перекус',
      );

  Map<String, dynamic> toMap() => {
        'food_id': food.id,
        'date':
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        'weight': weight,
        'type': type,
      };
}
