import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat/chat_ui/conditional/conditional.dart';
import 'package:chat/connection/http_connection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chat/data_model/chat_message.dart' as c;
import 'package:chat/data_model/room.dart' as r;
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ByTimeResultScreen extends StatefulWidget {
  final c.ChatMessage? chatMessage;
  final r.Rooms roomData;
  final String? search;
  final String? title;
  const ByTimeResultScreen({Key? key, required this.roomData, required this.chatMessage, this.search, this.title}) : super(key: key);
  @override
  _State createState() => _State();
}

class _State extends State<ByTimeResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isImageViewVisible = false;
  String? imageViewed;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AutoSizeText(
          widget.title ?? 'By Time',
          style: const TextStyle(
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
      body:  _isImageViewVisible
          ? _imageGalleryBuilder()
          : SafeArea(
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 20.0),
              child: Wrap(
                children: _list(),
              ),
            )
          ],
        ),
      ),
    );
  }
  List<Widget> _list() {
    Map<String,List<Widget>> values = {};
    List<String> keys = [];
    final format1 = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z");
    final format2 = DateFormat("dd/MM/yyyy");
    widget.chatMessage?.room?.images?.forEach((e) {
      final dt = format1.parse(e.date!, true);
      String formattedDate = format2.format(dt);
      if(widget.search != null && widget.search != '') {
        if(widget.search!.contains('-')) {
          List<String> listDates = widget.search!.split('-');
          if(listDates.length >= 2) {
            if (dt.isBetween(format2.parse(listDates[0]), format2.parse(listDates[1]))) {
              if(values.containsKey(formattedDate)) {
                values[formattedDate]!.add(widgetCacheImage(e.content!));
              }
              else {
                values[formattedDate] = [];
                values[formattedDate]!.add(widgetCacheImage(e.content!));
                keys.add(formattedDate);
              }
            }
          }
        }
        else {
          if(formattedDate == widget.search) {
            if(values.containsKey(formattedDate)) {
              values[formattedDate]!.add(widgetCacheImage(e.content!));
            }
            else {
              values[formattedDate] = [];
              values[formattedDate]!.add(widgetCacheImage(e.content!));
              keys.add(formattedDate);
            }
          }
        }
      }
      else {
        if(values.containsKey(formattedDate)) {
          values[formattedDate]!.add(widgetCacheImage(e.content!));
        }
        else {
          values[formattedDate] = [];
          values[formattedDate]!.add(widgetCacheImage(e.content!));
          keys.add(formattedDate);
        }
      }
    });
    List<Widget> widgets = [];
    for (var element in keys) {
      final dt = format2.parse(element, true);
      widgets.add(
        Row(
          children: [
            Expanded(child: Padding(
              padding: const EdgeInsets.only(left: 10.0,bottom: 15.0,top: 10.0),
              child: Text(
                dt.isToday() ? 'Today' : dt.isYesterday() ? 'Yesterday' :
                element,
                style: const TextStyle(fontWeight: FontWeight.w600),),
            ))
          ],
        )
      );
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Wrap(
          spacing: 5.0,
          children: values[element]!,),
      ));
      widgets.add(Container(height: 15.0,));
    }
    return widgets;
  }

  Widget widgetCacheImage(String content) {
    return InkWell(
      onTap: () {
        setState(() {
          _isImageViewVisible = true;
          imageViewed =
          '${HTTPConnection.domain}api/images/$content/256';
        });
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.3,
        height: MediaQuery.of(context).size.width * 0.3,
        child: CachedNetworkImage(
          imageUrl:
          '${HTTPConnection.domain}api/images/$content/256',
          fit: BoxFit.cover,
          placeholder: (context, url) => const CupertinoActivityIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
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
    try{
      setState(() {
        _isImageViewVisible = false;
      });
    }catch(_) {}
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
}

extension DateTimeExtension on DateTime? {
  bool? isAfterOrEqualTo(DateTime dateTime) {
    final date = this;
    if (date != null) {
      final isAtSameMomentAs = dateTime.isAtSameMomentAs(date);
      return isAtSameMomentAs | date.isAfter(dateTime);
    }
    return null;
  }
  bool? isBeforeOrEqualTo(DateTime dateTime) {
    final date = this;
    if (date != null) {
      final isAtSameMomentAs = dateTime.isAtSameMomentAs(date);
      return isAtSameMomentAs | date.isBefore(dateTime);
    }
    return null;
  }
  bool isBetween(
      DateTime fromDateTime,
      DateTime toDateTime,
      ) {
    final date = this;
    if (date != null) {
      final isAfter = date.isAfterOrEqualTo(fromDateTime) ?? false;
      final isBefore = date.isBeforeOrEqualTo(toDateTime) ?? false;
      return isAfter && isBefore;
    }
    return false;
  }
}