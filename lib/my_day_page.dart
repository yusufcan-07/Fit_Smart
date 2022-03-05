import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:nutrition_project/firebase_helper_custom.dart';
import 'package:nutrition_project/myday_helper.dart';
import 'package:nutrition_project/search_food.dart';
import 'package:nutrition_project/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'history_page.dart';
import 'constants.dart';

import 'main.dart';

String placeHolderImageURL =
    "https://www.ipcc.ch/site/assets/uploads/sites/3/2019/10/img-placeholder.png";
enum Meal { breakfast, lunch, dinner }

var dailyCaloryAim = 20000;
var dailyCaloryConsumed = 0;

var dailyConsumedProtein = 80;
var dailyConsumedCarb = 60;
var dailyConsumedFat = 90;

var dailyProteinLimit = 120;
var dailyCarbLimit = 120;
var dailyFatLimit = 120;

bool secureMode = false;

var overConsumedColorGradient = [Colors.red, Colors.redAccent];
var normalConsumedColorGradient = [Colors.green, Colors.teal];
Color backgroundColor = Colors.black12;
var ccActiveCardColour = Color(0xFF323244);
var ccInactiveCardColour = Color(0xFF22263A);
var ccBottomContainerColour = Color(0xFFEB1555);
TextStyle CCFoodValueTextStyle =
    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20);

TextStyle CCMealTitleTextStyle =
    TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15);

class MyDay extends StatefulWidget {
  @override
  State<MyDay> createState() => _MyDayState();
}

class _MyDayState extends State<MyDay> with WidgetsBindingObserver {
  late EndDayResults endDayResults;

  late MealCard breakfast;
  late MealCard lunch;
  late MealCard dinner;

  void setData() {
    //Get data from the myday helper class
    List<Food> breakfastFoods = [];
    int breakfastTotalCalorie = 0;
    int breakfastTotalProtein = 0;
    int breakfastTotalCarb = 0;
    int breakfastTotalFat = 0;
    for (FoodData foodData in MyDayHelper.breakfast.foods) {
      breakfastFoods.add(Food(
          calory: foodData.calorie,
          protein: foodData.protein,
          carb: foodData.carb,
          fat: foodData.fat,
          imageURL: foodData.imageURL));
      breakfastTotalCalorie += foodData.calorie;
      breakfastTotalProtein += foodData.protein;
      breakfastTotalCarb += foodData.carb;
      breakfastTotalFat += foodData.fat;
    }
    breakfast = MealCard(
        foods: breakfastFoods,
        title: 'Breakfast',
        totalCal: breakfastTotalCalorie,
        totalPro: breakfastTotalProtein,
        totalCarb: breakfastTotalCarb,
        totalFat: breakfastTotalFat);
    List<Food> lunchFoods = [];
    int lunchTotalCalorie = 0;
    int lunchTotalProtein = 0;
    int lunchTotalCarb = 0;
    int lunchTotalFat = 0;
    for (FoodData foodData in MyDayHelper.lunch.foods) {
      lunchFoods.add(Food(
          calory: foodData.calorie,
          protein: foodData.protein,
          carb: foodData.carb,
          fat: foodData.fat,
          imageURL: foodData.imageURL));
      lunchTotalCalorie += foodData.calorie;
      lunchTotalProtein += foodData.protein;
      lunchTotalCarb += foodData.carb;
      lunchTotalFat += foodData.fat;
    }
    lunch = MealCard(
        foods: lunchFoods,
        title: 'Lunch',
        totalCal: lunchTotalCalorie,
        totalPro: lunchTotalProtein,
        totalCarb: lunchTotalCarb,
        totalFat: lunchTotalFat);
    List<Food> dinnerFoods = [];
    int dinnerTotalCalorie = 0;
    int dinnerTotalProtein = 0;
    int dinnerTotalCarb = 0;
    int dinnerTotalFat = 0;
    for (FoodData foodData in MyDayHelper.dinner.foods) {
      dinnerFoods.add(Food(
          calory: foodData.calorie,
          protein: foodData.protein,
          carb: foodData.carb,
          fat: foodData.fat,
          imageURL: foodData.imageURL));
      dinnerTotalCalorie += foodData.calorie;
      dinnerTotalProtein += foodData.protein;
      dinnerTotalCarb += foodData.carb;
      dinnerTotalFat += foodData.fat;
    }
    dinner = MealCard(
        foods: dinnerFoods,
        title: 'Dinner',
        totalCal: dinnerTotalCalorie,
        totalPro: dinnerTotalProtein,
        totalCarb: dinnerTotalCarb,
        totalFat: dinnerTotalFat);
    dailyCaloryConsumed =
        breakfastTotalCalorie + lunchTotalCalorie + dinnerTotalCalorie;
    dailyConsumedProtein =
        breakfastTotalProtein + lunchTotalProtein + dinnerTotalProtein;
    dailyConsumedCarb = breakfastTotalCarb + lunchTotalCarb + dinnerTotalCarb;
    dailyConsumedFat = breakfastTotalFat + lunchTotalFat + dinnerTotalFat;

    //Set Daily Values
  }

  void setCalorieProgress(int aim, int consumed) {
    dailyCaloryAim = aim;
    dailyCaloryConsumed = consumed;
  }

  void addCaloryToProgress(int amount) {
    dailyCaloryConsumed += amount;
  }

  final firestoreInstance = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  UserModel loggedInUser = UserModel();

  late FlutterLocalNotificationsPlugin fltrNotification;
  bool hasInternet = true;

  Future<void> InternetStatus() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        hasInternet = true;
      }
    } on SocketException catch (_) {
      hasInternet = false;
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    InternetStatus();
    super.initState();
    FirebaseFirestore.instance.collection("users").doc(user!.uid).get().then(
      (value) {
        loggedInUser = UserModel.fromMap(value.data());
        setState(() {});
      },
    );
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                color: Colors.blue,
                playSound: true,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      },
    );
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
    setData();
    return Scaffold(
      backgroundColor: ccInactiveCardColour,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.save),
          onPressed: () async {
            await InternetStatus();
            if (hasInternet == true) {
              flutterLocalNotificationsPlugin.show(
                0,
                "Fit & Smart",
                "Your daily consumption has been saved",
                NotificationDetails(
                  android: AndroidNotificationDetails(channel.id, channel.name,
                      channelDescription: channel.description,
                      importance: Importance.high,
                      color: Colors.blue,
                      playSound: true,
                      styleInformation: const BigPictureStyleInformation(
                        DrawableResourceAndroidBitmap("@mipmap/ic_launcher"),
                        largeIcon: DrawableResourceAndroidBitmap(
                            "@mipmap/ic_launcher"),
                        htmlFormatContent: true,
                        htmlFormatContentTitle: true,
                      ),
                      icon: '@mipmap/ic_launcher'),
                ),
              );
            } else {
              flutterLocalNotificationsPlugin.show(
                1,
                "Fit & Smart",
                "Couldn't save your data, No internet connection",
                NotificationDetails(
                  android: AndroidNotificationDetails(channel.id, channel.name,
                      channelDescription: channel.description,
                      importance: Importance.high,
                      color: Colors.blue,
                      playSound: true,
                      styleInformation: const BigPictureStyleInformation(
                        DrawableResourceAndroidBitmap("@mipmap/ic_launcher"),
                        largeIcon: DrawableResourceAndroidBitmap(
                            "@mipmap/ic_launcher"),
                        htmlFormatContent: true,
                        htmlFormatContentTitle: true,
                      ),
                      icon: '@mipmap/ic_launcher'),
                ),
              );
            }
            //Save the daily stats to firebase
            endDayResults = EndDayResults(
                calorie: dailyCaloryConsumed,
                protein: dailyConsumedProtein,
                carb: dailyConsumedCarb,
                fat: dailyConsumedFat);
            FireStore.userID = loggedInUser.uid;
            FireStore fireStore = FireStore("24.01.2022");
            fireStore.saveDaily(endDayResults);

            /*      print('end day calory: ${endDayResults.calorie}');
            print('end day protein: ${endDayResults.protein}');
            print('end day carb: ${endDayResults.carb}');
            print('end day fat: ${endDayResults.fat}');*/

            //Reset the  whole day
          },
        ),
        backgroundColor: ccInactiveCardColour,
        title: Text("MY Day"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
                flex: 18,
                child: Column(
                  children: [
                    SizedBox(
                      height: 5,
                    ),
                    //Summary
                    Expanded(
                      //daily consumption container
                      child: Container(
                        decoration: BoxDecoration(
                          color: ccActiveCardColour,
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.only(left: 8),
                              color: ccActiveCardColour,
                              child: DailyConsumptionProgress(),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: Container(
                                              width: 70,
                                              height: 20,
                                              child: Text(
                                                "Protein",
                                                style: CCFoodValueTextStyle
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.normal),
                                              )),
                                        ),
                                        Container(
                                          height: 30,
                                          width: 150,
                                          child: FAProgressBar(
                                            progressColor: Colors.green,
                                            backgroundColor: Colors.blueGrey,
                                            size: 8,
                                            currentValue: dailyConsumedProtein,
                                            maxValue: dailyProteinLimit,
                                            displayText: 'gr',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: Container(
                                              width: 70,
                                              height: 20,
                                              child: Text(
                                                "Carb",
                                                style: CCFoodValueTextStyle
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.normal),
                                              )),
                                        ),
                                        Container(
                                          height: 30,
                                          width: 150,
                                          child: FAProgressBar(
                                            progressColor: Colors.green,
                                            backgroundColor: Colors.blueGrey,
                                            size: 8,
                                            currentValue: dailyConsumedCarb,
                                            maxValue: dailyCarbLimit,
                                            displayText: 'gr',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: Container(
                                              width: 70,
                                              height: 20,
                                              child: Text(
                                                "Fat",
                                                style: CCFoodValueTextStyle
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.normal),
                                              )),
                                        ),
                                        Container(
                                          height: 30,
                                          width: 150,
                                          child: FAProgressBar(
                                            progressColor: Colors.green,
                                            backgroundColor: Colors.blueGrey,
                                            size: 8,
                                            currentValue: dailyConsumedFat,
                                            maxValue: dailyFatLimit,
                                            displayText: 'gr',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    //BREAKFAST
                    breakfast,
                    const SizedBox(
                      height: 5,
                    ),
                    //LUNCH
                    lunch,

                    const SizedBox(
                      height: 5,
                    ),
                    //DINNER
                    dinner,

                    const SizedBox(
                      height: 5,
                    ),
                  ],
                )),
            Align(
              alignment: Alignment.bottomCenter,
              child: Hero(
                tag: "bottom",
                child: ConvexAppBar.badge(
                  {},
                  initialActiveIndex: 1,
                  gradient: LinearGradient(colors: navigationBarColors),
                  badgeColor: Colors.purple,
                  items: const [
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
                        break;
                      case 2:
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyFood()),
                        );
                        break;
                      case 3:
                        await Navigator.push(
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
        ), //page main column
      ),
    );
  }
}

//--------------------------------CUSTOM WIDGETS------------------------------------

// CUSTOM PIE CHART WIDGETS
class DailyConsumptionProgress extends StatefulWidget {
  DailyConsumptionProgress();

  @override
  State<DailyConsumptionProgress> createState() =>
      _DailyConsumptionProgressState();
}

class _DailyConsumptionProgressState extends State<DailyConsumptionProgress> {
  String percentageModifier(double value) {
    return "/$dailyCaloryAim";
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SleekCircularSlider(
      initialValue: (dailyCaloryConsumed / dailyCaloryAim) * 100,
      appearance: CircularSliderAppearance(
          size: 130,
          customWidths: CustomSliderWidths(handlerSize: 0),
          infoProperties: InfoProperties(
              topLabelText: "$dailyCaloryConsumed kcal",
              modifier: percentageModifier,
              mainLabelStyle: TextStyle(color: Colors.white, fontSize: 17),
              topLabelStyle: TextStyle(color: Colors.white, fontSize: 20)),
          angleRange: 340,
          customColors: CustomSliderColors(
              trackColor: Colors.cyan,
              progressBarColors: dailyCaloryConsumed > (dailyCaloryAim * 0.8)
                  ? overConsumedColorGradient
                  : normalConsumedColorGradient)),
    );
  }
}

class MealCard extends StatelessWidget {
  late List<Food> foods;
  late String title;
  int totalCal = 0;
  int totalPro = 0;
  int totalCarb = 0;
  int totalFat = 0;

  MealCard(
      {required this.foods,
      required this.title,
      required this.totalCal,
      required this.totalPro,
      required this.totalCarb,
      required this.totalFat});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Flexible(
        flex: 1,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            decoration: BoxDecoration(
              color: ccActiveCardColour,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    "$title",
                    style: CCMealTitleTextStyle,
                  ),
                  flex: 1,
                ),
                Flexible(
                  child: Container(
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
                            child: Consumer(
                              builder:
                                  (BuildContext context, value, Widget? child) {
                                return ListView.builder(
                                  itemCount: foods.length,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return Container(
                                        child: Row(
                                      children: [foods[index]],
                                    ));
                                  },
                                );
                              },
                            ),
                          ),
                          flex: 7,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Flexible(
                          //Data here
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.0)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  flex: 10,
                                  child: Row(
                                    children: [
                                      Container(
                                          width: 25,
                                          child: Text(
                                            "Cal",
                                            style:
                                                CCFoodValueTextStyle.copyWith(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 15),
                                          )),
                                      Container(
                                        height: 20,
                                        width: 90,
                                        child: FAProgressBar(
                                          progressColor: Colors.green,
                                          backgroundColor: Colors.blueGrey,
                                          size: 8,
                                          currentValue: totalCal.toInt(),
                                          maxValue: 5000,
                                          displayText: 'kcal',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(flex: 1, child: Container()),
                                Flexible(
                                  flex: 10,
                                  child: Row(
                                    children: [
                                      Container(
                                          width: 25,
                                          child: Text(
                                            "Pro",
                                            style:
                                                CCFoodValueTextStyle.copyWith(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 15),
                                          )),
                                      Container(
                                        height: 20,
                                        width: 90,
                                        child: FAProgressBar(
                                          progressColor: Colors.green,
                                          backgroundColor: Colors.blueGrey,
                                          size: 8,
                                          currentValue: totalPro.toInt(),
                                          maxValue: 100,
                                          displayText: 'gr',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(flex: 1, child: Container()),
                                Flexible(
                                  flex: 10,
                                  child: Row(
                                    children: [
                                      Container(
                                          width: 25,
                                          child: Text(
                                            "Car",
                                            style:
                                                CCFoodValueTextStyle.copyWith(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 15),
                                          )),
                                      Container(
                                        height: 20,
                                        width: 90,
                                        child: FAProgressBar(
                                          progressColor: Colors.green,
                                          backgroundColor: Colors.blueGrey,
                                          size: 8,
                                          currentValue: totalCarb.toInt(),
                                          maxValue: 100,
                                          displayText: 'gr',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(flex: 1, child: Container()),
                                Flexible(
                                  flex: 10,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: 25,
                                          child: Text(
                                            "Fat",
                                            style:
                                                CCFoodValueTextStyle.copyWith(
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    fontSize: 15),
                                          )),
                                      SizedBox(
                                        height: 20,
                                        width: 90,
                                        child: FAProgressBar(
                                          progressColor: Colors.green,
                                          backgroundColor: Colors.blueGrey,
                                          size: 8,
                                          currentValue: totalFat.toInt(),
                                          maxValue: 100,
                                          displayText: 'gr',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  flex: 7,
                )
              ],
            ),
          ),
        ));
  }
}

class Food extends StatelessWidget {
  late int calory;
  late int protein;
  late int carb;
  late int fat;
  late String imageURL;

  Food(
      {required this.calory,
      required this.protein,
      required this.carb,
      required this.fat,
      required this.imageURL});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
        padding: EdgeInsets.all(2),
        child: Container(
          width: 150,
          decoration: BoxDecoration(
              color: Colors.green, borderRadius: BorderRadius.circular(15.0)),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Image.network(
                imageURL,
                height: 85,
                fit: BoxFit.fill,
              )),
        ));
  }
}
