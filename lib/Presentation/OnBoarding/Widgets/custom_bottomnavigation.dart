import 'package:flutter/material.dart';
import 'package:hopper/Core/Consents/app_colors.dart';
import 'package:hopper/Core/Utility/app_images.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/home_screens.dart';
import 'package:hopper/Presentation/OnBoarding/Screens/package_screens.dart';
import 'package:hopper/uber_screen.dart';

class CommonBottomNavigation extends StatefulWidget {
  final int initialIndex;
  const CommonBottomNavigation({super.key, this.initialIndex = 0});

  @override
  CommonBottomNavigationState createState() => CommonBottomNavigationState();
}

class CommonBottomNavigationState extends State<CommonBottomNavigation> {
  int _selectedIndex = 0;

  static List<Widget> _screens = <Widget>[
    HomeScreens(),
    PackageScreens(),
    PackageScreens(),
    PackageScreens(),
    PackageScreens(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: _selectedIndex, children: _screens),
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
    );
  }
}
