import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomSnackBar {
  static late BuildContext context;


  static Future showToast({bool isSuccess = true, required String msg , ToastGravity position = ToastGravity.BOTTOM}) async{
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: position,
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        textColor: Colors.white,
        fontSize: 15.0);
  }
}
