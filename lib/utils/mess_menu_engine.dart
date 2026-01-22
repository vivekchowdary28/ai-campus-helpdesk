import '../data/mess_menu_data.dart';

class MessMenuEngine {
  static String currentDay() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[DateTime.now().weekday - 1];
  }

  static String weekType() {
    final week = (DateTime.now().day / 7).ceil();
    return (week == 1 || week == 3) ? "1st_3rd" : "2nd_4th";
  }

  static String currentMeal() {
    final hour = DateTime.now().hour;
    if (hour < 10) return "breakfast";
    if (hour < 16) return "lunch";
    return "dinner";
  }

  static List<String> getMenu({
    required String preference, // veg | nonVeg
  }) {
    final week = weekType();
    final day = currentDay();
    final meal = currentMeal();

    final data = messMenu[week]?[day]?[meal]?[preference];
    return data ?? ["Not available today"];
  }
}
