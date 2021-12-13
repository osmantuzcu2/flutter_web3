import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'package:get/get.dart';
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';
import 'package:flutter_awesome_buttons/flutter_awesome_buttons.dart';

import 'abi.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      GetMaterialApp(title: 'NFT Mint Web Site with Flutter', home: Home());
}

class HomeController extends GetxController {
  bool get isInOperatingChain => currentChain == OPERATING_CHAIN;

  bool get isConnected => Ethereum.isSupported && currentAddress.isNotEmpty;

  String currentAddress = '';

  int currentChain = -1;

  bool wcConnected = false;

  static const OPERATING_CHAIN = 3;

  final wc = WalletConnectProvider.binance();

  Web3Provider? web3wc;

  connectProvider() async {
    if (Ethereum.isSupported) {
      final accs = await ethereum!.requestAccount();
      if (accs.isNotEmpty) {
        currentAddress = accs.first;
        currentChain = await ethereum!.getChainId();
      }

      update();
    }
  }

  clear() {
    currentAddress = '';
    currentChain = -1;
    wcConnected = false;
    web3wc = null;

    update();
  }

  init() {
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

  String nftContractAddress = '0x56Fb0412E8d8E2916AB14a35F87c4732780aD379';

  getSymbol() async {
    final busd = Contract(
      nftContractAddress,
      CONTRACT_ABI,
      provider!,
    );
    String symbol = await busd.call<String>('symbol');
    print(symbol);
    Get.snackbar("Token Symbol", symbol);
  }

  mintNFT() async {
    var contract = DeployedContract(
        ContractAbi.fromJson(CONTRACT_ABI, nftContractAddress),
        EthereumAddress.fromHex(nftContractAddress));

    var data =
        hex.encode(contract.function("mint").encodeCall([BigInt.from(1)]));

    final tx = await provider!.getSigner().sendTransaction(
          TransactionRequest(
              to: '0x56Fb0412E8d8E2916AB14a35F87c4732780aD379',
              data: "0x" + data,
              value: BigInt.from(10000000000000000),
              gasLimit: BigInt.from(3000000)),
        );

    final receipt = await tx.wait();
    Get.snackbar("Recipt", receipt.blockHash);
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
        body: Stack(
          children: [
            Image.asset("assets/back.jpg"),
            Container(
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 10),
                      Builder(builder: (_) {
                        var shown = '';
                        if (h.isConnected && h.isInOperatingChain)
                          shown =
                              "Your Address : " + h.currentAddress.toString();
                        else if (h.isConnected && !h.isInOperatingChain)
                          shown = 'Wrong chain! Please connect to Ropsten. (3)';
                        else if (Ethereum.isSupported)
                          return OutlinedButton(
                              child: Text('Connect'),
                              onPressed: h.connectProvider);
                        else
                          shown = 'Your browser is not supported!';

                        return Text(shown,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12));
                      }),
                      Container(height: 30),
                      if (h.isConnected && h.isInOperatingChain) ...[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: PrimaryButton(
                              title: "Mint", onPressed: h.mintNFT),
                        ),
                      ],
                      Container(height: 30),
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
