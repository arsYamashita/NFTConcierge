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
    if (Ethereum.isSupported) {
      connectProvider();

      ethereum!.onAccountsChanged((accs) {
        clear();
      });

      ethereum!.onChainChanged((chain) {
        clear();
      });
    }
    getCcontractAddressList();
  }

  getLastestBlock() async {
    print(await provider!.getLastestBlock());
    print(await provider!.getLastestBlockWithTransaction());
  }

  testProvider() async {
    final rpcProvider = JsonRpcProvider('https://bsc-dataseed.binance.org/');
    print(rpcProvider);
    print(await rpcProvider.getNetwork());
  }

  test() async {}

  testSwitchChain() async {
    await ethereum!.walletSwitchChain(97, () async {
      await ethereum!.walletAddChain(
        chainId: 97,
        chainName: 'Binance Testnet',
        nativeCurrency:
        CurrencyParams(name: 'BNB', symbol: 'BNB', decimals: 18),
        rpcUrls: ['https://data-seed-prebsc-1-s1.binance.org:8545/'],
      );
    });
  }


  @override
  void onInit() {
    init();
    Firebase.initializeApp(); // new
    super.onInit();
  }

  void getCcontractAddressList() async {
    print('getCcontractAddressList');
    final snapshot = await firestore
        .collection('Collections')
        .get();
    var contractAddressList = snapshot.docs.map((doc) => doc.id).toList();
    print(contractAddressList);
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
            imageSLider(context),
            Builder(builder: (_) {
              var shown = '';
              if (h.isConnected && !h.isInOperatingChain)
                shown = 'Wrong chain! Please connect to Porigon.';
              return Text(shown,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20));
            }),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                h.currentAddress.length == 0 ?
                Text('ウォレットに未接続です') :
                OutlinedButton(
                    child: Text('ユーティリティNFT一覧へ'), onPressed: (){
                  Navigator.push(context, MaterialPageRoute(
                    // （2） 実際に表示するページ(ウィジェット)を指定する
                      builder: (context) =>NftList(
                        contractAddress: '0xFe82688c1191cd23aEE864C5B3579df38B70742A',
                        address: h.currentAddress,
                        page: 0,
                        limit: 20,
                      )
                  ));
                }),
                OutlinedButton(
                    child: Text('ユーティリティ登録画面へ'), onPressed: (){
                  Navigator.push(context, MaterialPageRoute(
                    // （2） 実際に表示するページ(ウィジェット)を指定する
                      builder: (context) =>AddActionScreen("",h.currentAddress)
                  ));
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
  Widget imageSLider(BuildContext context)  {
    return Container(
      margin: EdgeInsets.all(15),
      child: CarouselSlider.builder(
        itemCount: imageList.length,
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
                  imageList[i],
                  width: 500,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            onTap: (){
              var url = imageList[i];
              print(url.toString());
            },
          );
        },
      ),
    );
  }
}



