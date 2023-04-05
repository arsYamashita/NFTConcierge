import 'package:flutter/material.dart';
import 'connected.dart';
import 'dart:html' as html;

class NFTDetailWidget extends StatefulWidget {
  final ConciergeNFT nft;

  NFTDetailWidget(this.nft);

  @override
  _NFTDetailWidgetState createState() => _NFTDetailWidgetState();
}

class _NFTDetailWidgetState extends State<NFTDetailWidget> {
  Map<String, dynamic> _nftDetail = {};
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nft.nft.title),
      ),
      body:Contents()
    );
  }

  TextButton Creater() {
    return TextButton(
      onPressed:() {
        print(widget.nft.nft.created);
      },
      child: Text(widget.nft.nft.created),
    );
  }
  Widget DefaultsContents() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.network(widget.nft.nft.imageURL),
      SizedBox(height: 20),
      Text(
        widget.nft.nft.title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 10),
      Text(
        widget.nft.nft.description,
        style: TextStyle(fontSize: 16),
      ),
    ],
  );
  }
  Widget Contents(){
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.network(
            widget.nft.nft.imageURL,
            fit: BoxFit.cover,
            height: 200,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.nft.nft.title,
                  style: Theme.of(context).textTheme.headline6,
                ),
                SizedBox(height: 8),
                Text(
                  widget.nft.nft.description,
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                SizedBox(height: 8),
                Container(
                  alignment: Alignment.center,
                  child:  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          'Created by:'
                      ),
                      Creater()
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  children: widget.nft.utilities
                      .map((link) => ElevatedButton(
                    onPressed: () {
                      if (link.actionType == 'URL') {
                        html.window.open(link.action, '');
                      } else if (link.actionType == 'Text') {
                        print(link.action);
                      }
                    },
                    child: Text(link.desctiption),
                  ))
                      .toList(),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}