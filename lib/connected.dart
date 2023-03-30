import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import "package:cloud_firestore/cloud_firestore.dart";

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

Future<List<NFT>> getNFTs(String contractAddress, String address,
    {int page = 0, int limit = 20}) async {
  final response = await http.get(Uri.parse('$endpointGetNFTs?owner=$address&excludeFilters=SPAM'));

  if (response.statusCode == 200) {
    final jsonBody = json.decode(response.body);

    final List<NFT> nfts = [];
    for (var nft in jsonBody['ownedNfts']) {
      var item = NFT();
      item.created = nft['contractMetadata']['contractDeployer'];
      var conAd = nft['contract']['address'];
      var tokenID = nft['id']['tokenId'];
      if (containConciergeNFT(item)) {
        //final metaResponse = await http.get(Uri.parse('$endpointGetNFTMetadata?contractAddress=$conAd&tokenId=$tokenID'));
        //final ownerResponse = await http.get(Uri.parse('$endpointGetContractsForOwner?owner=$address&pageSize=100&withMetadata=true'));
        //if (ownerResponse.statusCode == 200) {
          //final metaJsonBody = json.decode(ownerResponse.body);
          //print(metaJsonBody);
          item.imageURL = (nft['media'][0]['raw']).contains('ipfs://') ? nft['media'][0]['raw'].replaceFirst('ipfs://', 'https://ipfs.io/ipfs/')
              : nft['media'][0]['raw'];
          item.title = nft['title'];
          item.description = nft['description'];
          nfts.add(item);

          getContractMetadata(conAd);

        //}
      }
    }
    return nfts;
  } else {
    throw Exception('Failed to load NFTs');
  }
}

bool containConciergeNFT (NFT nft) {
  return nft.created == nose360Address || nft.created == boboAddress;
}
class NFT {
  late final String title;
  late final String imageURL;
  late final String description;
  late final String created;
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
    return Scaffold(
        appBar: AppBar(
          title: Text('NFT一覧'),
        ),
        body:FutureBuilder<List<dynamic>>(
            future: getNFTs(contractAddress, address, page: page, limit: limit),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return GridView.builder(
                  itemCount: snapshot.data!.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                  itemBuilder: (BuildContext context, int index) {
                    final NFT nft = snapshot.data![index];
                    return ListItem(context,nft)!;
                  },
                );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return const CircularProgressIndicator();
            }));
  }

  Widget ListItem(BuildContext context, NFT nft)  {
    if(nft.created == nose360Address || nft.created == boboAddress) {
      return GestureDetector(
          onTap: (){
            if(nft.created == nose360Address) {
              html.window.open('https://oncyber.io/nose360', '');
            }
            if(nft.created == boboAddress) {
              html.window.open('http://lin.ee/zik1Rt6', '');
            }
          },
          child:Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Image.network(
                    nft.imageURL,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nft.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        nft.description,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ));
    }else{
      return Container();
    }
  }
}