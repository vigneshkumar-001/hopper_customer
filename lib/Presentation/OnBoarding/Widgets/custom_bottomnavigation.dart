import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/BookRide/Screens/book_map_screen.dart';
import 'package:hopper/Presentation/BookRide/Screens/search_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/chat_screen.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/home_screens.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/package_screens.dart';
import 'package:hopper/dummy2.dart';
import 'package:hopper/dummy_screen.dart';
import 'package:hopper/uber_screen.dart';
import 'package:hopper/uitls/netWorkHandling/network_handling_screen.dart';

class CommonBottomNavigation extends StatefulWidget {
  final int initialIndex;
  const CommonBottomNavigation({super.key, this.initialIndex = 0});

  @override
  CommonBottomNavigationState createState() => CommonBottomNavigationState();
}

class CommonBottomNavigationState extends State<CommonBottomNavigation> {
  int _selectedIndex = 0;

  // final List<Widget> _screens = <Widget>[
  //   HomeScreens(),
  //   BookRideSearchScreen(),
  //   PackageScreens(),
  //   PackageScreens(),
  //   ChatScreen(),
  // ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreens();
      case 1:
        return BookRideSearchScreen();
      case 2:
        return DummyScreen();
      case 3:
        return PackageScreens();
      case 4:
        return ChatScreen(bookingId: '');
      default:
        return HomeScreens();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: NoInternetOverlay(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: _getScreen(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: AppColors.commonWhite,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,

            selectedItemColor: AppColors.commonBlack,
            unselectedItemColor: Color(0xFF93959F),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),

            items: [
              BottomNavigationBarItem(
                icon: Image.asset(
                  AppImages.bHome,
                  height: 30,
                  width: 30,
                  color:
                      _selectedIndex == 0
                          ? AppColors.commonBlack
                          : Color(0xFF93959F),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  AppImages.bCar,
                  height: 30,
                  width: 30,
                  color:
                      _selectedIndex == 1
                          ? AppColors.commonBlack
                          : Color(0xFF93959F),
                ),
                label: 'Ride',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  AppImages.bWallet,
                  height: 30,
                  width: 30,
                  color:
                      _selectedIndex == 2
                          ? AppColors.commonBlack
                          : Color(0xFF93959F),
                ),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  AppImages.bPackage,
                  height: 30,
                  width: 30,
                  color:
                      _selectedIndex == 3
                          ? AppColors.commonBlack
                          : Color(0xFF93959F),
                ),
                label: 'Package',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  AppImages.bProfile,
                  height: 30,
                  width: 30,
                  color:
                      _selectedIndex == 4
                          ? AppColors.commonBlack
                          : Color(0xFF93959F),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
