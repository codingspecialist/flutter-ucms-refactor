// ignore_for_file: prefer_initializing_formals, must_be_immutable

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ucms/views/components/custom_buttons.dart';
import 'package:ucms/services/beacon/beacon_manager.dart';
import 'package:ucms/views/components/custom_screen.dart';
import 'package:ucms/views/components/label.dart';
import 'package:ucms/views/components/texts.dart';
import 'package:ucms/model/expan_item.dart';
import 'package:ucms/model/places/place.dart';
import 'package:ucms/model/position_list.dart';
import 'package:ucms/model/time_list.dart';
import 'package:ucms/views/cohort/cohort_assemble.dart';
import 'package:ucms/views/cohort/cohort_move.dart';
import 'package:ucms/views/login/login_page.dart';
import 'package:ucms/views/user/user_main.dart';
import 'package:ucms/services/socket/user_socket_client.dart';
import 'package:ucms/views/theme/color_theme.dart';
import 'package:ucms/views/theme/size.dart';
import 'package:ucms/views/theme/text_theme.dart';
import 'package:ucms/controllers/cohort_controller.dart';
import 'package:ucms/controllers/place_controller.dart';
import 'package:ucms/utils/snackbar.dart';
import 'package:ucms/controllers/user_controller.dart';
import 'package:ucms/utils/validate.dart';

class CohortMain extends StatefulWidget {
  CohortMain({Key? key, this.location, this.state}) : super(key: key);

  String? location = "location uninitialized";
  String? state = "state uninitialized";
  @override
  State<CohortMain> createState() => _CohortMainState();
}

class _CohortMainState extends State<CohortMain> {
  final store = GetStorage();
  UserController u = Get.find<UserController>();
  PlaceController p = Get.find<PlaceController>();
  CohortController c = Get.find<CohortController>();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final nameCon = TextEditingController();
  final rankCon = TextEditingController();
  final timeCon = TextEditingController();
  final tempCon = TextEditingController();
  final descCon = TextEditingController();

  int selectedIndex = 2;
  bool firstSnack = true;

  List<ExpanItem> expanItemsPos = [];
  List<ExpanItem> expanItemsTimes = [];

  @override
  void initState() {
    super.initState();
    var beaconMan = Get.find<BeaconManager>();
    UserSocketClient socketClient = Get.find<UserSocketClient>();
    socketClient.startSocket(store.read("token"));
    var beaconResult = beaconMan.beaconResult;
    int min15 = 900;

    beaconMan.startListeningBeacons();
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (min15 >= 0) {
        // String => double parse Error : TODO HERE
        double resultProximity = 0;
        try {
          resultProximity = double.parse(beaconResult.proximity);
        } catch (e) {}

        socketClient.locationReport(
            macAddress: beaconResult.macAddress, proximity: resultProximity);

        min15 -= 2;
      } else {
        timer.cancel();
      }
    });
    expanItemsPos = List<ExpanItem>.generate(p.positions.length, (index) {
      return ExpanItem(
          expanded: false,
          header: p.positions[index].place.name,
          body: p.positions[index].toListTiles());
    });
    expanItemsTimes = List<ExpanItem>.generate(c.times.length, (index) {
      return ExpanItem(
          expanded: false,
          header: c.times[index].place.name,
          body: c.times[index].toListTiles());
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
    // ?????? ??????????????? ?????? ?????????????????? ?????? ?????????~! TODO HERE
    // if (firstSnack) Snack.warnTop("????????? ??????", "$name ????????? ????????????????????????.");
    firstSnack = false;

    bool assembleVisible = store.read("assemble_visible") ?? false;
    final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
        GlobalKey<RefreshIndicatorState>();

    List<Widget> widgetOptions = _buildPages(c,
        positions: p.positions,
        expanItemsPos: expanItemsPos,
        times: c.times,
        expanItemsTimes: expanItemsPos,
        assembleVisible: assembleVisible,
        name: name,
        nameCon: nameCon,
        formKey: formKey,
        rankCon: rankCon,
        timeCon: timeCon,
        tempCon: tempCon,
        descCon: descCon);

    return KScreen(
      child: widgetOptions.elementAt(selectedIndex),
      bottomBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_red_eye),
            label: '?????? ?????? ??????',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_busy),
            label: '?????? ?????????',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '???',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.thermostat),
            label: '?????? ??????',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: '??? ?????????',
          ),
        ],
        currentIndex: selectedIndex,
        unselectedItemColor: Colors.grey,
        selectedItemColor: warningColor(),
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

  List<Widget> _buildPages(CohortController c,
      {required List<PositionList> positions,
      required List<ExpanItem> expanItemsPos,
      required List<TimeList> times,
      required List<ExpanItem> expanItemsTimes,
      required bool assembleVisible,
      required String name,
      required nameCon,
      required GlobalKey<FormState> formKey,
      required rankCon,
      required timeCon,
      required tempCon,
      required descCon}) {
    DateTime _now = DateTime.now().toUtc().add(const Duration(hours: 9));
    return <Widget>[
      Obx(
        () => ListView(
          children: [
            topMargin(),
            title("???????????? ?????? ?????? ??????"),
            quote("??????????????? ????????? ???????????????"),
            const SizedBox(height: 50),
            ExpansionPanelList(
              //TODO : ExpansionTile ??? ?????? ???????????? ?????????.
              animationDuration: const Duration(milliseconds: 2000),
              children: [
                ...List<ExpansionPanel>.generate(positions.length, (index) {
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
                    isExpanded: expanItemsPos[index].expanded,
                    canTapOnHeader: true,
                  );
                }),
              ],
              dividerColor: Colors.grey,
              expansionCallback: (panelIndex, isExpanded) {
                setState(() {
                  expanItemsPos[panelIndex].expanded = !isExpanded;
                });
              },
            ),
            const SizedBox(height: 20),
            footer(),
          ],
        ),
      ),
      Obx(
        () => ListView(
          children: [
            topMargin(),
            title("???????????? ?????? ????????? ??????"),
            quote("????????? ??? ?????? ????????? ???????????????"),
            const SizedBox(height: 50),
            ExpansionPanelList(
              //TODO : ExpansionTile ??? ?????? ???????????? ?????????.
              animationDuration: const Duration(milliseconds: 2000),
              children: [
                ...List<ExpansionPanel>.generate(times.length, (index) {
                  return ExpansionPanel(
                    headerBuilder: (context, isExpanded) {
                      return ListTile(
                        title: Text(
                          "${times[index].place.name} ?????????",
                          style: body(),
                        ),
                      );
                    },
                    body: times[index].toListTiles(),
                    isExpanded: expanItemsTimes[index].expanded,
                    canTapOnHeader: true,
                  );
                }),
              ],
              dividerColor: Colors.grey,
              expansionCallback: (panelIndex, isExpanded) {
                setState(() {
                  expanItemsTimes[panelIndex].expanded = !isExpanded;
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
          Visibility(
            visible: assembleVisible,
            child: WarnButton(
                onPressed: () {
                  Get.to(CohortAssemble(
                      location: store.read("assemble_location")));
                },
                label: "?????? ????????? ??????????????????."),
          ),
          WarnButton(
              onPressed: () async {
                List<Place> btns = await p.outsideFacilAllInfo();
                Get.to(CohortMove(name: "????????????", btns: btns));
              },
              label: "???????????? ?????? ?????? ??????"),
          WarnButton(
              onPressed: () async {
                List<Place> btns = await p.doomFacilAllInfo();
                Get.to(CohortMove(name: "?????? ???", btns: btns));
              },
              label: "?????? ??? ?????? ?????? ??????"),
          footer(),
        ],
      ),
      ListView(
        children: [
          topMargin(),
          title("???????????? ??? ???????????? ??????"),
          quote("??? ??????????????? ???????????????."),
          const SizedBox(height: 40),
          Form(
            key: formKey,
            child: Column(
              // ignore: prefer_const_literals_to_create_immutables
              children: [
                LabelFormDropDown(
                  label: "??????",
                  labels: const ["?????????", "??????", "??????", "??????", "??????"],
                  hint: "??????",
                  controller: rankCon,
                  validator: validateNull(),
                  isCohort: true,
                ),
                LabelFormInput(
                  label: "??????",
                  hint: "??????",
                  controller: nameCon,
                  validator: validateNull(),
                  isCohort: true,
                ),
                LabelFormDateTimeInput(
                  label: "?????? ??????",
                  hint: "${_now.hour}:${_now.minute}",
                  controller: timeCon,
                  validator: validateTime(),
                  isCohort: true,
                ),
                LabelFormFloatInput(
                  label: "?????? ??????",
                  hint: "36.5",
                  controller: tempCon,
                  validator: validateNull(),
                  isCohort: true,
                ),
                LabelFormInput(
                  label: "?????? ??????",
                  hint: "???????????? ??????",
                  controller: descCon,
                  validator: validateNull(),
                  isCohort: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          WarnButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  var json = {
                    "temperature": tempCon.text.trim(),
                    "details": descCon.text.trim(),
                  };
                  String result = await c.anomaly(json);
                  if (result == "success") {
                    Get.back();
                    Snack.top("?????? ?????? ?????? ??????", "??????");
                  } else {
                    Snack.warnTop("?????? ?????? ?????? ??????", result);
                  }
                }
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
          WarnButton(
              onPressed: () {
                u.logout();
                Get.offAll(LoginPage());
              },
              label: "??????????????????"),
          PageButton(
              onPressed: () async {
                store.writeIfNull("state", "??????");

                await u.currentPosition(store.read("tag"));
                // await p.positionAllInfo();

                Get.to(UserMain(
                  location:
                      store.read("recent_place_name") ?? "error in LoginPage",
                  state: store.read("state") ?? "",
                ));
              },
              label: "????????? ?????? ?????? ??????"),
          footer(),
        ],
      ),
    ];
  }
}
