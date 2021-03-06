// ignore_for_file: prefer_initializing_formals, must_be_immutable

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ucms/views/components/custom_buttons.dart';
import 'package:ucms/views/components/custom_screen.dart';
import 'package:ucms/views/components/label.dart';
import 'package:ucms/views/components/texts.dart';
import 'package:ucms/services/beacon/beacon_manager.dart';
import 'package:ucms/model/expan_item.dart';
import 'package:ucms/model/places/place.dart';
import 'package:ucms/model/position_list.dart';
import 'package:ucms/model/time_list.dart';
import 'package:ucms/views/cohort/cohort_main.dart';
import 'package:ucms/views/login/login_page.dart';
import 'package:ucms/views/user/user_assemble.dart';
import 'package:ucms/views/user/user_move.dart';
import 'package:ucms/services/socket/user_socket_client.dart';
import 'package:ucms/views/theme/color_theme.dart';
import 'package:ucms/views/theme/size.dart';
import 'package:ucms/views/theme/text_theme.dart';
import 'package:ucms/controllers/cohort_controller.dart';
import 'package:ucms/controllers/place_controller.dart';
import 'package:ucms/utils/snackbar.dart';
import 'package:ucms/controllers/user_controller.dart';

class UserMain extends StatefulWidget {
  UserMain({Key? key, required this.location, required this.state})
      : super(key: key);

  String? location = "location uninitialized";
  String? state = "state uninitialized";
  @override
  State<UserMain> createState() => _UserMainState();
}

class _UserMainState extends State<UserMain> {
  final store = GetStorage();
  UserController u = Get.find<UserController>();
  PlaceController p = Get.find<PlaceController>();
  List<ExpanItem> expanItems = [];
  int selectedIndex = 1;
  bool firstSnack = true;
  ScrollController scrollCon = ScrollController();

  @override
  void initState() {
    super.initState();
    var beaconMan = Get.find<BeaconManager>();
    UserSocketClient socketClient = Get.find<UserSocketClient>();
    socketClient.startSocket(store.read("token"));
    var beaconResult = beaconMan.beaconResult;
    int min15 = 900;

    beaconMan.startListeningBeacons();
    Timer.periodic(const Duration(minutes: 2), (timer) {
      if (min15 >= 0) {
        socketClient.locationReport(
            macAddress: beaconResult.macAddress,
            proximity: double.parse(beaconResult.proximity));
        min15 -= 2;
      } else {
        timer.cancel();
      }
    });
    print("initState ${p.positions.length}");
    expanItems = List<ExpanItem>.generate(p.positions.length, (index) {
      return ExpanItem(
          expanded: false,
          header: p.positions[index].place.name,
          body: p.positions[index].toListTiles());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String name = store.read("name") ?? "??????";
    widget.location = store.read("recent_place_name") ?? "?????? ??????";
    widget.state = store.read("state");
    // ?????????????????? ????????? ????????????! ????????? ??? ???????????? ?????? snack bar??? ???????????? ?????? ??????????????????!
    // if (firstSnack) Snack.top("?????? ??????", "$name ????????? ????????????????????????."); TODO HERE
    firstSnack = false;

    bool assembleVisible = store.read("assemble_visible") ?? false;

    final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
        GlobalKey<RefreshIndicatorState>();

    List<Widget> widgetOptions =
        _buildPages(p.positions, expanItems, assembleVisible, name, scrollCon);

    return KScreen(
      child: widgetOptions.elementAt(selectedIndex),
      bottomBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_red_eye),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'My Profile',
          ),
        ],
        currentIndex: selectedIndex,
        selectedItemColor: selectedColor(),
        onTap: _onItemTapped,
        elevation: 5,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void _scrollToSelectedContent(
      bool isExpanded, double previousOffset, int index) {
    scrollCon.animateTo(isExpanded ? (100.0 * index) : previousOffset,
        duration: const Duration(milliseconds: 500), curve: Curves.linear);
  }

  List<Widget> _buildPages(
      List<PositionList> positions,
      List<ExpanItem> expanItems,
      bool assembleVisible,
      String name,
      ScrollController scrollCon) {
    return <Widget>[
      Obx(
        () => ListView(
          controller: scrollCon,
          children: [
            topMargin(),
            title("????????????"),
            quote("??????????????? ????????? ???????????????"),
            const SizedBox(height: 40),
            ExpansionPanelList(
              animationDuration: const Duration(milliseconds: 2000),
              children: [
                ...List<ExpansionPanel>.generate(positions.length, (index) {
                  print("${positions.length} $index");
                  return ExpansionPanel(
                    headerBuilder: (context, isExpanded) {
                      return ListTile(
                        title: Text(
                          "${positions[index].place.name} (${positions[index].list.length} ???)",
                          style: body(),
                        ),
                      );
                    },
                    body: positions[index].toListTiles(),
                    isExpanded: expanItems[index].expanded,
                    canTapOnHeader: true,
                  );
                }),
              ],
              dividerColor: Colors.grey,
              expansionCallback: (panelIndex, isExpanded) {
                setState(() {
                  expanItems[panelIndex].expanded = !isExpanded;
                  _scrollToSelectedContent(expanItems[panelIndex].expanded,
                      scrollCon.offset, panelIndex);
                });
              },
            ),
            footer(),
          ],
        ),
      ),
      ListView(
        children: [
          topMargin(),
          title("UMCS"),
          quote("Untact Movement Control System"),
          const SizedBox(height: 20),
          LabelText(label: "??? ??????", content: widget.location!),
          LabelText(label: "??? ??????", content: widget.state!),
          const SizedBox(height: 20),
          Visibility(
            visible: assembleVisible,
            child: WarnButton(
                onPressed: () {
                  Get.to(
                      UserAssemble(location: store.read("assemble_location")));
                },
                label: "?????? ????????? ??????????????????."),
          ),
          PageButton(
              onPressed: () async {
                // TODO HERE
                List<Place> btns = await p.outsideFacilAllInfo();
                Get.to(UserMove(btns: btns));
              },
              label: "?????? ?????? ??????"),
          footer(),
        ],
      ),
      ListView(
        children: [
          topMargin(),
          title("?????????"),
          quote("??? ????????? ??????"),
          const SizedBox(height: 20),
          const Icon(
            Icons.account_circle,
            size: 100.0,
          ),
          quote("$name ??? ???????????????."),
          const SizedBox(height: 20),
          PageButton(
              onPressed: () {
                u.logout();
                Get.offAll(LoginPage());
              },
              label: "??????????????????"),
          WarnButton(
              onPressed: () async {
                store.writeIfNull("state", "??????");

                await u.currentPosition(store.read("tag"));
                // positions = await p.positionAllInfo();

                Snack.top("????????? ??????", "??????");
                WidgetsBinding.instance!
                    .addPostFrameCallback((_) => Get.to(CohortMain(
                          location: store.read("recent_place_name") ??
                              "error in LoginPage",
                          state: store.read("state") ?? "",
                        )));
              },
              label: "????????? ?????? ?????? ??????"),
          footer(),
        ],
      ),
    ];
  }
}
