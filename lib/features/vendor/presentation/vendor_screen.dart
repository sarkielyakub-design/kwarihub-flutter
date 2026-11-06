import 'package:flutter/material.dart';
class VendorDashboardScreen extends StatelessWidget { const VendorDashboardScreen({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Vendor')),body:Center(child:Text('Vendor',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)))); }
