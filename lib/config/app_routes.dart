import 'package:cuan_app/data/model/lesson.dart';
import 'package:cuan_app/pages/launch/animated_splash_page.dart';
import 'package:cuan_app/pages/launch/welcome_page.dart';
import 'package:cuan_app/pages/menu/about_us_page.dart';
import 'package:cuan_app/pages/menu/edit_profile_page.dart';
import 'package:cuan_app/pages/menu/profile_page.dart';
import 'package:cuan_app/pages/menu/terms_page.dart';
import 'package:cuan_app/pages/payments/payment_launcher_page.dart';
import 'package:cuan_app/pages/payments/payment_method_page.dart';
import 'package:cuan_app/pages/screen/broker_info_page.dart';
import 'package:cuan_app/pages/screen/daftar_broker_page.dart';
import 'package:cuan_app/pages/screen/home_page.dart';
import 'package:cuan_app/pages/menu/settings_page.dart';
import 'package:cuan_app/pages/launch/help_page.dart';
import 'package:cuan_app/pages/launch/launch_page.dart';
import 'package:cuan_app/pages/launch/login_page.dart';
import 'package:cuan_app/pages/launch/otp_insert_page.dart';
import 'package:cuan_app/pages/launch/otp_metode_page.dart';
import 'package:cuan_app/pages/launch/register_page.dart';
import 'package:cuan_app/pages/launch/register_tambahan.dart';
import 'package:cuan_app/pages/screen/key_statistics_page.dart';
import 'package:cuan_app/pages/screen/lessons_page.dart';
import 'package:cuan_app/pages/screen/main_page.dart';
import 'package:cuan_app/pages/screen/modul_page.dart';
import 'package:cuan_app/pages/screen/readme_page.dart';
import 'package:cuan_app/pages/screen/video_detail_page.dart';
import 'package:cuan_app/pages/screen/video_list_page.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  //launch
  static const splash = '/';
  static const launch = '/launch';
  static const login = '/login';
  static const register = '/register';
  static const registerTambahan = '/register_tambahan';
  static const otpMetode = '/otp_metode';
  static const otpInsert = '/otp_insert';
  static const help = '/help';

  //home
  static const welcome = '/welcome';
  static const main = '/main';
  static const home = '/home';
  static const readme = '/readme';
  static const modul = '/modul';
  static const videoDetail = '/video_detail';
  static const lessons = '/lessons';
  static const listVideo = '/list_video';
  static const historyVideo = '/history_video';
  static const brokerInfo = '/broker_info';
  static const daftarBroker = '/daftar_broker';

  //menu
  static const settings = '/settings';
  static const profile = '/profile';
  static const editProfile = '/edit_profile';
  static const aboutUs = '/about_us';
  static const terms = '/terms';
  static const termsO = '/terms';

  //detail
  static const keyStats = '/key_stats';

  //payment
  static const paymentMethod = '/payment_method';
  static const paymentLauncher = '/payment_launcher';

  static final Map<String, WidgetBuilder> pages = {
    splash: (_) => const AnimatedSplashPage(),
    launch: (_) => LaunchPage(),
    login: (_) => LoginPage(),
    register: (_) => RegisterPage(),
    registerTambahan: (_) => RegisterTambahan(),
    otpMetode: (_) => OtpMetodePage(),
    // Ambil argumen ter-typed
    otpInsert: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final verificationType = args['type'] as OtpVerificationType;
      final contactInfo = args['contact'] as String;
      return OtpInsertPage(
        verificationType: verificationType,
        contactInfo: contactInfo,
      );
    },

    help: (_) => HelpPage(),
    settings: (_) => SettingsPage(),
    profile: (_) => ProfilePage(),
    aboutUs: (_) => const AboutUsPage(),
    terms: (_) => const TermsPage(),
    // editProfile: (context) {
    //   final args =
    //       ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    //   return EditProfilePage(
    //     fullname: args?['name'] as String? ?? '',
    //     username: args?['username'] as String? ?? '',
    //     birthPlace: args?['birthPlace'] as String? ?? '',
    //     birthDate: args?['birthDate'] as String? ?? '',
    //     domicile: args?['domicile'] as String? ?? '',
    //     phone: args?['phone'] as String? ?? '',
    //   );
    // },
    editProfile: (_) => const EditProfilePage(),

    //beranda
    welcome: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      final name = (args?['name'] as String?) ?? 'User';
      final avatarUrl = args?['avatarUrl'] as String?;
      return WelcomePage(displayName: name, avatarUrl: avatarUrl);
    },
    main: (_) => MainPage(),
    home: (_) => HomePage(),
    modul: (_) => ModulPage(),

    // Readme butuh argumen (punya default aman)
    readme: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      final prefKey = (args?['prefKey'] as String?) ?? 'readme_default_v1';
      final popInstead = (args?['popInsteadOfReplace'] as bool?) ?? false;

      return ReadmePage(prefKey: prefKey, popInsteadOfReplace: popInstead);
    }, // Video Detail wajib Lesson
    videoDetail: (context) {
      final a =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final lesson = a['lesson'] as Lesson;
      final playlistId = a['playlistId'] as String; // ← wajib ada
      return VideoDetailPage(lesson: lesson, playlistId: playlistId);
    },
    // lessons: (context) {
    //   final a = ModalRoute.of(context)!.settings.arguments;

    //   if (a is Map<String, dynamic> && a['lesson'] is Lesson) {
    //     return LessonsPage(
    //       lesson: a['lesson'] as Lesson,
    //       part: (a['part'] as int?) ?? 1,
    //       position: (a['position'] as Duration?) ?? Duration.zero,
    //       duration:
    //           (a['duration'] as Duration?) ??
    //           const Duration(hours: 1, minutes: 59, seconds: 21),
    //     );
    //   }

    //   // fallback agar tidak crash jika argumen salah/kurang
    //   return Scaffold(
    //     appBar: AppBar(title: const Text('Routing Error')),
    //     body: const Center(
    //       child: Padding(
    //         padding: EdgeInsets.all(16),
    //         child: Text(
    //           'LessonsPage membutuhkan arguments: {lesson: Lesson, part: int, '
    //           'position?: Duration, duration?: Duration}.',
    //           textAlign: TextAlign.center,
    //         ),
    //       ),
    //     ),
    //   );
    // },
    lessons: (context) {
      final a =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      if (a != null &&
          a['lesson'] is Lesson &&
          a['playlistId'] is String &&
          a['videoId'] is String) {
        return LessonsPage(
          lesson: a['lesson'] as Lesson,
          part: (a['part'] as int?) ?? 1,
          playlistId: a['playlistId'] as String, // ⬅️ WAJIB
          videoId: a['videoId'] as String, // ⬅️ WAJIB
          position: (a['position'] as Duration?) ?? Duration.zero,
          duration: (a['duration'] as Duration?) ?? Duration.zero,
        );
      }

      // fallback aman
      return const Scaffold(
        body: Center(
          child: Text('Routing Error: butuh lesson, playlistId, videoId'),
        ),
      );
    },

    // listVideo: (context) {
    //   final a =
    //       ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    //   final lesson = a?['lesson'] as Lesson?;
    //   final totalParts = (a?['totalParts'] as int?) ?? 0;
    //   final watched = (a?['watched'] as Set<int>?) ?? const <int>{};

    //   if (lesson != null && totalParts > 0) {
    //     return VideoListPage(
    //       lesson: lesson,
    //       totalParts: totalParts,
    //       watched: watched,
    //     );
    //   }

    //   // fallback aman
    //   return Scaffold(
    //     appBar: AppBar(title: const Text('Routing Error')),
    //     body: const Center(
    //       child: Padding(
    //         padding: EdgeInsets.all(16),
    //         child: Text(
    //           'List video membutuhkan arguments: {lesson: Lesson, totalParts: int, watched?: Set<int>}.',
    //           textAlign: TextAlign.center,
    //         ),
    //       ),
    //     ),
    //   );
    // },
    listVideo: (context) {
      final a =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      final lesson = a?['lesson'] as Lesson?;
      final playlistId = a?['playlistId'] as String?;
      if (lesson != null && playlistId != null) {
        return VideoListPage(lesson: lesson, playlistId: playlistId);
      }
      return const Scaffold(
        body: Center(child: Text('Routing Error: butuh lesson & playlistId')),
      );
    },
    //detail
    brokerInfo: (_) => BrokerInfoPage(),
    daftarBroker: (_) => DaftarBrokerPage(),
    keyStats: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      final ticker = args?['ticker'] as String? ?? '';
      return KeyStatisticsPage(ticker: ticker);
    },

    //payment
    paymentMethod: (_) => PaymentMethodPage(),
    paymentLauncher: (_) => PaymentLauncherPage(),
  };
}
