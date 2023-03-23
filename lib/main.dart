import 'dart:convert';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:get/get.dart';
import 'package:nft_concierge/connected.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;

late Client httpClient;
late Web3Client ethClient;
void main() {
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

    super.onInit();
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
                    child: Text('NFT一覧へ'), onPressed: (){
                  Navigator.push(context, MaterialPageRoute(
                    // （2） 実際に表示するページ(ウィジェット)を指定する
                      builder: (context) =>NftList(
                        contractAddress: '0xFe82688c1191cd23aEE864C5B3579df38B70742A',
                        address: h.currentAddress,
                        page: 0,
                        limit: 20,
                      )
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
}



