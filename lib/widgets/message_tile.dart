import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MessageTile extends StatelessWidget {
  const MessageTile({super.key, required this.msg, required this.animation});
  final String msg;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final isItPatch = msg.contains("read");
    // msg.insert(0, "${timeStamp()}\t$text write");
    // String formattedStr = "${timeStamp()}\t$convertedStr read";
    List<String> splittedMsg = msg.split('\t');
    List<String> msgGot = splittedMsg[1].trimRight().split(" ");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: FadeTransition(
        opacity: animation, //점점진해지게
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0, //애니메이션이 아래쪽부터 올라오면서 글자 안잘림
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isItPatch? Colors.amberAccent : Colors.lightBlueAccent,
                child: isItPatch? const Text("MT") : const Text("ME"),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isItPatch?
                    const Text(
                      "MediLight Patch",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ): const Text(
                      "Me",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(msgGot[0]),
                    Text(splittedMsg[0]),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
