import 'package:flutter/material.dart';
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});
  final String title; final String? action; final VoidCallback? onAction;
  @override Widget build(BuildContext context) => Row(children:[Expanded(child:Text(title,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800))), if(action!=null) TextButton(onPressed:onAction,child:Text(action!))]);
}
