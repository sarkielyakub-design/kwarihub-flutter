import 'package:flutter/material.dart';
class WalletScreen extends StatelessWidget { const WalletScreen({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Wallet')),body:Center(child:Text('Wallet',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)))); }
