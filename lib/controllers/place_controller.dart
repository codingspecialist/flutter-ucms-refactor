import 'dart:convert';

import 'package:get/get.dart';
import 'package:ucms/model/places/doom.dart';
import 'package:ucms/model/places/doomfacility.dart';
import 'package:ucms/model/places/doomroom.dart';
import 'package:ucms/model/places/outside_facility.dart';
import 'package:ucms/model/places/place.dart';
import 'package:ucms/model/position.dart';
import 'package:ucms/model/position_list.dart';
import 'package:ucms/utils/convert_utf8.dart';
import 'package:ucms/domains/place/place_repository.dart';

class PlaceController extends GetxController {
  final repository = PlaceRepository();

  RxList<PositionList> positions = RxList();

  @override
  onInit() {
    super.onInit();

    positionAllInfo().then((_) {
      print("========== PlaceController positionAllInfo Done ==========");
    });
  }

  Future<List<Doom>> doomAllInfo() async {
    final jsonList = await repository.doomAll();
    List<Doom> doomList = [];

    for (Map<String, dynamic> json in jsonList) {
      doomList.add(Doom.fromJson(json));
    }

    return doomList;
  }

  Future<Doom> doomInfo(int doomId) async {
    final json = await repository.doom(doomId);

    return Doom.fromJson(json);
  }

  Future<List<DoomFacility>> doomFacilAllInfo() async {
    final jsonList = await repository.doomFacilAll();
    List<DoomFacility> doomFacilList = [];

    for (Map<String, dynamic> json in jsonList) {
      doomFacilList.add(DoomFacility.fromJson(json));
    }

    return doomFacilList;
  }

  Future<DoomFacility> doomFacilInfo(int id) async {
    final json = await repository.doom(id);
    return DoomFacility.fromJson(json);
  }

  Future<List<DoomRoom>> doomRoomAllInfo() async {
    final jsonList = await repository.doomRoomAll();
    List<DoomRoom> doomRoomList = [];

    for (Map<String, dynamic> json in jsonList) {
      doomRoomList.add(DoomRoom.fromJson(json));
    }

    return doomRoomList;
  }

  Future<DoomRoom> doomRoomInfo(int id) async {
    final json = await repository.doomRoom(id);

    return DoomRoom.fromJson(json);
  }

  Future<List<OutsideFacility>> outsideFacilAllInfo() async {
    final jsonList = await repository.outsideFacilAll();

    List<OutsideFacility> outsideFacilList = [];

    for (Map<String, dynamic> json in jsonList) {
      outsideFacilList.add(OutsideFacility.fromJson(json));
    }
    return outsideFacilList;
  }

  Future<OutsideFacility> outsideFacilInfo(int id) async {
    final json = await repository.outsideFacil(id);

    return OutsideFacility.fromJson(json);
  }

  Future<void> positionAllInfo() async {
    // ?????? Position ???????????? ?????? ????????? PositionList ??? ??????,
    // ??? PositionList ??? list ??? ????????????.

    //1.?????? ???????????? ????????? Position ?????? ?????????.
    List<dynamic> temp = await repository.positionAll();
    List<Map<String, dynamic>> l = [];
    for (dynamic j in temp) {
      l.add(convertUtf8ToObject(j));
    }

    List<Position> pos = [];
    for (Map<String, dynamic> json in l) {
      pos.add(Position.fromJson(json));
    }
    //2. ?????? ????????? ?????? ????????????
    List<Place> avail = await allAvailablePlaces();

    //3. ?????? ????????? ????????? ?????? PositionList ?????????

    List<PositionList> list = [];
    for (Place p in avail) {
      list.add(PositionList(list: [], place: p));
    }

    //4. position ??? ??? ????????? ???????????? positionlist ??? list ??? ???????????????

    for (Position p in pos) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].place.name == p.name) {
          list[i].list.add(p);
          break;
        }
      }
    }
    //5. ????????? ?????? ??? ??????????

    // ????????? ???????????? 36??? ?????????~ ???????????????????????? TODO HERE
    // print(list.length);

    positions.value = list;
  }

  Future<Position> positionInfo(int id) async {
    final json = await repository.position(id);

    return Position.fromJson(json);
  }

  Future<List<Place>> allAvailablePlaces() async {
    List<Place> doom = await doomAllInfo();
    List<Place> doomRoom = await doomRoomAllInfo();
    List<Place> doomFacil = await doomFacilAllInfo();
    List<Place> outsideFacil = await outsideFacilAllInfo();

    List<Place> res = [];

    for (Place p in doom) {
      res.add(p);
    }
    for (Place p in doomRoom) {
      res.add(p);
    }
    for (Place p in doomFacil) {
      res.add(p);
    }
    for (Place p in outsideFacil) {
      res.add(p);
    }

    return res;
  }
}
