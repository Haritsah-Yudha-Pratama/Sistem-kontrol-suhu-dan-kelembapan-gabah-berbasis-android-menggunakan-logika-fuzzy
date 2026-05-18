import 'package:firebase_database/firebase_database.dart';


FirebaseDatabase database = FirebaseDatabase.instance ;

Future<String> getHomepage() async {
  DatabaseReference ref = database.ref('/serviceState');
  final page = await ref.get();
  if(page.exists){ 
    if (page.value.toString() == 'storage'){
    return "storage";
    } else if( page.value.toString() == 'drying'){
    return "drying";
    } else {
    return "standby";
    }
  } else {
    return "error";
  }
}

Future<void> setMode(String mode) async {
  DatabaseReference ref = database.ref('/serviceState');
  await ref.set(mode);
}

// Future<String> getValue(String path) async{
//   DatabaseReference valueRef = database.ref(path);
//   final _value = await valueRef.get();
//   return _value.value.toString();
// }


