
import 'package:flutter/material.dart';

class CommonLineView extends StatelessWidget {
  const CommonLineView({super.key});


  Widget _buildLine(){
    return Container(height: 0.8, margin: EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.grey[200]));
  }
  
  @override
  Widget build(BuildContext context) {
    return _buildLine();
  }
  
}