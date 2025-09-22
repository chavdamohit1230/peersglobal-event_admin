import 'package:go_router/go_router.dart';
import 'package:peersglobaladmin/pages/admin_home_screen.dart';
import 'package:peersglobaladmin/pages/admin_splashscreen.dart';
import 'package:peersglobaladmin/pages/adminlogin.dart';
import 'package:peersglobaladmin/pages/forgetpasswordscreen.dart';
import 'package:peersglobaladmin/pages/manageexhibiter.dart';
import 'package:peersglobaladmin/pages/managefloorplan.dart';
import 'package:peersglobaladmin/pages/managesponsor.dart';
import 'package:peersglobaladmin/pages/manageuser.dart';


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

      GoRoute(path: '/manageuser'
        ,builder: (context, state) => Manageuser(),),

      GoRoute(path: '/managesponsor',
        builder: (context, state) => Managesponsor(),),

        GoRoute(path: '/manageexhibiter',
        builder: (context, state) => Manageexhibiter()),

      GoRoute(path: '/managefloorplan',
          builder: (context, state) =>ManageFloorPlan()),





    ]);


}