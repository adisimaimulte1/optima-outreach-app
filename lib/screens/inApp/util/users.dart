import 'package:flutter/material.dart';
import 'package:optima/ai/navigator/key_registry.dart';
import 'package:optima/globals.dart';
import 'package:optima/screens/inApp/widgets/abstract_screen.dart';
import 'package:optima/screens/inApp/widgets/users/tabs/events_chat_tab.dart';
import 'package:optima/screens/inApp/widgets/users/tabs/public_events_tab.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => UsersScreenState();
}

class UsersScreenState extends State<UsersScreen> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    usersController.attachVSync(this);

    final tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: usersController.lastTabIndex,
    );

    usersController.init(tabController);


    tabController.animation?.addListener(() {
      final value = tabController.animation!.value;
      final newIndex = value.round();
      if (newIndex != tabController.index) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    });

    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScreenRegistry.register<UsersScreenState>(
          ScreenType.users, widget.key as GlobalKey<UsersScreenState>);

      if (showEventChatOnLaunch.key && showEventChatOnLaunch.value != null) {
        usersController.tabController.animateTo(0);
      }
    });
  }

  @override
  void dispose() {
    usersController.dispose();
    ScreenRegistry.unregister(ScreenType.users);
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return AbsScreen(
      sourceType: UsersScreen,
      builder: (context, isMinimized, scale) {

        return AnimatedBuilder(
          animation: combinedEventsListenable,
          builder: (context, _) {
            return Stack(
              children: [
                Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Column(
                    children: [
                      const SizedBox(height: 85),
                      _buildTabBar(context),
                      _buildDivider(),
                      const SizedBox(height: 10),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: usersController.tabController,
                          builder: (context, _) {
                            return IndexedStack(
                              index: usersController.tabController.index,
                              children: [
                                EventsChatTab(key: eventsChatTabKey),
                                PublicEventsTab(key: publicEventsTabKey),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Tap zones
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 60,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      final index = usersController.tabController.index;
                      if (index > 0) {
                        usersController.tabController.animateTo(index - 1);
                      }
                    },
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 60,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      final index = usersController.tabController.index;
                      if (index < usersController.tabController.length - 1) {
                        usersController.tabController.animateTo(index + 1);
                      }
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final animationValue = usersController.tabController.animation?.value ?? usersController.tabController.index.toDouble();
    final isSwipingRight = animationValue < 0.5;
    final isSwipingLeft = animationValue > 0.5;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (!isSwipingRight) {
                  usersController.tabController.animateTo(0);
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.chevron_left,
                  key: ValueKey(isSwipingRight ? "dim" : "bright"),
                  size: 40,
                  color: isSwipingRight ? Colors.white24 : textHighlightedColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 50,
              decoration: BoxDecoration(
                color: inAppForegroundColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: textDimColor, width: 1.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                ),
                child: TabBar(
                  controller: usersController.tabController,
                  onTap: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() {});
                  }),
                  indicator: BoxDecoration(
                    color: textHighlightedColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  labelColor: inAppBackgroundColor,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Events Chat'),
                    Tab(text: 'All Events'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                if (!isSwipingLeft) {
                  usersController.tabController.animateTo(1);
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.chevron_right,
                  key: ValueKey(isSwipingLeft ? "dim" : "bright"),
                  size: 40,
                  color: isSwipingLeft ? Colors.white24 : textHighlightedColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Divider(color: textDimColor, thickness: 1),
    );
  }
}