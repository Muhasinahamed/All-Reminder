import 'package:flutter/material.dart';
import '../../models/notification_model.dart';

class AppConstants {
  // Notification Categories
  static const String categoryPrayer = 'prayer';
  static const String categoryWorkout = 'workout';
  static const String categoryMeal = 'meal';
  static const String categoryMedicine = 'medicine';
  static const String categoryStudy = 'study';
  static const String categorySleep = 'sleep';

  // Screen Titles
  static const String titlePrayer = 'Prayer Reminders';
  static const String titleWorkout = 'Workout Reminders';
  static const String titleMeal = 'Meal Reminders';
  static const String titleMedicine = 'Medicine Reminders';
  static const String titleStudy = 'Study Reminders';
  static const String titleSleep = 'Sleep Reminders';

  // Messages
  static const String noRemindersYet = 'No Reminders Yet!';
  static const String reminderDeleted = 'Reminder deleted';
  static const String requiredFields = 'Name and Time are required';

  // Notification Channels per Planner Category
  static const String channelPrayerId = 'channel_prayer';
  static const String channelPrayerName = 'Prayer & Azan Reminders';
  static const String channelPrayerDesc = 'Notifications for daily prayer times & Azan';

  static const String channelWorkoutId = 'channel_workout';
  static const String channelWorkoutName = 'Workout Reminders';
  static const String channelWorkoutDesc = 'Notifications for workout & exercise schedules';

  static const String channelMealId = 'channel_meal';
  static const String channelMealName = 'Meal Reminders';
  static const String channelMealDesc = 'Notifications for meal & diet schedules';

  static const String channelMedicineId = 'channel_medicine';
  static const String channelMedicineName = 'Medicine Reminders';
  static const String channelMedicineDesc = 'Notifications for pill & medicine schedules';

  static const String channelStudyId = 'channel_study';
  static const String channelStudyName = 'Study Reminders';
  static const String channelStudyDesc = 'Notifications for study & exam schedules';

  static const String channelSleepId = 'channel_sleep';
  static const String channelSleepName = 'Sleeping Reminders';
  static const String channelSleepDesc = 'Notifications for bedtime & sleep cycle schedules';

  static String getChannelIdForCategory(String category) {
    switch (category) {
      case categoryWorkout:
        return channelWorkoutId;
      case categoryMeal:
        return channelMealId;
      case categoryMedicine:
        return channelMedicineId;
      case categoryStudy:
        return channelStudyId;
      case categorySleep:
        return channelSleepId;
      case categoryPrayer:
      default:
        return channelPrayerId;
    }
  }

  static const String updateConfigUrl =
      'https://raw.githubusercontent.com/Muhasinahamed/All-Reminder/main/main/version.json';

  // Prayer specific
  static const String prayerChannelId = channelPrayerId;
  static const String prayerChannelName = channelPrayerName;
  static const String prayerChannelDescription = channelPrayerDesc;
  static const Map<String, String> prayerSounds = {
    'Takbeer': 'allahu_akbar',
    'Adhan': 'adhan',
    'Mansur Al-Zahrane - Adhan': 'mansur_al_zahrane_adhan',
    'Mishary Rashid Alafasy - Adhan': 'mishary_rashid_alafasy_adhan',
    'Nasser Al-Qatami - Adhan': 'nasser_al_qatami_adhan',
    'Badee Jadu - Adhan': 'badee_jadu_adhan',
  };
  static const String defaultPrayerSound = 'allahu_akbar';

  static String getSoundDisplayName(String soundKey) {
    for (var entry in prayerSounds.entries) {
      if (entry.value == soundKey) return entry.key;
    }
    return soundKey;
  }

  static const List<String> prayerNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  // SharedPreferences keys
  static const String keyAutoLocationEnabled = 'auto_location_enabled';
  static const String keyLastLatitude = 'last_latitude';
  static const String keyLastLongitude = 'last_longitude';

  // Colors
  static const Map<String, Color> categoryColors = {
    categoryPrayer: Colors.green,
    categoryWorkout: Colors.orange,
    categoryMeal: Colors.teal,
    categoryMedicine: Colors.blueAccent,
    categoryStudy: Colors.deepOrangeAccent,
    categorySleep: Colors.purpleAccent,
  };

  static Color getCategoryColor(String category, bool isDark) {
    if (isDark) {
      switch (category) {
        case categoryPrayer:
          return const Color(0xFF00FF87);
        case categoryWorkout:
          return const Color(0xFFFFB800);
        case categoryMeal:
          return const Color(0xFF00FFE0);
        case categoryMedicine:
          return const Color(0xFF00F0FF);
        case categoryStudy:
          return const Color(0xFFFF7700);
        case categorySleep:
          return const Color(0xFF9D00FF);
        default:
          return const Color(0xFF00F0FF);
      }
    } else {
      switch (category) {
        case categoryPrayer:
          return const Color(0xFF047857);
        case categoryWorkout:
          return const Color(0xFFD97706);
        case categoryMeal:
          return const Color(0xFF0891B2);
        case categoryMedicine:
          return const Color(0xFF0284C7);
        case categoryStudy:
          return const Color(0xFFC2410C);
        case categorySleep:
          return const Color(0xFF7E22CE);
        default:
          return const Color(0xFF0284C7);
      }
    }
  }

  // Icons
  static const Map<String, IconData> categoryIcons = {
    categoryPrayer: Icons.mosque_outlined,
    categoryWorkout: Icons.fitness_center_outlined,
    categoryMeal: Icons.restaurant_menu_outlined,
    categoryMedicine: Icons.medical_services,
    categoryStudy: Icons.school_outlined,
    categorySleep: Icons.bedtime_outlined,
  };

  // Default Prayer Times
  static List<Map<String, dynamic>> get defaultPrayerTimes => [
    {
      "name": "Fajr",
      "time": "05:00 AM",
      "enabled": false,
      "message": "auto",
      "sound": defaultPrayerSound,
    },
    {
      "name": "Dhuhr",
      "time": "12:30 PM",
      "enabled": false,
      "message": "auto",
      "sound": defaultPrayerSound,
    },
    {
      "name": "Asr",
      "time": "03:45 PM",
      "enabled": false,
      "message": "auto",
      "sound": defaultPrayerSound,
    },
    {
      "name": "Maghrib",
      "time": "06:15 PM",
      "enabled": false,
      "message": "auto",
      "sound": defaultPrayerSound,
    },
    {
      "name": "Isha",
      "time": "08:00 PM",
      "enabled": false,
      "message": "auto",
      "sound": defaultPrayerSound,
    },
  ];

  static const Map<String, List<String>> prayerWeeklyMessages = {
    'Fajr': [
      "🕌 Fajr Reminder\nAssalamu Alaikum. It is time for Fajr prayer. Rise for the remembrance of Allah and begin your day with Salah.",
      "🌄 Wake for Fajr\nWake up and answer the call of Allah. As-salātu khayrun minan-nawm (Prayer is better than sleep).",
      "🤲 Start with Allah\nBegin your day by performing Fajr prayer and seeking Allah's guidance and blessings.",
      "📿 Don't Delay Fajr\nEvery sunrise is a blessing. Offer your Fajr Salah with sincerity and devotion.",
      "🌙 Blessed Morning\nThe best way to begin your morning is with the remembrance of Allah through Fajr prayer.",
      "❤️ Seek Allah's Mercy\nPerform Fajr on time and ask Allah to grant you success, health, and peace throughout the day.",
      "✨ Morning of Faith\nMay your Fajr prayer fill your heart with light and bring barakah to your entire day.",
    ],
    'Dhuhr': [
      "🕌 Dhuhr Reminder\nAssalamu Alaikum. It is time for Dhuhr prayer. Pause your work and answer Allah's call.",
      "🤲 Time for Dhuhr\nLeave your worldly tasks for a few moments and stand before Allah in prayer.",
      "📿 Midday Salah\nPerform your Dhuhr prayer on time and seek Allah's forgiveness and mercy.",
      "🌿 Remember Allah\nRefresh your heart with the remembrance of Allah through Dhuhr Salah.",
      "🕋 Answer the Adhan\nRespond to the call to prayer and perform your Dhuhr Salah with humility.",
      "🕌 Jummah Reminder\nAssalamu Alaikum. Today is Friday, the blessed day of Jummah. Prepare for Jummah prayer, make du'a, and recite Surah Al-Kahf.",
      "❤️ Peace Through Prayer\nMay Allah accept your Dhuhr prayer and bless the rest of your day.",
    ],
    'Asr': [
      "🕌 Asr Reminder\nAssalamu Alaikum. It is time for Asr prayer. Do not delay your Salah.",
      "🤲 Time for Asr\nRemember Allah before the day comes to an end and perform your Asr prayer.",
      "📿 Afternoon Prayer\nOffer your Asr Salah with sincerity and gratitude.",
      "🌅 Protect Your Prayer\nProtect your prayers, especially Asr, and seek Allah's mercy.",
      "🕋 Stand Before Allah\nPause your daily work and devote these moments to worship.",
      "❤️ Seek Forgiveness\nAsk Allah to forgive your shortcomings and accept your Asr prayer.",
      "✨ Faith Until Sunset\nKeep your heart connected to Allah by performing Asr on time.",
    ],
    'Maghrib': [
      "🕌 Maghrib Reminder\nAssalamu Alaikum. The sun has set. It is time for Maghrib prayer.",
      "🌇 Sunset Prayer\nThank Allah for the blessings of today and perform your Maghrib Salah.",
      "🤲 Time for Maghrib\nEnd the day with gratitude by remembering Allah through prayer.",
      "📿 Evening Worship\nOffer your Maghrib prayer promptly and seek Allah's forgiveness.",
      "🌙 Blessed Evening\nFill your evening with the remembrance of Allah and sincere worship.",
      "🕋 Answer Allah's Call\nPerform Maghrib prayer with humility and thank Allah for His countless blessings.",
      "❤️ Peace at Sunset\nMay Allah accept your Maghrib prayer and fill your heart with peace.",
    ],
    'Isha': [
      "🕌 Isha Reminder\nAssalamu Alaikum. It is time for Isha prayer. End your day with the remembrance of Allah.",
      "🤲 Night Prayer\nPerform your Isha Salah before resting and seek Allah's forgiveness.",
      "📿 Complete Your Day\nEnd your day with Isha prayer and place your trust in Allah.",
      "🌙 Before Sleeping\nPray Isha, make du'a, and ask Allah for protection throughout the night.",
      "🕋 Night of Worship\nComplete your daily prayers with Isha and seek Allah's mercy.",
      "❤️ Rest with Peace\nMay Allah forgive your sins, accept your Isha prayer, and grant you peaceful sleep.",
      "✨ Sleep in Allah's Protection\nEnd your day in worship, remembering Allah and trusting in His care. May He grant you a blessed night. Āmīn.",
    ],
  };

  // Sample reminders generator for non-prayer planners
  static List<NotificationModel> getSampleReminders(String category, [String langCode = 'en']) {
    final now = DateTime.now().millisecondsSinceEpoch % 100000;
    final isTa = langCode == 'ta';
    final isUr = langCode == 'ur';

    switch (category) {
      case categoryWorkout:
        return [
          NotificationModel(
            id: now + 1,
            name: isTa
                ? "காலை உடற்பயிற்சி & கார்டியோ"
                : (isUr ? "صبح کی ورزش اور اسٹریچ" : "Morning Cardio & Stretch"),
            time: "06:30",
            message: isTa
                ? "உயர் ஆற்றலுடன் காலைப் பொழுதைத் தொடங்குங்கள்! 15 நிமிட உடற்பயிற்சி."
                : (isUr
                    ? "پرجوش انداز میں صبح کا آغاز کریں! 15 منٹ کی ورزش۔"
                    : "Start your morning with high energy! 15-min stretch & cardio."),
            category: categoryWorkout,
            repeatDays: const [1, 2, 3, 4, 5, 6, 7],
            sound: "alarm",
          ),
          NotificationModel(
            id: now + 2,
            name: isTa
                ? "மாலை உடற்பயிற்சி & வலிமை"
                : (isUr ? "شام کی جیم اور طاقت کی ورزش" : "Evening Gym & Strength"),
            time: "18:00",
            message: isTa
                ? "தசைகளின் வலிமை மற்றும் உடற்பயிற்சிக்கான நேரம்."
                : (isUr
                    ? "طاقت کی تربیت اور مسلز کے لیے وقت۔"
                    : "Time for strength training, core workout, and muscle recovery."),
            category: categoryWorkout,
            repeatDays: const [1, 2, 3, 4, 5],
            sound: "gentle",
          ),
        ];

      case categoryMeal:
        return [
          NotificationModel(
            id: now + 3,
            name: isTa
                ? "ஆரோக்கியமான காலை உணவு"
                : (isUr ? "صحت بخش ناشتہ" : "Healthy Breakfast"),
            time: "08:00",
            message: isTa
                ? "புரதம் மற்றும் புதிய பழங்களுடன் உங்கள் காலையைத் தொடங்குங்கள்!"
                : (isUr
                    ? "پروٹین اور تازہ پھلوں کے ساتھ اپنی صبح کو توانائی بخشیں!"
                    : "Fuel your morning with protein, fresh fruits, and warm tea!"),
            category: categoryMeal,
            repeatDays: const [1, 2, 3, 4, 5, 6, 7],
            sound: "gentle",
          ),
          NotificationModel(
            id: now + 4,
            name: isTa
                ? "சத்தான மதிய உணவு"
                : (isUr ? "غذائیت سے بھرپور دوپہر کا کھانا" : "Nutritious Lunch"),
            time: "13:00",
            message: isTa
                ? "சற்று ஓய்வெடுத்து சத்தான மதிய உணவை சாப்பிடுங்கள்."
                : (isUr
                    ? "تھوڑا وقفہ لیں اور متوازن دوپہر کا کھانا کھائیں۔"
                    : "Take a break and enjoy a wholesome, balanced lunch."),
            category: categoryMeal,
            repeatDays: const [1, 2, 3, 4, 5, 6, 7],
            sound: "alarm",
          ),
          NotificationModel(
            id: now + 5,
            name: isTa
                ? "லேசான இரவு உணவு"
                : (isUr ? "ہلکا رات کا کھانا" : "Light Dinner"),
            time: "19:30",
            message: isTa
                ? "சிறந்த செரிமானம் மற்றும் அமைதியான தூக்கத்திற்கு லேசான இரவு உணவு."
                : (isUr
                    ? "بہتر ہاضمے اور پرسکون نیند کے لیے ہلکا رات کا کھانا کھائیں۔"
                    : "Eat a light dinner for better digestion and peaceful sleep."),
            category: categoryMeal,
            repeatDays: const [1, 2, 3, 4, 5, 6, 7],
            sound: "gentle",
          ),
        ];

      case categoryMedicine:
        return [
          NotificationModel(
            id: now + 6,
            name: isTa
                ? "காலை மருந்துகள் & வைட்டமின்கள்"
                : (isUr ? "صبح کی ادویات اور وٹامنز" : "Morning Medication & Vitamins"),
            time: "08:30",
            message: isTa
                ? "காலை உணவுக்குப் பிறகு பரிந்துரைக்கப்பட்ட மாத்திரைகளை உட்கொள்ளுங்கள்."
                : (isUr
                    ? "ناشتے کے بعد صبح کی تجویز کردہ ادویات لیں۔"
                    : "Take morning prescribed pills and daily vitamins after breakfast."),
            category: categoryMedicine,
            repeatDays: const [1, 2, 3, 4, 5, 6, 7],
            sound: "digital",
          ),
          NotificationModel(
            id: now + 7,
            name: isTa
                ? "இரவு மருந்துகள்"
                : (isUr ? "رات کی دوا" : "Night Prescription"),
            time: "21:30",
            message: isTa
                ? "தூங்குவதற்கு முன் இரவு நேர மருந்தை உட்கொள்ளுங்கள்."
                : (isUr
                    ? "سونے سے پہلے رات کی تجویز کردہ دوا لیں۔"
                    : "Take bedtime prescribed medicine before sleeping."),
            category: categoryMedicine,
            repeatDays: const [1, 2, 3, 4, 5, 6, 7],
            sound: "digital",
          ),
        ];

      case categoryStudy:
        return [
          NotificationModel(
            id: now + 8,
            name: isTa
                ? "காலை படிப்பு நேரம்"
                : (isUr ? "صبح کی پڑھائی کا سیشن" : "Morning Study Session"),
            time: "09:00",
            message: isTa
                ? "கவனத்துடன் படிக்கும் நேரம்! 45 நிமிட ஆழ்ந்த படிப்பு."
                : (isUr
                    ? "توجہ کا وقت! شارٹ بریک کے ساتھ 45 منٹ کی گہری پڑھائی۔"
                    : "Focus time! 45-min deep study session with a short break."),
            category: categoryStudy,
            repeatDays: const [1, 2, 3, 4, 5],
            sound: "gentle",
          ),
          NotificationModel(
            id: now + 9,
            name: isTa
                ? "மாலை வாசிப்பு & திருப்புதல்"
                : (isUr ? "شام کا مطالعہ اور دہرائی" : "Evening Reading & Revision"),
            time: "17:00",
            message: isTa
                ? "இன்றைய பாடக் குறிப்புகள் மற்றும் சுருக்கங்களை திருப்புங்கள்."
                : (isUr
                    ? "آج کے نوٹوں اور سبق کا اعادہ کریں۔"
                    : "Review today's study notes, summary, and chapter revision."),
            category: categoryStudy,
            repeatDays: const [1, 2, 3, 4, 5],
            sound: "alarm",
          ),
        ];

      case categorySleep:
        return [
          NotificationModel(
            id: now + 10,
            name: isTa
                ? "மன அமைதி & ஓய்வு"
                : (isUr ? "سکون اور آرام" : "Wind Down & Unwind"),
            time: "21:45",
            message: isTa
                ? "திரைகளைப் பயன்படுத்தி ஓய்வெடுத்து தூக்கத்திற்கு தயாராகுங்கள்."
                : (isUr
                    ? "ڈیجیٹل سکرینز بند کریں اور سونے کی تیاری کریں۔"
                    : "Turn off digital screens, relax your mind, and prepare for bed."),
            category: categorySleep,
            repeatDays: const [1, 2, 3, 4, 5, 6, 7],
            sound: "lullaby",
          ),
          NotificationModel(
            id: now + 11,
            name: isTa
                ? "இரவு தூக்க அட்டவணை"
                : (isUr ? "رات کی نیند کا وقت" : "Bedtime Schedule"),
            time: "22:30",
            message: isTa
                ? "8 மணி நேர ஆழ்ந்த தூக்கத்திற்கான நேரம்."
                : (isUr
                    ? "8 گھنٹے کی پرسکون نیند کا وقت۔"
                    : "Time to sleep for 8 hours of deep restorative rest."),
            category: categorySleep,
            repeatDays: const [1, 2, 3, 4, 5, 6, 7],
            sound: "lullaby",
          ),
        ];

      default:
        return [];
    }
  }
}
