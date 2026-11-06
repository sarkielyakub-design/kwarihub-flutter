import 'package:flutter/material.dart';
class NotificationsScreen extends StatelessWidget { const NotificationsScreen({super.key}); @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Notifications')),body:Center(child:Text('Notifications',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)))); }
