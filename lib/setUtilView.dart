import 'dart:convert';

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import 'package:http/http.dart' as http;
import 'connected.dart';
import 'dart:html' as html;

final FirebaseFirestore firestore = FirebaseFirestore.instance;

Future<void> addContractAction(
    String contractAddress,
    String actionType,
    String action,
    String desctiption,
    String address,
    ) async {
  try {
    await firestore
        .collection('Collections')
        .doc(contractAddress).set(
        {
          'contractAddress': contractAddress,
          'enable': true,
          'utilities': [{'actionType': actionType,
            'action': action, 'desctiption': desctiption}],
          'address': address}
    );
  } catch (e) {
    print('登録失敗:$e');
  }
}

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
  final String contractAddress;
  final String address;
  AddActionScreen(this.contractAddress,this.address);
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
      setState(() {
        _isCreater = widget.address == createrAddress;
        print(widget.address);
        print(createrAddress);
        print('_isCreater:$_isCreater');
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Action'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(
                hintText: 'ContractAddress',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter an action';
                }
                return null;
              },
              onChanged: (value) {
                isCreater(value);
                _contractAddress = value;
              },
            ),
            DropdownButtonFormField<String>(
              value: _actionType,
              decoration: InputDecoration(
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
                hintText: 'Action',
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Actionを入力してください';
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
              decoration: InputDecoration(
                hintText: '説明',
              ),
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
                  if (_formKey.currentState!.validate()) {
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
                child: _isCreater ? Text('登録する') : Text('コントラクトアドレスが間違っています'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}