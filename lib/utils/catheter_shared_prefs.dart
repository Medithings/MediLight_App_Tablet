import 'package:shared_preferences/shared_preferences.dart';

class CatheterSharedPrefs{
  late final SharedPreferences? _sharedPrefs;

  static final CatheterSharedPrefs _instance = CatheterSharedPrefs._internal();

  factory CatheterSharedPrefs() => _instance;
  CatheterSharedPrefs._internal();

  Future<void> init() async{
    _sharedPrefs = await SharedPreferences.getInstance();
  }

  bool get hasCatheter => _sharedPrefs?.containsKey("catheter") ?? false;
  bool get catheter => _sharedPrefs?.getBool("catheter") ?? false;
  int get totalC => _sharedPrefs?.getInt("totalC") ?? 0;
  int get initialC => _sharedPrefs?.getInt("initialC") ?? 0;
  int get per => _sharedPrefs?.getInt("per") ?? 0;
  int get initPer => _sharedPrefs?.getInt("initPer") ?? 0;
  String get endDate => _sharedPrefs?.getString("endDate") ?? "";
  String get savedDate => _sharedPrefs?.getString("savedDate") ?? "";

  set catheter(bool x) => _sharedPrefs?.setBool("catheter", x);
  set totalC(int x) => _sharedPrefs?.setInt("totalC", x);
  set initialC(int x) => _sharedPrefs?.setInt("initialC", x);
  set per(int x) => _sharedPrefs?.setInt("per", x);
  set initPer(int x) => _sharedPrefs?.setInt("initPer", x);
  set endDate(String x) => _sharedPrefs?.setString("endDate", x);
  set savedDate(String x) => _sharedPrefs?.setString("savedDate", x);

  void removeCatheterSP(){
    print("remove catheter");
    _sharedPrefs?.remove("catheter");
    _sharedPrefs?.remove("totalC");
    _sharedPrefs?.remove("initialC");
    _sharedPrefs?.remove("initPer");
    _sharedPrefs?.remove("per");
    _sharedPrefs?.remove("endDate");
    _sharedPrefs?.remove("savedDate");
  }
}