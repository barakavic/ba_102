import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:permission_handler/permission_handler.dart";

class SmsListenerService {
  static const platform = MethodChannel('com.example.ba_102_fe/sms');

  final Function(Map<String, dynamic>) onMessageReceived;

  SmsListenerService({required this.onMessageReceived});


  // Initialize Listener
  Future<void> initialize() async{
    final status = await Permission.sms.request();


    if (status.isGranted){
      platform.setMethodCallHandler(_handleMethodCall);
      print("SMS Listener initialized");

    }
    else{
      print("SMS Permission denied");
    }
  }

    Future<dynamic> _handleMethodCall(MethodCall call) async{
      if (call.method == 'onSmsReceived'){
        final Map<String, dynamic> smsData = Map<String, dynamic>.from(call.arguments);
        onMessageReceived(smsData);
      }
    }




    void dispose(){
      platform.setMethodCallHandler(null);
    }

  }

