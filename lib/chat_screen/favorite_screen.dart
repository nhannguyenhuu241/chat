import 'dart:io';
import 'package:chat/chat_screen/home_screen.dart';
import 'package:chat/chat_ui/vietnamese_text.dart';
import 'package:chat/connection/chat_connection.dart';
import 'package:chat/chat_screen/chat_screen.dart';
import 'package:chat/data_model/room.dart';
import 'package:chat/connection/http_connection.dart';
import 'package:chat/localization/app_localizations.dart';
import 'package:chat/localization/lang_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class FavoriteScreen extends StatefulWidget {
  final RefreshBuilder builder;
  final Function? homeCallback;
  const FavoriteScreen({Key? key, required this.builder, this.homeCallback}) : super(key: key);
  @override
  _FavoriteScreenScreenState createState() => _FavoriteScreenScreenState();
}

class _FavoriteScreenScreenState extends State<FavoriteScreen> with AutomaticKeepAliveClientMixin {

  final _focusSearch = FocusNode();
  final _controllerSearch = TextEditingController();

  Room? roomListVisible;
  Room? roomListData;
  bool isInitScreen = true;

  @override
  void initState() {
    super.initState();
    _getRooms();
  }
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  void _onRefresh() async{
    await Future.delayed(const Duration(milliseconds: 1000));
    await _getRooms();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async{
    await Future.delayed(const Duration(milliseconds: 1000));
    await _getRooms();
    _refreshController.loadComplete();
  }
  _getRooms() async {
    if(mounted) {
      roomListData = await ChatConnection.favoritesList();
      _getRoomVisible();
      isInitScreen = false;
      setState(() {});
    }
    else {
      WidgetsBinding.instance?.addPostFrameCallback((_) async {
        roomListData = await ChatConnection.favoritesList();
        _getRoomVisible();
        isInitScreen = false;
        setState(() {});
      });
    }
  }

  _getRoomVisible() {
    String val = _controllerSearch.value.text.toLowerCase().removeAccents();
    if(val != '') {
      roomListVisible!.rooms = roomListData!.rooms!.where((element) {
        try {
          People p = element.people!.firstWhere((e) => e.sId != ChatConnection.user!.id);
          if(!element.isGroup! ?
          ('${p.firstName} ${p.lastName}'.toLowerCase().removeAccents()).contains(val) : element.title!.toLowerCase().contains(val)) {
            return true;
          }
          return false;
        }catch(e){
          return false;
        }
      }).toList();
    }
    else {
      roomListVisible = Room();
      roomListVisible?.limit = roomListData?.limit;
      try{
        roomListVisible?.rooms = <Rooms>[...roomListData!.rooms!.toList()];
      }catch(_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    widget.builder.call(context, _getRooms);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 30.0,
                  margin: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 5.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.of(ChatConnection.buildContext).pop();
                        },
                        child: SizedBox(
                            width:30.0,
                            child: Icon(Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back, color: Colors.black)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3.0,left: 10.0,right: 10.0),
                  child: Text(AppLocalizations.text(LangKey.favorites),style: const TextStyle(fontSize: 25.0,color: Colors.black)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 10.0),
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE7EAEF), borderRadius: BorderRadius.circular(5)),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Center(
                            child: Icon(
                              Icons.search,
                            ),
                          ),
                        ),
                        Expanded(child: TextField(
                          focusNode: _focusSearch,
                          controller: _controllerSearch,
                          onChanged: (_) {
                            setState(() {
                              _getRoomVisible();
                            });
                          },
                          decoration: InputDecoration.collapsed(
                            hintText: AppLocalizations.text(LangKey.searchChats),
                          ),
                        )),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(5),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Center(
                                child: Icon(
                                  Icons.close,
                                ),
                              ),
                            ),
                            onTap: (){
                              _controllerSearch.text = '';
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() {
                                _getRoomVisible();
                              });
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            Expanded(
              child:
              isInitScreen ? Center(child: Platform.isAndroid ? const CircularProgressIndicator() : const CupertinoActivityIndicator()) :
              roomListVisible?.rooms != null ? SmartRefresher(
                enablePullDown: true,
                enablePullUp: false,
                controller: _refreshController,
                onRefresh: _onRefresh,
                onLoading: _onLoading,
                header: const WaterDropHeader(),
                child: ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: roomListVisible!.rooms?.length,
                    itemBuilder: (BuildContext context, int position) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: InkWell(
                            onTap: () async {
                              await Navigator.of(context,rootNavigator: true).push(
                                MaterialPageRoute(builder: (context) => ChatScreen(data: roomListVisible!.rooms![position]),settings:const RouteSettings(name: 'chat_screen')),
                              );
                              if(widget.homeCallback != null) {
                                widget.homeCallback!();
                              }
                              _getRooms();
                            },
                            child: _room(roomListVisible!.rooms![position], position == roomListVisible!.rooms!.length-1)),
                      );
                    }),
              ) : Container(),
            )
          ],),
        ),
      ),
    );
  }
  Widget _room(Rooms data, bool isLast) {
    People info = getPeople(data.people);
    String? author = findAuthor(data.people,data.lastMessage?.author);
    return Column(
      children: [
        SizedBox(
          child: SizedBox(
            height: 50.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  !data.isGroup! ? info.picture == null ? CircleAvatar(
                    radius: 25.0,
                    child: Text(
                        info.getAvatarName(),
                      style: const TextStyle(color: Colors.white),),
                  ) : CircleAvatar(
                    radius: 25.0,
                    backgroundImage:
                    CachedNetworkImageProvider('${HTTPConnection.domain}api/images/${info.picture!.shieldedID}/256'),
                    backgroundColor: Colors.transparent,
                  ) : data.picture == null ? CircleAvatar(
                    radius: 25.0,
                    child: Text(
                        data.getAvatarGroupName(),
                      style: const TextStyle(color: Colors.white),),
                  ) : CircleAvatar(
                    radius: 25.0,
                    backgroundImage:
                    CachedNetworkImageProvider('${HTTPConnection.domain}api/images/${data.picture!.shieldedID}/256'),
                    backgroundColor: Colors.transparent,
                  ),
                  Expanded(child: Container(
                    padding: const EdgeInsets.only(top: 5.0,bottom: 5.0,left: 10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Row(
                              children: [
                                Expanded(child: AutoSizeText(!data.isGroup! ?
                                '${info.firstName} ${info.lastName}' : data.title ?? '${AppLocalizations.text(LangKey.group)} ${info.firstName} ${info.lastName}',overflow: TextOverflow.ellipsis),),
                                AutoSizeText(data.lastMessage?.lastMessageDate() ?? '',style: const TextStyle(fontSize: 11,color: Colors.grey),)
                              ],
                            )
                        ),
                        Container(height: 5.0,),
                        Expanded(child: AutoSizeText(
                          '$author${(data.lastMessage?.type == 'image' ? AppLocalizations.text(LangKey.sentPicture) :
                          data.lastMessage?.type == 'file' ? AppLocalizations.text(LangKey.sendFile) :
                          data.lastMessage?.content ?? '')}',
                          overflow: TextOverflow.ellipsis,))
                      ],
                    ),
                  ))
                ],
              ),
            ),
          ),
        ),
        !isLast ? Container(height: 5.0,) : Container(),
        !isLast ?  Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Container(height: 1.0,color: Colors.grey.shade300,),
        ) : Container()
      ],
    );
  }
  People getPeople(List<People>? people) {
    return people!.first.sId != ChatConnection.user!.id ? people.first : people.last;
  }
  String? findAuthor(List<People>? people, String? author) {
    People? p;
    try {
      p = people?.firstWhere((element) => element.sId == author);
      return (p!.sId != ChatConnection.user!.id ? p.firstName : AppLocalizations.text(LangKey.you))! + ': ';
    }catch(_){
      return '';
    }
  }
  @override
  bool get wantKeepAlive => true;
}