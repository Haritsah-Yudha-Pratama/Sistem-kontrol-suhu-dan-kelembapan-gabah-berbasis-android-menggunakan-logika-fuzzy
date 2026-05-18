import 'package:contra_app/service/firebase_service.dart';
import 'package:contra_app/views/drying_page.dart';
import 'package:contra_app/views/storage_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    
    super.initState();
    getHomepage().then((value){
      if(value == 'storage'){
        SchedulerBinding.instance.addPostFrameCallback((_){
          Navigator.push(context, MaterialPageRoute(builder: (context) => const StoragePage(fromDrying: false)));
        });
      }else if(value == 'drying'){
        SchedulerBinding.instance.addPostFrameCallback((_){
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DryingPage(fromStorage: false)));
        });
      }
    });
  }

  @override
  void dispose(){
    super.dispose();
  }


  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 235, 235),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: 
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 4),
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))
                  )
                ),
                onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (context) => const StoragePage(fromDrying: false,)));}, 
                child: 
                const Text("Storage Mode", style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700,color: Colors.white, fontSize: 18),)
              ),
              const SizedBox(height: 10),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 4),
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))
                  )
                ),
                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context) => const DryingPage(fromStorage: false)));}, 
                child: const Text("Drying Mode", style: TextStyle(fontFamily: 'Montserrat',   fontWeight: FontWeight.w700,color: Colors.white, fontSize: 18),)
              )
          ])
        ),
      ),
    );
  }
}