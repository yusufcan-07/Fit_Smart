import 'dart:convert';
import 'dart:ui';

import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_beautiful_popup/main.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:nutrition_project/myday_helper.dart';
import 'main.dart';
import 'settings_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:percent_indicator/percent_indicator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'constants.dart';
import 'history_page.dart';
import 'my_day_page.dart';

//Made by Serkan Biçer
final List<FoodInfo> foodList = [
  FoodInfo("Apple"),
  FoodInfo('Beef'),
  FoodInfo('Broccoli'),
  FoodInfo('Cookies'),
  FoodInfo('Tuna fish'),
  FoodInfo('Milk'),
  FoodInfo('Mushroom'),
  FoodInfo('Ham'),
  FoodInfo('Hummus'),
  FoodInfo('Asparagus'),
  FoodInfo('Beef brisket'),
  FoodInfo('Beef tenderloin'),
  FoodInfo('Beef ribs'),
  FoodInfo('Toasted bread'),
  FoodInfo('Bread'),
  FoodInfo('Breakfast bar'),
  FoodInfo('Cheeseburger'),
  FoodInfo('Chicken strips'),
  FoodInfo('Double cheeseburger'),
  FoodInfo('French fries'),
  FoodInfo('Hamburger'),
  FoodInfo('Onion rings'),
  FoodInfo('Vanilla shake'),
  FoodInfo('Burrito'),
  FoodInfo('Cake'),
  FoodInfo('Cheesecake'),
  FoodInfo('Jellybeans'),
  FoodInfo('Chocolate'),
  FoodInfo('White chocolate'),
  FoodInfo('Cherries'),
  FoodInfo('Roasted chicken breast'),
  FoodInfo('Chicken wings'),
  FoodInfo('Brownies'),
  FoodInfo('Macaroon cookies'),
  FoodInfo('Canned corn'),
  FoodInfo('Pancake'),
  FoodInfo('Pizza'),
  FoodInfo('Mac and cheese'),
  FoodInfo('Eggplant pickles'),
  FoodInfo('English muffin'),
  FoodInfo('Chicken sandwich'),
  FoodInfo('Nachos'),
  FoodInfo('Quesadilla'),
  FoodInfo('Roast beef sandwich'),
  FoodInfo('Submarine sandwich'),
  FoodInfo('Tuna salad'),
  FoodInfo('Frozen yogurt'),
  FoodInfo('Grapes'),
  FoodInfo('Ice cream'),
  FoodInfo('Biscuit'),
  FoodInfo('Pepperoni pizza'),
  FoodInfo('Roasted pork'),
];

Map<String, String> imageMaps = {};

int length = foodList.length;
var ContainerColor = Color(0xFF323244);
var _isInit = true;
var _isLoading = false;

late final popup;

class MyFood extends StatefulWidget {
  @override
  State<MyFood> createState() => _MySearchPage();
}

Future<void> setEveryProp(int i) async {
  await foodList[i].setProperties();
  await foodList[i].setImageForFood();
}

class _MySearchPage extends State<MyFood> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);

    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) return;

    final isBackground = state == AppLifecycleState.paused;

    if (isBackground) {
      await LocalAuthApi.authenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF323244),
        title: const Text('Search Foods'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: Column(
                children: [
                  Flexible(
                    flex: 8,
                    child: ListView.builder(
                      itemCount: foodList.length,
                      itemBuilder: (_, i) => FutureBuilder(
                          future: setEveryProp(i),
                          builder: (ctx, dataSnapshot) {
                            if (dataSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            } else {
                              return Column(
                                children: [
                                  foodList[i],
                                  Divider(),
                                ],
                              );
                            }
                          }),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Hero(
                      tag: "bottom",
                      child: ConvexAppBar.badge(
                        {},
                        initialActiveIndex: 2,
                        gradient: LinearGradient(colors: navigationBarColors),
                        badgeColor: Colors.purple,
                        items: [
                          TabItem(
                            icon: Icon(
                              Icons.history,
                              color: Colors.grey,
                              size: 26,
                            ),
                          ),
                          TabItem(
                            icon: Icons.home,
                          ),
                          TabItem(
                            icon: Icons.search,
                          ),
                          TabItem(
                            icon: Icons.person,
                          ),
                        ],
                        curveSize: 0,
                        onTap: (int i) async {
                          switch (i) {
                            case 0:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HistoryPage()),
                              );
                              break;
                            case 1:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MyDay()),
                              );
                              break;
                            case 2:
                              break;
                            case 3:
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SettingsPage()),
                              );
                              break;
                          }
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}

class FoodInfo extends StatelessWidget {
  late FoodData currFood;
  String foodName;
  late double carbs = 0;
  late double protein = 0;
  late double fat = 0;
  late double energy = 0;
  late String imageUrl = "";

  FoodInfo(this.foodName); // Future<void>> getData() async{
  //   setProperties();
  //   setImageForFood();
  //
  // }

  setProperties() async {
    //Food Data
    String? apikey = dotenv.env['FOODDATA_API'];
    //Yedek Anahtar "d0EqjBBQvpLPM1EfSJrekadYvfFzzHdWDpYZBGdx".

    try {
      Uri uri = await Uri.parse(
          "https://api.nal.usda.gov/fdc/v1/foods/search?query=$foodName&pageSize=2&api_key=$apikey");
      http.Response response = await http.get(uri) as http.Response;
      String data;
      var decodedData;
      if (response.statusCode == 200) {
        data = response.body;
        decodedData = jsonDecode(data);
        protein =
            decodedData["foods"][0]["foodNutrients"][0]["value"].toDouble();
        fat = decodedData["foods"][0]["foodNutrients"][1]["value"].toDouble();
        carbs = decodedData["foods"][0]["foodNutrients"][2]["value"].toDouble();
        energy =
            decodedData["foods"][0]["foodNutrients"][3]["value"].toDouble();
      } else {
        print("couldnt get the response from usda food api. Code: " +
            response.statusCode.toString());
      }
    } catch (error) {
      Uri uri = await Uri.parse(
          "http://api.nal.usda.gov/fdc/v1/foods/search?query=$foodName&pageSize=2&api_key=$apikey");
      http.Response response = await http.get(uri) as http.Response;
      String data;
      var decodedData;
      if (response.statusCode == 200) {
        data = response.body;
        decodedData = jsonDecode(data);
        protein =
            decodedData["foods"][0]["foodNutrients"][0]["value"].toDouble();
        fat = decodedData["foods"][0]["foodNutrients"][1]["value"].toDouble();
        carbs = decodedData["foods"][0]["foodNutrients"][2]["value"].toDouble();
        energy =
            decodedData["foods"][0]["foodNutrients"][3]["value"].toDouble();
      } else {
        print("couldnt get the response from usda food api. Code: " +
            response.statusCode.toString());
      }
    }
  }

  Future<void> setImageForFood() async {
    //Pixabay
    String? apikey = dotenv.env['IMAGE_API'];
    //Yedek Anahtar "25273848-ee71d21fc61d528765fdd1574",
    //              "25274200-4b961e2da5e27bd975e52cfca",
    //              "25274210-4c294e8b0bdbaeacf1482a4d0".

    try {
      Uri uri = await Uri.parse(
          "http://pixabay.com/api/?key=$apikey&q=$foodName&image_type=photo&pretty=true");
      http.Response response = await http.get(uri);
      String data;
      var decodedData;
      if (response.statusCode == 200) {
        data = response.body;
        decodedData = jsonDecode(data);
        imageUrl = decodedData["hits"][0]["previewURL"];
      } else {
        print("couldnt get the response from pixal api. Code: " +
            response.statusCode.toString());
      }
    } catch (e) {
      Uri uri = await Uri.parse(
          "https://pixabay.com/api/?key=$apikey&q=$foodName&image_type=photo&pretty=true");
      http.Response response = await http.get(uri);
      if (response == null) {
        return;
      }
      String data;
      var decodedData;
      if (response.statusCode == 200) {
        data = response.body;
        decodedData = jsonDecode(data);
        imageUrl = decodedData["hits"][0]["previewURL"];
      } else {
        print("couldnt get the response from pixal api. Code: " +
            response.statusCode.toString());
      }
    }
  }

  double getTotal() {
    return (carbs + protein + fat);
  }

  double getPortion(double nutritionType) {
    return (nutritionType / getTotal());
  }

  Future<dynamic> addClick(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: ContainerColor,
            content: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(const Radius.circular(65)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Add food to",
                        style: ccNormalWhite.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  primary: Color(0xff045b62),
                                  fixedSize: Size(80, 30)),
                              onPressed: () {
                                MyDayHelper.addBreakfast(currFood);
                              },
                              child: Text(
                                "Breakfast",
                                style: ccNormalWhite,
                              )),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    primary: Color(0xff045b62),
                                    fixedSize: Size(80, 30)),
                                onPressed: () {
                                  MyDayHelper.addLunch(currFood);
                                },
                                child: Text("Lunch", style: ccNormalWhite)),
                          ),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  primary: Color(0xff045b62),
                                  fixedSize: Size(80, 30)),
                              onPressed: () {
                                MyDayHelper.addDinner(currFood);
                              },
                              child: Text("Dinner", style: ccNormalWhite)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            color: ContainerColor,
            borderRadius: BorderRadius.all(const Radius.circular(25)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black,
                offset: Offset(1.0, 6.0),
                blurRadius: 40.0,
              ),
            ],
          ),
          height: 150,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 25, left: 10, right: 10),
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 45.0,
                      child: ClipRRect(
                        child: Image.network(
                          imageUrl,
                          height: 90,
                          width: 90,
                          fit: BoxFit.fill,
                        ),
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Container(
                      height: 30,
                      width: 70,
                      child: Text(foodName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 40, left: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircularPercentIndicator(
                      radius: 55.0,
                      lineWidth: 6.0,
                      percent: getPortion(fat),
                      center: const Text(
                        "Fat",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                            color: Colors.white),
                      ),
                      footer: Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text(
                          "$fat gram ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10.0,
                              color: Colors.white),
                        ),
                      ),
                      backgroundColor: Colors.yellowAccent,
                      progressColor: Colors.red,
                    ),
                    SizedBox(width: 12.5),
                    CircularPercentIndicator(
                      radius: 55.0,
                      animation: true,
                      animationDuration: 1200,
                      lineWidth: 6.0,
                      percent: getPortion(carbs),
                      center: const Text(
                        "Carb",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                            color: Colors.white),
                      ),
                      footer: Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text(
                          "$carbs gram ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10.0,
                              color: Colors.white),
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.butt,
                      backgroundColor: Colors.yellowAccent,
                      progressColor: Colors.blue,
                    ),
                    const SizedBox(width: 12.5),
                    CircularPercentIndicator(
                      radius: 55.0,
                      lineWidth: 6.0,
                      animation: true,
                      percent: getPortion(protein),
                      center: const Text(
                        "Protein",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                            color: Colors.white),
                      ),
                      footer: Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text(
                          "$protein gram ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10.0,
                              color: Colors.white),
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      backgroundColor: Colors.yellowAccent,
                      progressColor: Colors.lightGreen,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 7, left: 14, right: 10),
                      child: Column(
                        children: <Widget>[
                          IconButton(
                            onPressed: () async {
                              //open the popup for adding selecting the meal for adding the food
                              currFood = await FoodData(
                                  calorie: energy.toInt(),
                                  protein: protein.toInt(),
                                  carb: carbs.toInt(),
                                  fat: fat.toInt(),
                                  imageURL: imageUrl);
                              /* print("calorie: ${currFood.calorie}");
                            print("protein: ${currFood.protein}");
                            print("carb: ${currFood.carb}");
                            print("fat: ${currFood.fat}");
                            print("imageUrl: ${currFood.imageURL}");*/
                              addClick(context);
                            },
                            icon: Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            color: ContainerColor,
            borderRadius: BorderRadius.all(const Radius.circular(25)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black,
                offset: Offset(1.0, 6.0),
                blurRadius: 40.0,
              ),
            ],
          ),
          height: 150,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 25, left: 10, right: 10),
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 45.0,
                      child: ClipRRect(
                        child: Image.network(
                          imageUrl,
                          height: 90,
                          width: 90,
                          fit: BoxFit.fill,
                        ),
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Container(
                      height: 30,
                      width: 70,
                      child: Text(foodName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 40, left: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircularPercentIndicator(
                      radius: 55.0,
                      lineWidth: 6.0,
                      percent: getPortion(fat),
                      center: const Text(
                        "Fat",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                            color: Colors.white),
                      ),
                      footer: Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text(
                          "$fat gram ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10.0,
                              color: Colors.white),
                        ),
                      ),
                      backgroundColor: Colors.yellowAccent,
                      progressColor: Colors.red,
                    ),
                    SizedBox(width: 12.5),
                    CircularPercentIndicator(
                      radius: 55.0,
                      animation: true,
                      animationDuration: 1200,
                      lineWidth: 6.0,
                      percent: getPortion(carbs),
                      center: const Text(
                        "Carb",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                            color: Colors.white),
                      ),
                      footer: Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text(
                          "$carbs gram ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10.0,
                              color: Colors.white),
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.butt,
                      backgroundColor: Colors.yellowAccent,
                      progressColor: Colors.blue,
                    ),
                    const SizedBox(width: 5),
                    CircularPercentIndicator(
                      radius: 55.0,
                      lineWidth: 6.0,
                      animation: true,
                      percent: getPortion(protein),
                      center: const Text(
                        "Protein",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                            color: Colors.white),
                      ),
                      footer: Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text(
                          "$protein gram ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10.0,
                              color: Colors.white),
                        ),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      backgroundColor: Colors.yellowAccent,
                      progressColor: Colors.lightGreen,
                    ),
                    SizedBox(
                      width: 12.5,
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 7, left: 14, right: 10),
                      child: Column(
                        children: <Widget>[
                          IconButton(
                            onPressed: () async {
                              //open the popup for adding selecting the meal for adding the food
                              currFood = await FoodData(
                                  calorie: energy.toInt(),
                                  protein: protein.toInt(),
                                  carb: carbs.toInt(),
                                  fat: fat.toInt(),
                                  imageURL: imageUrl);
                              /* print("calorie: ${currFood.calorie}");
                            print("protein: ${currFood.protein}");
                            print("carb: ${currFood.carb}");
                            print("fat: ${currFood.fat}");
                            print("imageUrl: ${currFood.imageURL}");*/
                              addClick(context);
                            },
                            icon: Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
