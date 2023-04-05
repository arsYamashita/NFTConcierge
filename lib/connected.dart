import 'dart:convert';
import 'dart:js';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:nft_concierge/NFTDetail.dart';

const alchemyEndpoint = 'https://polygon-mainnet.g.alchemy.com/nft/v2/';
const apiKey = 'b08QhiZ6NvO4GZBQQtxcqPXn-eJQXpqk';
const endpointGetNFTs = '$alchemyEndpoint$apiKey/getNFTs/';
const endpointGetNFTMetadata = '$alchemyEndpoint$apiKey/getNFTMetadata/';
const endpointGetContractsForOwner = '$alchemyEndpoint$apiKey/getContractsForOwner/';
const endpointGetContractMetadata = '$alchemyEndpoint$apiKey/getContractMetadata/';

const nose360Address = '0x4539984a14cfc1854765dd81e4ef9aef6b7a5734';
const boboAddress    = '0xa0e19ad5f2cacecb010f4459f4d7b75bfb23e136';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

Future getContractMetadata(String contractAddress) async {
  final response = await http.get(Uri.parse('$endpointGetContractMetadata?contractAddress=$contractAddress'));
  if (response.statusCode == 200) {
    final jsonBody = json.decode(response.body);
    print(jsonBody);
  } else {
    throw Exception('Failed to load NFTs');
  }
}
class ConciergeNFT {
  late final String address;
  late final String contractAddress;
  late final bool enable;
  late final List<Utill> utilities;
  late final NFT nft;
}
class Utill {
  late final String action;
  late final String actionType;
  late final String desctiption;
}
class NFT {
  late final String title;
  late final String imageURL;
  late final String description;
  late final String created;
  late final String contractAddress;
}
class NftList extends StatelessWidget {
  final List<ConciergeNFT> conciergeNFTList;
  final String address;
  final int page;
  final int limit;

  NftList(
      {required this.conciergeNFTList,
        required this.address,
        this.page = 0,
        this.limit = 20});

  Future<List<ConciergeNFT>> getNFTs(String address,
      {int page = 0, int limit = 20}) async {
    final response = await http.get(Uri.parse('$endpointGetNFTs?owner=$address&excludeFilters=SPAM'));

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);

      final List<ConciergeNFT> nfts = [];
      for (var nft in jsonBody['ownedNfts']) {

        for (var conNFT in conciergeNFTList) {
          if (conNFT.contractAddress == nft['contract']['address']) {
            nfts.add(conNFT);
          }
        }
      }
      return nfts;
    } else {
      throw Exception('Failed to load NFTs');
    }
  }
  bool containConciergeNFT (NFT nft) {
    return conciergeNFTList.map((doc) => doc.contractAddress).toList().contains(nft.contractAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('NFT一覧'),
        ),
        body:FutureBuilder<List<dynamic>>(
            future: getNFTs(address, page: page, limit: limit),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return GridView.builder(
                  itemCount: snapshot.data!.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                  itemBuilder: (BuildContext context, int index) {
                    final ConciergeNFT nft = snapshot.data![index];
                    return ListItem(nft,context)!;
                  },
                );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return const CircularProgressIndicator();
            }));
  }

  Widget ListItem(ConciergeNFT nft, BuildContext context)  {
      return Container(
          child:CardItem(nft,context));
  }

  Widget CardItem(ConciergeNFT nft, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Image.network(
              nft.nft.imageURL,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              nft.nft.description,
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    // （2） 実際に表示するページ(ウィジェット)を指定する
                      builder: (context) =>NFTDetailWidget(nft)
                  ));
                },
                child: const Text('詳細へ'),
              ),
            ],
          ),
        ],
      ),
    )
    );
  }

  Widget DefaultsCardItem(ConciergeNFT nft, BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.arrow_drop_down_circle),
            title: Text(nft.nft.title),
            subtitle: Text(
              'Secondary Text',
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              nft.nft.description,
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {

                },
                child: const Text('詳細へ'),
              )
            ],
          ),
          Expanded(
            child: Image.network(
              nft.nft.imageURL,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}