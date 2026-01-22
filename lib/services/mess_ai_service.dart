import '../utils/mess_menu_engine.dart';

class MessAIService {
  static String buildAnswer({required String preference}) {
    final items = MessMenuEngine.getMenu(preference: preference);

    return '''
Today's Mess Menu

Day: ${MessMenuEngine.currentDay()}
Meal: ${MessMenuEngine.currentMeal()}
Preference: $preference

Items:
${items.map((e) => "• $e").join("\n")}

This information is based on the official mess menu.
''';
  }
}
