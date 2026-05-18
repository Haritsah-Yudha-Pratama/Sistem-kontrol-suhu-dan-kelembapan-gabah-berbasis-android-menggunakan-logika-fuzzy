import 'package:contra_app/views/storage_page.dart';
import 'package:flutter/material.dart';
import 'package:contra_app/service/firebase_service.dart';
import 'package:firebase_database/firebase_database.dart';

class DryingPage extends StatefulWidget {
  const DryingPage({super.key, required this.fromStorage});
  final bool? fromStorage;

  @override
  State<DryingPage> createState() => DryingPageState();
}

class DryingPageState extends State<DryingPage> {

  String? _humidityValue;
  String? _temperatureValue;
  
  FirebaseDatabase database = FirebaseDatabase.instance ;

  @override
  void initState() {
    super.initState();
    setMode("drying");
    _dataListener();
  }


  void _dataListener(){
    DatabaseReference ref = FirebaseDatabase.instance.ref('/data');

    ref.onValue.listen((DatabaseEvent event){
      final datasnapshot = event.snapshot.value;
      Map<dynamic, dynamic> dataValue = datasnapshot as Map<dynamic, dynamic>;
      if(mounted){
        setState(() {
        _humidityValue = dataValue['hum'].toString();
        _temperatureValue = dataValue['temp'].toString();
      });
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(elevation: 4,
        shadowColor: Colors.black,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: (){
            if(widget.fromStorage == true){
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                Navigator.pop(context);
              }}, 
          icon: const Icon(Icons.arrow_back, 
          color: Colors.blue,)),
        title: const Text('Drying', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700,color: Colors.blue, fontSize: 24),),
        centerTitle: true,),
      backgroundColor: const Color.fromARGB(255, 235, 235, 235),
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              const Text("Temperature & Humidity", style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700,color: Colors.blue, fontSize: 24)),
              const SizedBox(height: 4),
              const Text("At this page, you can monitor how is the temperature and humidity of the storage", style: TextStyle(fontFamily: 'Montserrat',color: Colors.black87, fontSize: 14)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Temperature", style: TextStyle(fontFamily: 'Montserrat',color: Colors.black87, fontSize: 16)),
                              Text("🌡️", style: TextStyle(fontSize: 20))
                            ],
                          ),
                          const SizedBox(height:20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("$_temperatureValue", style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 50, color: Colors.blue)),
                              const Text("°C",  style: TextStyle(fontFamily: 'Montserrat', fontSize: 18,color: Colors.blue))
                              ]
                            )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Humidity", style: TextStyle(fontFamily: 'Montserrat',color: Colors.black87, fontSize: 16)),
                              Text("💧", style: TextStyle(fontSize: 20))
                            ],
                          ),
                          const SizedBox(height:20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("$_humidityValue", style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 50, color: Colors.blue)),
                              const SizedBox(width: 10),
                              const Text("%",  style: TextStyle(fontFamily: 'Montserrat', fontSize: 18,color: Colors.blue))
                              ]
                            )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Go to storage mode ?', style: TextStyle(fontFamily: 'Montserrat',color: Colors.black87, fontSize: 14),),
                      const SizedBox(width: 10),
                      ElevatedButton(style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)
                        ) ,
                        backgroundColor: Colors.blue
                      ),onPressed: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const StoragePage(fromDrying: true)));
                      }, child: const Text("Go Storage Mode", style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)))
                    ],
                  ),
                )
            ]),
        ),
      ),
    );
  }
}