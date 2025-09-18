import 'package:go_router/go_router.dart';
import 'package:peersglobaladmin/pages/admin_home_screen.dart';
import 'package:peersglobaladmin/pages/admin_splashscreen.dart';
import 'package:peersglobaladmin/pages/adminlogin.dart';
import 'package:peersglobaladmin/pages/exhibitor_screen.dart';
import 'package:peersglobaladmin/pages/forgetpasswordscreen.dart';
import 'package:peersglobaladmin/pages/sponsor_screen.dart';


class AppRout{

    static final GoRouter router=GoRouter(routes:[

      GoRoute(path:'/',
      builder:(context, state) => AdminSplashscreen(),
      ),

      GoRoute(path:'/adminlogin',
      builder:(context, state) =>Adminlogin(),),

      GoRoute(path: '/forgetpasswordscreen',
      builder: (context, state) => ForgotPasswordScreen(),),

      GoRoute(path: '/admin_home'
        ,builder: (context, state) => AdminHomeScreen(),),

      GoRoute(path: '/exhibitot_screen'
        ,builder: (context, state) =>ExhibitorScreen(),),


      GoRoute(path: '/sponsor_screen'
        ,builder: (context, state) =>SponsorScreen(),),



    ]);


}