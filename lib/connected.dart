import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const alchemyEndpoint = 'https://polygon-mainnet.g.alchemy.com/nft/v2/';
const apiKey = 'b08QhiZ6NvO4GZBQQtxcqPXn-eJQXpqk';
const endpoint = '$alchemyEndpoint$apiKey/getNFTs';

Future<List<dynamic>> getNFTs(String contractAddress, String address,
    {int page = 0, int limit = 20}) async {
  final response = await http.get(Uri.parse('$endpoint?owner=$address'));

  if (response.statusCode == 200) {
    final jsonBody = json.decode(response.body);

    for (var nft in jsonBody['ownedNfts']){
      print(nft['media'][0]['raw']);
      print(nft['media'][0]['thumbnail']);
      print(nft['metadata']['image']);
    }
    return jsonBody['ownedNfts'];
  } else {
    throw Exception('Failed to load NFTs');
  }
}

class NftList extends StatelessWidget {
  final String contractAddress;
  final String address;
  final int page;
  final int limit;

  NftList(
      {required this.contractAddress,
        required this.address,
        this.page = 0,
        this.limit = 20});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
        future: getNFTs(contractAddress, address, page: page, limit: limit),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return GridView.builder(
              itemCount: snapshot.data!.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              itemBuilder: (BuildContext context, int index) {
                final nft = snapshot.data![index];
                return Card(
                  child: Column(
                    children: <Widget>[
                      (nft['media'][0]['raw']).contains('ipfs://') ?
                      Image.network(nft['media'][0]['raw'].replaceFirst('ipfs://', 'https://ipfs.io/ipfs/')) : Image.network(nft['media'][0]['raw']),
                      Text(nft['title']),
                      Text(nft['description']),
                    ],
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return CircularProgressIndicator();
        });
  }
}
