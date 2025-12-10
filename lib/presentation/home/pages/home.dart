import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotify/core/extensions/is_dark_mode.dart';
import 'package:spotify/core/constants/app_images.dart';
import 'package:spotify/core/theme/app_colors.dart';
import 'package:spotify/presentation/home/widgets/news_songs.dart';
import 'package:spotify/presentation/home/widgets/play_list.dart';
import 'package:spotify/presentation/home/widgets/artist_list_tab.dart';
import 'package:spotify/presentation/home/widgets/genre_list_tab.dart';
import 'package:spotify/presentation/home/widgets/search_bar_widget.dart';
import 'package:spotify/presentation/profile/pages/profile.dart';
import 'package:spotify/presentation/auth/pages/signup_or_siginin.dart';
import 'package:spotify/shared/widgets/basic_app_bar.dart';
import 'package:spotify/core/constants/app_vectors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        hideBack: true,
        action: PopupMenuButton<String>(
          icon: const Icon(Icons.person),
          onSelected: (value) async {
            if (value == 'profile') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            } else if (value == 'logout') {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupOrSigninPage()),
                      (route) => false,
                );
              }
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ];
          },
        ),
        title: SvgPicture.asset(
          AppVectors.logo,
          height: 40,
          width: 40,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SearchBarWidget(),
            _homeTopCard(),
            _tabs(),
            SizedBox(
              height: 260,
              child: TabBarView(
                controller: _tabController,
                children: const [
                  NewsSongs(),
                  Center(child: Text('Videos coming soon...')),
                  ArtistListTab(),
                  GenreListTab(),
                ],
              ),
            ),
            const PlayList()
          ],
        ),
      ),
    );
  }

  Widget _homeTopCard() {
    return Center(
      child: SizedBox(
        height: 140,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: SvgPicture.asset(AppVectors.homeTopCard),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 60),
                child: Image.asset(AppImages.homeArtist),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: context.isDarkMode ? Colors.white : Colors.black,
      indicatorColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      tabs: const [
        Text(
          'News',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        Text(
          'Videos',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        Text(
          'Artists',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        Text(
          'Genres',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        )
      ],
    );
  }
}