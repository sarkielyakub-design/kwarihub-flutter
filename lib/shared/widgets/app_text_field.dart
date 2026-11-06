import 'package:flutter/material.dart';
class AppTextField extends StatelessWidget {
  const AppTextField({super.key, required this.label, this.hint, this.controller, this.keyboardType, this.obscureText=false, this.prefixIcon});
  final String label; final String? hint; final TextEditingController? controller; final TextInputType? keyboardType; final bool obscureText; final IconData? prefixIcon;
  @override Widget build(BuildContext context) => TextField(controller:controller, keyboardType:keyboardType, obscureText:obscureText, decoration:InputDecoration(labelText:label, hintText:hint, prefixIcon:prefixIcon==null?null:Icon(prefixIcon)));
}
