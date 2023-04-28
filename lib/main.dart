import 'dart:convert';
import 'dart:html';
import 'package:firebase_core/firebase_core.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:get/get.dart';
import 'package:nft_concierge/connected.dart';
import 'package:nft_concierge/setUtilView.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

late Client httpClient;
late Web3Client ethClient;
final FirebaseFirestore firestore = FirebaseFirestore.instance;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBy83_zcGXZ00xDJ_vMnTF8iuyJ85tfv3g",
      appId: "1:331191694934:web:e0d4663fcedb489db32df7",
      messagingSenderId: "331191694934",
      projectId: "nftconcierge-9f216",
    ),
  );
  // FirebaseAnalyticsを使用した何らかの処理

  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      GetMaterialApp(title: '', home: Home());
}

class HomeController extends GetxController {
  bool get isInOperatingChain => currentChain == OPERATING_CHAIN;

  bool get isConnected => Ethereum.isSupported && currentAddress.isNotEmpty;

  String currentAddress = '';

  int currentChain = -1;

  bool wcConnected = false;

  List<String> contractAddressList = [];
  List<ConciergeNFT> conciergeNFTList = [];

  final List<NFT> nfts = [];
  static const OPERATING_CHAIN = 137;

  final wc = WalletConnectProvider.polygon();
  double amount = 0;
  Web3Provider? web3wc;

  void connectProvider() async {
    if (Ethereum.isSupported) {
      final accs = await ethereum!.requestAccount();
      if (accs.isNotEmpty) {
        currentAddress = accs.first;
        currentChain = await ethereum!.getChainId();
      }
      update();
    }
  }

  void connectWC(BuildContext context) async {
    await wc.connect();
    if (wc.connected) {
      currentAddress = wc.accounts.first;
      currentChain = OPERATING_CHAIN;
      wcConnected = true;
      web3wc = Web3Provider.fromWalletConnect(wc);
    }
    update();
  }

  clear() {
    currentAddress = '';
    currentChain = -1;
    wcConnected = false;
    web3wc = null;

    update();
  }

  init() {
    start();
  }

  void start() {
    connectProvider();
    // if (Ethereum.isSupported) {
    //   connectProvider();
    //
    //   ethereum!.onAccountsChanged((accs) {
    //     clear();
    //   });
    //   });
    //
    //   ethereum!.onChainChanged((chain) {
    //     clear();
    //   });
    // }
  }

  @override
  void onInit() {
    Firebase.initializeApp(); // new
    getCcontractAddressList();
    init();
    super.onInit();
  }

  void getCcontractAddressList() async {
    print('getCcontractAddressList');
    final snapshot = await firestore
        .collection('Collections')
        .get();
    contractAddressList = snapshot.docs.map((doc) => doc.id).toList();
    List<ConciergeNFT> coList = [];
    for (var doc in snapshot.docs) {
      if (doc.id != 'CustomCollections') {
        var docID = doc.id;
        ConciergeNFT coItem = ConciergeNFT();
        coItem.address = doc.data()['address'];
        coItem.enable = doc.data()['enable'];
        coItem.contractAddress = doc.data()['contractAddress'];
        List<Utill> utillList = [];
        for (var action in  doc.data()['utilities']) {
          Utill utill = Utill();
          utill.action = action['action'];
          utill.actionType = action['actionType'];
          utill.desctiption = action['desctiption'];
          utillList.add(utill);
        }
        coItem.utilities = utillList;
        final metaResponse = await http.get(
            Uri.parse('$endpointGetNFTMetadata?contractAddress=$docID&tokenId=0'));
        if (metaResponse.statusCode == 200) {
          final nft = json.decode(metaResponse.body);
          var item = NFT();
          print(nft);
          item.created = nft['contractMetadata']['contractDeployer'];
          item.contractAddress = nft['contract']['address'];
          var tokenID = nft['id']['tokenId'];
          item.imageURL = (nft['media'][0]['raw']).contains('ipfs://') ? nft['media'][0]['raw'].replaceFirst('ipfs://', 'https://ipfs.io/ipfs/')
              : nft['media'][0]['raw'];
          if (nft['title'].length == 0) {
            item.title = nft['contractMetadata']['name'];
          } else {
            item.title = nft['title'];
          }
          if (nft['description'].length == 0) {
            item.description = nft['contractMetadata']['name'];
          } else {
            item.description = nft['description'];
          }
          coItem.nft = item;
          nfts.add(item);
        }
        coList.add(coItem);
      }
      conciergeNFTList = coList;
    }
    update();
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (h) => Scaffold(
        appBar: AppBar(
          title: Text('NFT Concierge'),
          actions: [
            h.wcConnected ? Icon(Icons.settings) :
            Container(
              child: TextButton( onPressed:() => h.connectWC(context), child: Text('ウォレット接続',
                style: TextStyle(
                  color: Colors.white,
                ),)),
            ),
          ],
        ),
        body: Center(
          child: Column(children: [
            Container(height: 10),
            h.conciergeNFTList.length >0 ? imageSLider(context, h.conciergeNFTList) : Container(),
            h.currentAddress.length == 0 ?
            Text('ウォレットに未接続です') :
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                    child: Text('ユーティリティNFT一覧へ'), onPressed: (){
                  Navigator.push(context, MaterialPageRoute(
                    // （2） 実際に表示するページ(ウィジェット)を指定する
                      builder: (context) =>NftList(
                        conciergeNFTList: h.conciergeNFTList,
                        address: h.currentAddress,
                        page: 0,
                        limit: 20,
                      )
                  )).then((value) {
                    // 再描画
                    h.getCcontractAddressList();
                  });
                }),
                OutlinedButton(
                    child: Text('ユーティリティ登録画面へ'), onPressed: (){
                  Navigator.push(context, MaterialPageRoute(
                    // （2） 実際に表示するページ(ウィジェット)を指定する
                      builder: (context) =>AddActionScreen(h.conciergeNFTList,h.currentAddress)
                  )).then((value) {
                    // 再描画
                    h.getCcontractAddressList();
                  });
                })
              ],
            ),
            Container(height: 30),
            if (h.wcConnected && h.wc.connected) ...[
              Text('接続中:${h.currentAddress}'),
            ],
          ]),
        ),
      ),
    );
  }

  final List<String> imageList = ["https://images.unsplash.com/photo-1520342868574-5fa3804e551c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=6ff92caffcdd63681a35134a6770ed3b&auto=format&fit=crop&w=1951&q=80",
    'https://images.unsplash.com/photo-1523205771623-e0faa4d2813d?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=89719a0d55dd05e2deae4120227e6efc&auto=format&fit=crop&w=1953&q=80',
    'https://images.unsplash.com/photo-1508704019882-f9cf40e475b4?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=8c6e5e3aba713b17aa1fe71ab4f0ae5b&auto=format&fit=crop&w=1352&q=80',
    'https://images.unsplash.com/photo-1519985176271-adb1088fa94c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=a0c8d632e977f94e5d312d9893258f59&auto=format&fit=crop&w=1355&q=80'];
   Widget imageSLider(BuildContext context, List<ConciergeNFT> nfts)  {
    return Container(
      margin: EdgeInsets.all(15),
      child: CarouselSlider.builder(
        itemCount: nfts.length,
        options: CarouselOptions(
          enlargeCenterPage: true,
          height: 300,
          autoPlay: true,
          autoPlayInterval: Duration(seconds: 3),
          reverse: false,
          aspectRatio: 5.0,
        ),
        itemBuilder: (context, i, id){
          //for onTap to redirect to another screen
          return GestureDetector(
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white,)
              ),
              //ClipRRect for image border radius
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  nfts[i].nft.imageURL,
                  width: 500,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            onTap: (){
              var url = nfts[i].nft.title;
              print(url.toString());
            },
          );
        },
      ),
    );
  }
}



