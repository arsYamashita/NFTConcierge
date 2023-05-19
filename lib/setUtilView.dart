import 'dart:convert';

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import 'package:http/http.dart' as http;
import 'connected.dart';
import 'dart:html' as html;

final FirebaseFirestore firestore = FirebaseFirestore.instance;

Future<List<String>> getActionTypes() async {
  final snapshot = await firestore
      .collection('actionTypes')
      .get();
  var list = snapshot.docs.map((doc) => doc.data()['actionTypes']).toList();
  final List<String> results = [];

  for (final snapshot in list) {
    for (final data in snapshot) {
      results.add(data);
    }
  }
  return results;
}

class AddActionScreen extends StatefulWidget {
  final List<ConciergeNFT> conciergeNFTList;
  final String address;
  AddActionScreen(this.conciergeNFTList,this.address);
  @override
  _AddActionScreenState createState() => _AddActionScreenState();
}
class _AddActionScreenState extends State<AddActionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _contractAddress = '';
  String _actionType = '';
  String _action = '';
  String _description = '';
  bool _isCreater = false;
  int utillCount = 0;
  late ConciergeNFT selectNFT;

  List<String> _actionTypes = [];
  @override
  void initState() {
    super.initState();
    _loadActionTypes();
  }
  Future isCreater(String contractAddress) async {
    final response = await http.get(Uri.parse('$endpointGetContractMetadata?contractAddress=$contractAddress'));
    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      final createrAddress = jsonBody['contractMetadata']['contractDeployer'];

      print(jsonBody);
      for (ConciergeNFT nft in widget.conciergeNFTList) {
        if (strComp(nft.contractAddress,contractAddress) && strComp(widget.address,createrAddress)) {
          setState(() {
            _isCreater = strComp(widget.address,createrAddress);
            utillCount = nft.utilities.length;
            selectNFT = nft;
            _contractAddress = nft.contractAddress;
          });
        }
      }
      setState(() {
        _isCreater = widget.address == createrAddress;
        _contractAddress = jsonBody['address'];
      });
    } else {
      setState(() {
        _isCreater = false;
      });
    }
  }

  Future<void> _loadActionTypes() async {
    final actionTypes = await getActionTypes();
    final list = actionTypes
        .map((actionType) => DropdownMenuItem<String>(
      value: actionType,
      child: Text(actionType),
    )).toList();
    setState(() {
      _actionTypes = actionTypes;
      _actionType = _actionTypes[0];
    });
  }

  Future<void> addContractAction(
      String contractAddress,
      String actionType,
      String action,
      String desctiption,
      String address,
      ) async {
    if (utillCount > 0) {
      List<Map<String, String>> utilities = [];
      for (Utill util in selectNFT.utilities) {
        utilities.add({'actionType': util.actionType,
          'action': util.action, 'desctiption': util.desctiption});
      }
      utilities.add({'actionType': actionType,
        'action': action, 'desctiption': desctiption});
      print(utilities);
      try {
        await firestore
            .collection('Collections')
            .doc(contractAddress).update(
            {
              'utilities': utilities,
            }
        );
      } catch (e) {
        print('登録失敗:$e');
      }
    } else {
      try {
        await firestore
            .collection('Collections')
            .doc(contractAddress).set(
            {
              'contractAddress': contractAddress,
              'enable': true,
              'utilities': [{'actionType': actionType,
                'action': action, 'desctiption': desctiption}
              ],
              'address': address}
        );
      } catch (e) {
        print('登録失敗:$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ユーティリティ登録'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'ContractAddress',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return '入力してください';
                }
                return null;
              },
              onChanged: (value) {
                isCreater(value);
              },
            ),
            _contractAddress.length == 0 ? Text('入力してください') :utillCount == 0 ? Text("ユーティリティは未登録です。") : Text("$utillCount件のユーティリティが登録されています。"),
            DropdownButtonFormField<String>(
              value: _actionType,
              decoration: const InputDecoration(
                labelText: 'Action Type',
              ),
              validator: (value) {
                if (value == null) {
                  return '選択してください';
                }
                return null;
              },
              items: _actionTypes
                  .map((actionType) => DropdownMenuItem<String>(
                value: actionType,
                child: Text(actionType),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _actionType = value ?? "";
                });
              },
            ),
            TextFormField(
              decoration: InputDecoration(
                hintText: _actionType == 'URL' ? 'Action' : 'タイトル',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return _actionType == 'URL' ? 'Actionを入力してください' : 'タイトルを入力してください';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _action = value;
                });
              },
            ),
            TextFormField(
              decoration: const InputDecoration(
                hintText: '説明',
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              validator: (value) {
                if (value!.isEmpty) {
                  return '説明を入力してください';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && _isCreater) {
                    await addContractAction(
                        _contractAddress,
                        _actionType,
                        _action,
                        _description,
                        widget.address
                    );
                    Navigator.pop(context);
                  }
                },
                child: _contractAddress.length == 0 ? Text('入力してください') : _isCreater ? Text('登録する') : Text('コントラクトアドレスが間違っています'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}