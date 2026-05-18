import 'package:contra_app/service/firebase_service.dart';
import 'package:contra_app/views/drying_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key, required this.fromDrying});

  final bool? fromDrying;

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  
  String? _fanValue;
  String? _heaterValue;
  int? _days;
  int? _hours;
  int? _minutes;
  FirebaseDatabase database = FirebaseDatabase.instance;

  @override
  void initState(){
    super.initState();
    setMode('storage');
    _dataListener();
  }

  @override
  void dispose(){
    super.dispose();
  }

  void _dataListener(){
    DatabaseReference duration = FirebaseDatabase.instance.ref('/duration');
    DatabaseReference refFan = FirebaseDatabase.instance.ref('/defuzzy');
    // DatabaseReference refHeater = FirebaseDatabase.instance.ref('/defuzzy/fan');

    duration.onValue.listen((DatabaseEvent event){
      final durationSnapshot = event.snapshot.value;
      Map<dynamic, dynamic> durationValue = durationSnapshot as Map<dynamic, dynamic>;
      if(mounted){
        setState(() {
          _days = durationValue['days'];
          _hours = durationValue['hours'];
          _minutes = durationValue['minutes'];
        });
      }
    });

    refFan.onValue.listen((DatabaseEvent event){
      final datasnapshot = event.snapshot.value;
      Map<dynamic, dynamic> dataValue = datasnapshot as Map<dynamic, dynamic>;
      if(mounted){
        setState(() {
        _fanValue = dataValue['fan'];
        _fanValue = _fanValue?.substring(6);
        _heaterValue = dataValue['heater'];
        _heaterValue = _heaterValue?.substring(7);
      });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 235),
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black,
        backgroundColor: Colors.white,
        leading: IconButton(onPressed: (){
           if(widget.fromDrying == true){
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                Navigator.pop(context);
              }
        }, 
        icon: const Icon(Icons.arrow_back, color: Colors.blue,)),
        title: const Text('Storage', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700,color: Colors.blue, fontSize: 24),),
        centerTitle: true,
        ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Storage Time 🕛', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700,color: Colors.blue, fontSize: 24)),
            const Text('The Grain has been stored for :', style: TextStyle(fontFamily: 'Montserrat',color: Colors.black87, fontSize: 18)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 23.0, vertical: 18),
                      child: Column(
                        children: [
                          Text('$_days', style: const TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.w700,color: Colors.blue, fontSize: 30),
                          ),
                          const Text('Days', style: TextStyle(fontFamily: 'Montserrat',color: Colors.black87, fontSize: 16),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child:  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 23.0, vertical: 18),
                      child: Column(
                        children: 
                        [
                          Text( '$_hours', style: const TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.w700,color: Colors.blue, fontSize: 30),
                          ),
                          const Text('Hours', style: TextStyle(fontFamily: 'Montserrat',color: Colors.black87, fontSize: 16),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
                      child: Column(
                        children: [
                          Text('$_minutes', style: const TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.w700,color: Colors.blue, fontSize: 30),
                          ),
                          const Text('Minutes', style: TextStyle(fontFamily: 'Montserrat',color: Colors.black87, fontSize: 16),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text('Devices Status ⚡', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700,color: Colors.blue, fontSize: 24)),
            const SizedBox(height: 12),
            Column(
                children: [
                  Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fan Speed', style: TextStyle(fontFamily: 'Montserrat',color: Colors.black87, fontSize: 16)),
                        Row(
                          children: [
                            Text('$_fanValue', style: const TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.w700,color: Colors.blue, fontSize: 16),),                          
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Heater Status', style: TextStyle(fontFamily: 'Montserrat',color: Colors.black87, fontSize: 16)),
                        Row(
                          children: [
                            Text('$_heaterValue', style: const TextStyle(fontFamily: 'Montserrat',fontWeight: FontWeight.w700,color: Colors.blue, fontSize: 16),),                          
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Go to drying mode ?', style: TextStyle(fontFamily: 'Montserrat',color: Colors.black87, fontSize: 14),),
                      const SizedBox(width: 10),
                      ElevatedButton(style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)
                        ) ,
                        backgroundColor: Colors.blue
                      ),onPressed: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const DryingPage(fromStorage: true)));
                      }, child: const Text("Go Drying Mode", style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)))
                    ],
                  ),
                )
                ]
              ),
          ],
        ),
      ),
    );
  }
}