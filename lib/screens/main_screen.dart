import 'package:all_reminder/screens/meal_screen.dart';
import 'package:all_reminder/screens/medicine_screen.dart';
import 'package:all_reminder/screens/sleep_screen,dart';
import 'package:all_reminder/screens/snacks_screen.dart';
import 'package:all_reminder/screens/workout_screen.dart';
import 'package:flutter/material.dart';
import '../screens/prayer_screen.dart';

import '../widgets/main_button_widget.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder App'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      buildNavigationButton(
                        context,
                        'Prayer Planner',
                        Icons.mosque_outlined,
                        Colors.greenAccent.shade400,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PrayerScreen()),
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildNavigationButton(
                        context,
                        'Workout Planner',
                        Icons.fitness_center_outlined,
                        Colors.orange.shade400,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => WorkoutScreen()),
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildNavigationButton(
                        context,
                        'Meal Planner',
                        Icons.restaurant_menu_outlined,
                        Colors.teal.shade400,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MealScreen()),
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildNavigationButton(
                          context,
                          'Medicine Planner',
                          Icons.medical_services,
                          Colors.blueAccent.shade400,
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MedicineScreen()),
                              )),
                      const SizedBox(height: 20),
                      buildNavigationButton(
                        context,
                        'Snacks Planner',
                        Icons.fastfood_outlined,
                        Colors.orange.shade300,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SnacksScreen()),
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildNavigationButton(
                        context,
                        'Sleeping Planner',
                        Icons.bedtime_outlined,
                        Colors.purple.shade400,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SleepScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
