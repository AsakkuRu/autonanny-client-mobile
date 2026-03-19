import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/direct_vm.dart';
import 'package:nanny_components/base_views/views/document_view.dart';
import 'package:nanny_components/base_views/views/video_view.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/widgets/message_send_panel.dart';
import 'package:nanny_core/models/from_api/chat_message.dart';
import 'package:nanny_core/nanny_core.dart';

class DirectView extends StatefulWidget {
  final int idChat;
  final String? name;

  const DirectView({super.key, required this.idChat, this.name});

  @override
  State<DirectView> createState() => _DirectViewState();
}

class _DirectViewState extends State<DirectView> {
  late DirectVM vm;
  static const double sideMargin = 100;
  static const double margin = 20;

  @override
  void initState() {
    super.initState();
    vm = DirectVM(context: context, update: setState, idChat: widget.idChat);

    vm.scrollController.addListener(() {
      if (vm.scrollController.position.pixels ==
              vm.scrollController.position.maxScrollExtent &&
          !vm.isLoadingMore &&
          vm.hasMoreMessages) {
        // Пользователь достиг верхней границы — подгружаем сообщения
        vm.loadMessages();
      }
    });
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf7f7f7),
      appBar: NannyAppBar(
        title: widget.name ?? "Чат",
        isTransparent: false,
        color: NannyTheme.secondary,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                vm.toggleEditingMode();
              });
            },
            icon: Icon(
              Icons.edit_rounded,
              color: vm.isEditingMode ? NannyTheme.primary : Colors.black,
            ),
            splashRadius: 30,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RequestLoader(
              request: vm.messagesRequest,
              completeView: (context, data) {
                vm.messages ??= data!.messages;

                return Stack(
                  children: [
                    ListView.separated(
                      controller: vm.scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shrinkWrap: true,
                      reverse: true,
                      itemCount: vm.messages!.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 20),
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () {
                          if (vm.isEditingMode) {
                            vm.startEditingMessage(vm.messages![index]);
                          }
                        },
                        child: directPanel(
                          vm.messages![index],
                        ),
                      ),
                    ),
                    if (vm.isLoadingMore)
                      const Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: NannyTheme.primary),
                        ),
                      ),
                  ],
                );
              },
              errorView: (context, error) => ErrorView(
                errorText: error.toString(),
              ),
            ),
          ),
          NannyBottomSheet(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
              child: MessageSendPanel(
                  onPressed: vm.sendTextMessage,
                  onAttachmentPressed: vm.attachImage,
                  controller: vm.textController),
            ),
          ),
        ],
      ),
    );
  }

  Widget directPanel(ChatMessage message) {
    return Stack(
      alignment: message.isMe ? Alignment.bottomRight : Alignment.bottomLeft,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: message.isMe ? sideMargin : margin + 3.5,
            right: message.isMe ? margin + 3.5 : sideMargin,
            bottom: 8.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
          decoration: BoxDecoration(
            color: message.isMe ? NannyTheme.primary : NannyTheme.lightGreen,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 5),
                blurRadius: 7,
                color: const Color(0xFF171170).withOpacity(.11),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: decideMessageContent(message),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${message.edited ? '(ред.) ' : ''} ${DateFormat("HH:mm").format(
                      DateTime.fromMillisecondsSinceEpoch(
                        (message.timestampSend * 1000).toInt(),
                      ),
                    )}',
                    style: TextStyle(
                        color: message.isMe
                            ? NannyTheme.secondary
                            : const Color(0xFF2B2B2B),
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Nunito'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget decideMessageContent(ChatMessage message) {
    const double messageFontSize = 16;
    var textStyle = TextStyle(
        color: message.isMe ? NannyTheme.secondary : const Color(0xFF2B2B2B),
        fontSize: messageFontSize,
        height: 1.35,
        fontWeight: FontWeight.w400,
        fontFamily: 'Nunito');

    if (message.msg.split('.').last == "gif") message.msgType = 2;

    return switch (message.msgType) {
      1 => Text(message.msg, style: textStyle),
      2 => GestureDetector(
          onTap: () => _openImageView(message.msg),
          child: NetImage(
            radius: 20,
            url: message.msg,
            fitToShortest: false,
          ),
        ),
      3 => GestureDetector(
          onTap: () => vm.navigateToView(VideoView(url: message.msg)),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: NannyTheme.onSecondary),
            child: const Center(
                child: Icon(
              Icons.play_circle_outline_rounded,
              color: NannyTheme.secondary,
              size: 50,
            )),
          ),
        ),
      4 => TextButton(
          onPressed: () => _openPdfFile(message.msg),
          child: Text(message.msg.split('/').last,
              style: textStyle.copyWith(decoration: TextDecoration.underline)),
        ),
      _ => const Placeholder()
    };
  }

  void _openImageView(String url) {
    showDialog(
      context: context,
      builder: (dContext) => Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
              maxScale: 5,
              child: NetImage(
                url: url,
                fitToShortest: false,
              )),
          Align(
            alignment: Alignment.topRight,
            child: Material(
              borderRadius:
                  const BorderRadius.only(bottomLeft: Radius.circular(20)),
              child: IconButton(
                  onPressed: () => Navigator.pop(dContext),
                  icon: const Icon(Icons.close)),
            ),
          ),
        ],
      ),
    );
  }

  void _openPdfFile(String url) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => DocumentView(url: url)));
  }
}
