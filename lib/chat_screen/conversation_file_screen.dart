import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:chat/chat_screen/by_time_search_list.dart';
import 'package:chat/chat_ui/conditional/conditional.dart';
import 'package:chat/connection/http_connection.dart';
import 'package:chat/chat_screen/by_sender_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chat/data_model/chat_message.dart' as c;
import 'package:chat/data_model/room.dart' as r;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ConversationFileScreen extends StatefulWidget {
  final c.ChatMessage? chatMessage;
  final r.Rooms roomData;
  const ConversationFileScreen(
      {Key? key, required this.roomData, this.chatMessage})
      : super(key: key);
  @override
  _ConversationFileScreenState createState() => _ConversationFileScreenState();
}

class _ConversationFileScreenState extends State<ConversationFileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late FocusNode _searchNode;
  bool _isImageViewVisible = false;
  String? imageViewed;
  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
    _searchNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AutoSizeText(
          // 'File, images, link are sent',
          'Images are sent',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: InkWell(
          child: Icon(Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back,
              color: Colors.black),
          onTap: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),
      body: _isImageViewVisible
          ? _imageGalleryBuilder()
          : SafeArea(
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSearchChip('Search',
                              const Icon(Icons.search, color: Colors.black),
                              () {
                            _showBottomDialog();
                          }),
                          _buildSearchChip('By sender',
                              const Icon(Icons.people, color: Colors.black),
                              () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => BySenderResultScreen(
                                      roomData: widget.roomData,
                                      chatMessage: widget.chatMessage,
                                    )));
                          }),
                          _buildSearchChip(
                              'By time',
                              const Icon(Icons.timer, color: Colors.black),
                              () {
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ByTimeResultScreen(
                                        roomData: widget.roomData,
                                        chatMessage: widget.chatMessage,
                                      )));
                              }),
                        ],
                      ),
                    ),
                  ),
                  // : CustomSearchTextField(_searchNode, _searchController, "Tìm ảnh, bộ sưu tạp, files, links"),
                  Container(
                    height: 3.0,
                    color: const Color(0xFFE5E5E5),
                  ),
                  TabBar(
                      unselectedLabelColor: Colors.grey,
                      labelColor: Colors.black,
                      tabs: const [
                        Tab(
                          text: 'IMAGE',
                        ),
                        Tab(
                          text: 'FILE',
                        ),
                        Tab(
                          text: 'LINK',
                        )
                      ],
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorColor: Colors.black),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _images(),
                        Container(),
                        Container(),
                      ],
                      controller: _tabController,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchChip(String label, Icon icon, Function function) {
    return InkWell(
      child: Chip(
        labelPadding: const EdgeInsets.all(2.0),
        avatar: icon,
        label: AutoSizeText(
          '  $label',
          style: const TextStyle(
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFFE5E5E5),
        elevation: 6.0,
        shadowColor: Colors.grey[60],
        padding: const EdgeInsets.all(8.0),
      ),
      onTap: () => function(),
    );
  }

  Widget _images() {
    return GridView.builder(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: widget.chatMessage?.room?.images?.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 4),
        itemBuilder: (BuildContext context, int position) {
          return InkWell(
            onTap: () {
              setState(() {
                _isImageViewVisible = true;
                imageViewed =
                    '${HTTPConnection.domain}api/images/${widget.chatMessage?.room?.images?[position].content}/512';
              });
            },
            child: CachedNetworkImage(
              imageUrl:
                  '${HTTPConnection.domain}api/images/${widget.chatMessage?.room?.images?[position].content}/512',
              placeholder: (context, url) => const CupertinoActivityIndicator(),
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          );
        });
  }

  Widget _imageGalleryBuilder() {
    return imageViewed != null
        ? Dismissible(
            key: const Key('photo_view_gallery'),
            direction: DismissDirection.down,
            onDismissed: (direction) => _onCloseGalleryPressed(),
            child: Stack(
              children: [
                PhotoViewGallery.builder(
                  builder: (BuildContext context, int index) =>
                      PhotoViewGalleryPageOptions(
                    imageProvider: Conditional().getProvider(imageViewed!),
                  ),
                  itemCount: 1,
                  loadingBuilder: (context, event) =>
                      _imageGalleryLoadingBuilder(context, event),
                  onPageChanged: _onPageChanged,
                  pageController: PageController(initialPage: 0),
                  scrollPhysics: const ClampingScrollPhysics(),
                ),
                Positioned(
                  right: 16,
                  top: 56,
                  child: CloseButton(
                    color: Colors.white,
                    onPressed: _onCloseGalleryPressed,
                  ),
                ),
              ],
            ),
          )
        : Container();
  }

  void _onCloseGalleryPressed() {
    try {
      setState(() {
        _isImageViewVisible = false;
      });
    } catch (_) {}
  }

  void _onPageChanged(int index) {
    setState(() {});
  }

  Widget _imageGalleryLoadingBuilder(
    BuildContext context,
    ImageChunkEvent? event,
  ) {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          value: event == null || event.expectedTotalBytes == null
              ? 0
              : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
        ),
      ),
    );
  }

  Widget searchOptionItem(String title, int type , {bool dateType = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(!dateType) Container(
            margin: const EdgeInsets.only(left: 16.0, right: 16.0),
            height: 15.0,
            width: 15.0,
            child: type == 1
                ? Icon(
                    Icons.people,
                    color: Colors.grey.shade500,
                  )
                : (type == 2
                    ? Icon(
                        Icons.access_alarm,
                        color: Colors.grey.shade500,
                      )
                    : Icon(
                        Icons.video_call_outlined,
                        color: Colors.grey.shade500,
                      )),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left:dateType ? 15.0 : 0.0),
                  child: Text(
                    title,
                    style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade400),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 16.0),
                  height: 1,
                  color: Colors.grey.shade200,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  int searchType = 0;
  _showBottomDialog() {
    showModalBottomSheet(
        context: context,
        isDismissible: true,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (BuildContext bc) {
          return StatefulBuilder(
              builder: (BuildContext cxtx, StateSetter setState) {
            return Column(
              children: [
                Container(
                  height: MediaQuery.of(context).viewPadding.top,
                  color: Colors.white,
                ),
                Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              width: double.infinity,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(10),
                                  borderRadius: BorderRadius.circular(5)),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Center(
                                      child: Icon(
                                        Icons.search,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                      child: TextField(
                                    focusNode: _searchNode,
                                    controller: _searchController,
                                    onChanged: (_) {},
                                    decoration: const InputDecoration.collapsed(
                                      hintText: 'Find images, files, links',
                                    ),
                                  )),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(5),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Center(
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        _searchController.text = '';
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )),
                          InkWell(
                              onTap: () {
                                    if(searchType == 1) {
                                      setState(() {
                                        searchType = 0;
                                      });
                                    }
                                    else {
                                      Navigator.of(context).pop();
                                    }
                              } ,
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey.shade500),
                                ),
                              ))
                        ],
                      ),
                      if (searchType == 0)
                        InkWell(
                            onTap: () {
                              String text = _searchController.value.text;
                              Navigator.of(context).pop();
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => BySenderResultScreen(
                                        roomData: widget.roomData,
                                        chatMessage: widget.chatMessage,
                                        search: text,
                                      )));
                              _searchController.text = '';
                              searchType = 0;
                            },
                            child: searchOptionItem("By sender", 1)),
                      if (searchType == 0)
                        InkWell(
                            onTap: () {
                              setState(() {
                                searchType = 1;
                              });
                            },
                            child: searchOptionItem("By time", 2)),
                      if (searchType == 1) InkWell(
                        onTap: () {
                          final format2 = DateFormat("dd/MM/yyyy");
                          String formattedDate = format2.format(DateTime.now().toUtc().add(const Duration(hours: 7)));
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ByTimeResultScreen(
                                roomData: widget.roomData,
                                chatMessage: widget.chatMessage,
                                search: formattedDate,
                                title: 'Today',
                              )));
                          _searchController.text = '';
                          searchType = 0;
                        },
                          child: searchOptionItem("Today", 4, dateType: true)),
                      if (searchType == 1) InkWell(
                          onTap: () {
                            final format2 = DateFormat("dd/MM/yyyy");
                            String formattedDate = format2.format(DateTime.now().toUtc().add(const Duration(hours: 7)).subtract(const Duration(days: 1)));
                            Navigator.of(context).pop();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ByTimeResultScreen(
                                  roomData: widget.roomData,
                                  chatMessage: widget.chatMessage,
                                  search: formattedDate,
                                  title: 'Yesterday',
                                )));
                            _searchController.text = '';
                            searchType = 0;
                          },child: searchOptionItem("Yesterday", 4, dateType: true)),
                      if (searchType == 1) InkWell(
                          onTap: () {
                            final format2 = DateFormat("dd/MM/yyyy");
                            DateTime thisWeekFirstDay = firstDateOfTheThisWeek(DateTime.now());
                            DateTime thisWeekLastDay = lastDateOfTheThisWeek(thisWeekFirstDay);
                            String formattedDate1 = format2.format(thisWeekFirstDay.toUtc().add(const Duration(hours: 7)));
                            String formattedDate2 = format2.format(thisWeekLastDay.toUtc().add(const Duration(hours: 7)));
                            Navigator.of(context).pop();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ByTimeResultScreen(
                                  roomData: widget.roomData,
                                  chatMessage: widget.chatMessage,
                                  search: '$formattedDate1-$formattedDate2',
                                  title: 'This week',
                                )));
                            _searchController.text = '';
                            searchType = 0;
                          },child: searchOptionItem("This week", 4, dateType: true)),
                      if (searchType == 1) InkWell(
                          onTap: () {
                            final format2 = DateFormat("dd/MM/yyyy");
                            DateTime lastWeekFirstDay = firstDateOfTheThisWeek(DateTime.now().subtract(const Duration(days: 7)));
                            DateTime lastWeekLastDay = lastDateOfTheThisWeek(lastWeekFirstDay);
                            String formattedDate1 = format2.format(lastWeekFirstDay.toUtc().add(const Duration(hours: 7)));
                            String formattedDate2 = format2.format(lastWeekLastDay.toUtc().add(const Duration(hours: 7)));
                            Navigator.of(context).pop();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ByTimeResultScreen(
                                  roomData: widget.roomData,
                                  chatMessage: widget.chatMessage,
                                  search: '$formattedDate1-$formattedDate2',
                                  title: 'Last week',
                                )));
                            _searchController.text = '';
                            searchType = 0;
                          },child: searchOptionItem("Last week", 4, dateType: true)),
                      if (searchType == 1) InkWell(
                          onTap: () {
                            final format2 = DateFormat("dd/MM/yyyy");
                            DateTime firstDayOfMonth = firstDayCurrentMonth(DateTime.now());
                            DateTime lastDayOfMonth = lastDayCurrentMonth(DateTime.now());
                            String formattedDate1 = format2.format(firstDayOfMonth.toUtc().add(const Duration(hours: 7)));
                            String formattedDate2 = format2.format(lastDayOfMonth.toUtc().add(const Duration(hours: 7)));
                            Navigator.of(context).pop();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ByTimeResultScreen(
                                  roomData: widget.roomData,
                                  chatMessage: widget.chatMessage,
                                  search: '$formattedDate1-$formattedDate2',
                                  title: 'This month',
                                )));
                            _searchController.text = '';
                            searchType = 0;
                          },child: searchOptionItem("This month", 4, dateType: true)),
                      if (searchType == 1) InkWell(
                          onTap: () {
                            final format2 = DateFormat("dd/MM/yyyy");
                            DateTime firstDayOfMonth = firstDayLastMonth(DateTime.now());
                            DateTime lastDayOfMonth = lastDayLastMonth(DateTime.now());
                            String formattedDate1 = format2.format(firstDayOfMonth.toUtc().add(const Duration(hours: 7)));
                            String formattedDate2 = format2.format(lastDayOfMonth.toUtc().add(const Duration(hours: 7)));
                            Navigator.of(context).pop();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ByTimeResultScreen(
                                  roomData: widget.roomData,
                                  chatMessage: widget.chatMessage,
                                  search: '$formattedDate1-$formattedDate2',
                                  title: 'Last month',
                                )));
                            _searchController.text = '';
                            searchType = 0;
                          },child: searchOptionItem("Last month", 4, dateType: true)),
                    ],
                  ),
                ),
                Container(
                  height: 20.0,
                  color: Colors.white,
                ),
                Expanded(child: InkWell(
                  onTap: () {
                    _searchController.text = '';
                    searchType = 0;
                    Navigator.of(context).pop();
                  },
                ))
              ],
            );
          });
        });
  }
  DateTime firstDateOfTheThisWeek(DateTime dateTime) {
    return dateTime.subtract(Duration(days: dateTime.weekday - 1));
  }
  DateTime lastDateOfTheThisWeek(DateTime dateTime) {
    return dateTime.add(Duration(days: DateTime.daysPerWeek - dateTime.weekday));
  }
  DateTime firstDayCurrentMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, 1);
  }
  DateTime lastDayCurrentMonth(DateTime dateTime) {
    return DateTime(dateTime.year,dateTime.month+1,).subtract(const Duration(days: 1));
  }
  DateTime firstDayLastMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month-1, 1);
  }
  DateTime lastDayLastMonth(DateTime dateTime) {
    return DateTime(dateTime.year,dateTime.month,1).subtract(const Duration(days: 1));
  }
}