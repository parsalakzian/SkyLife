import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:SkyLife/Model/CurrentCityDataModel.dart';
import 'package:SkyLife/Model/ForecastDaysModel.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:intl/intl.dart';
import 'package:restart_app/restart_app.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp()
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<CurrentCityDataModel> currentWeatherFuture;
  late StreamController<List<ForecastDaysModel>> streamForecastDays;
  TextEditingController textEditingController = TextEditingController();
  var cityname = "Karaj";


  @override
  void initState() {
    super.initState();

    currentWeatherFuture = sendRequestCurrentWeather(cityname);
    streamForecastDays = StreamController<List<ForecastDaysModel>>();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 12, 12, 12),
      appBar: AppBar(
        title: const Text("Sky Life" , style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
        backgroundColor: const Color.fromARGB(255, 51, 51, 51),
        elevation: 25,
        shadowColor: Colors.cyan.shade500,
        centerTitle: true,
        actions: <Widget>[
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context){
              return {'Setting' , 'Logout'}.map((String choice){
                return PopupMenuItem(
                  value: choice,
                  child: Text(choice)
                  );
              }).toList();
            }
            )
        ],
      ),
      body: FutureBuilder<CurrentCityDataModel>(
        future: currentWeatherFuture,
        builder: (context, snapshot) {
          if(snapshot.hasData){
            CurrentCityDataModel? cityDataModel = snapshot.data;
            sendRequest7DaysForecast(cityDataModel?.cityname);

            final formatter = DateFormat.jm();
            var sunrise = formatter.format(
              DateTime.fromMicrosecondsSinceEpoch(
                cityDataModel!.sunrise * 1000000,
                isUtc: false
              )
            );
            var sunset = formatter.format(
              DateTime.fromMicrosecondsSinceEpoch(
                cityDataModel.sunset * 1000000,
                isUtc: false
              )
            );

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              clipBehavior: Clip.antiAlias,              
              child: Container(
                color: const Color.fromARGB(255, 12, 12, 12),
                child: Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: ElevatedButton(
                                onPressed: (){
                                  setState(() {
                                    currentWeatherFuture = sendRequestCurrentWeather(textEditingController.text);
                                  });
                                }, child: const Text("Find")),
                            ),
                              Expanded(
                                child: TextField(
                                  controller: textEditingController ,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter a city name',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: UnderlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white24,
                                  ),
                              ))
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Text(cityDataModel.cityname , style: const TextStyle(color: Colors.white , fontSize: 35),),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(cityDataModel.description , style: const TextStyle(color: Colors.grey , fontSize: 20),),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Image(image: NetworkImage("https://openweathermap.org/img/wn/${cityDataModel.icon}@4x.png" , scale: 1.5)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: Text("${cityDataModel.temp}\u00B0", style: const TextStyle(color: Colors.white , fontSize: 60)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              const Text("Max",style: TextStyle(color: Colors.grey , fontSize: 20),),
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text("${cityDataModel.temp_max.round()}\u00B0",style: const TextStyle(color: Colors.white, fontSize: 20),),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 10 , right: 10),
                            child: Container(
                              width: 1,
                              height: 40,
                              color: Colors.white,
                            ),
                          ),
                          Column(
                            children: [
                              const Text("Min",style: TextStyle(color: Colors.grey , fontSize: 20),),
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text("${cityDataModel.temp_min.round()}\u00B0",style: const TextStyle(color: Colors.white, fontSize: 20),),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          color: Colors.grey,
                          height: 1,
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SizedBox(
                          width: double.infinity,
                          height: 120,
                          child: Center(
                            child: StreamBuilder<List<ForecastDaysModel>>(
                              stream: streamForecastDays.stream,
                              builder: (context, snapshot) {
                                if(snapshot.hasData){
                                  List<ForecastDaysModel>? foreCastDays = snapshot.data ;
            
                                  return ListView.builder(
                                            shrinkWrap: true,
                                            scrollDirection: Axis.horizontal,
                                            itemCount: 39,
                                            itemBuilder: (BuildContext context , int pos){
                                              return listViewItems(foreCastDays![pos + 1]);
                                            });
                                }else{
                                  return Container(
                                    color: const Color.fromARGB(255, 12, 12, 12),
                                    child: Center(
                                      child: JumpingDotsProgressIndicator(
                                        color: Colors.white,
                                        fontSize: 60,
                                        dotSpacing: 2,
                                      ),
                                    ),
                                  );
                                }
                              },
            
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          color: Colors.grey,
                          height: 1,
                          width: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                const Text("Wind Speed" , style: TextStyle(color: Colors.grey , fontSize: 15),),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text("${cityDataModel.windSpeed} m/s" , style: const TextStyle(color: Colors.white),),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10 , right: 10),
                              child: Container(
                                width: 1,
                                height: 40,
                                color: Colors.white,
                              ),
                            ),
                            Column(
                              children: [
                                const Text("Sunrise" , style: TextStyle(color: Colors.grey , fontSize: 15),),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(sunrise , style: const TextStyle(color: Colors.white),),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10 , right: 10),
                              child: Container(
                                width: 1,
                                height: 40,
                                color: Colors.white,
                              ),
                            ),
                            Column(
                              children: [
                                const Text("Sunset" , style: TextStyle(color: Colors.grey , fontSize: 15),),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(sunset , style: const TextStyle(color: Colors.white),),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10 , right: 10),
                              child: Container(
                                width: 1,
                                height: 40,
                                color: Colors.white,
                              ),
                            ),
                            Column(
                              children: [
                                const Text("Humidity" , style: TextStyle(color: Colors.grey , fontSize: 15),),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text("${cityDataModel.humidity} %" , style: const TextStyle(color: Colors.white),),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ),
            );
          }else{
            return Container(
              color: const Color.fromARGB(255, 12, 12, 12),
              child: Center(
                child: Column(
                  children: [
                    JumpingDotsProgressIndicator(
                      color: Colors.white,
                      fontSize: 60,
                      dotSpacing: 2,
                    ),
                    const Text('if loading to long in chang city : your city name is wrong to reset use this button' , style: TextStyle(color: Colors.white , fontSize: 20),textAlign: TextAlign.center,),
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: ElevatedButton(
                        onPressed: (){
                          setState(() {
                            //currentWeatherFuture = sendRequestCurrentWeather("Karaj");
                            Restart.restartApp();
                          });
                        }, child: const Text("Reset")),
                    ),
                  ],
                ),
              ),
            );
          }
        },


      ),
    );
  }


  SizedBox listViewItems(ForecastDaysModel foreCastDay){
    return SizedBox(
      width: 90,
      height: 120,
      child: Card(
        elevation: 1, shadowColor: Colors.grey,
        color: Colors.transparent,
        child: Column(
          children: [
            Text(foreCastDay.dataTime , style: const TextStyle(color: Colors.grey , fontSize: 15),),
            Text(foreCastDay.dth , style: const TextStyle(color: Colors.grey , fontSize: 12),),
            Image(image: NetworkImage("https://openweathermap.org/img/wn/${foreCastDay.icon}.png" , scale: 0.9)),
            Text("${foreCastDay.temp.round()}\u00B0" , style: const TextStyle(color: Colors.grey , fontSize: 20),),
                  
          ],
        ),
      ),
    );
  }


  Future<CurrentCityDataModel> sendRequestCurrentWeather(String cityname) async {
    var apikey = "73234f3df35ebf997e15f822521e092b";
    

    var response = await Dio().get("https://api.openweathermap.org/data/2.5/weather",
      queryParameters: {"q":cityname , "appid":apikey , "units":"metric"}
    );

    var datamodel = CurrentCityDataModel(response.data["name"], response.data["coord"]["lon"], response.data["coord"]["lat"], response.data["weather"][0]["main"], response.data["weather"][0]["description"], response.data["main"]["temp"], response.data["main"]["temp_min"], response.data["main"]["temp_max"], response.data["main"]["pressure"], response.data["main"]["humidity"], response.data["wind"]["speed"],response.data["dt"], response.data["sys"]["sunrise"], response.data["sys"]["sunset"], response.data["sys"]["country"] , response.data["weather"][0]["icon"]);



    //  if (kDebugMode) {
    //    print(datamodel.sunrise);
    //    print(datamodel.sunset);
    //  }
    
    return datamodel;

  }


  void sendRequest7DaysForecast(cityname) async{
    List<ForecastDaysModel> list =[];
    //var apikey = "73234f3df35ebf997e15f822521e092b";

    

    try{
      var response = await Dio().get("https://api.codebazan.ir/weather/",
        queryParameters: {"city":cityname }
      );

      

      final formatter = DateFormat.jm();

      for(int i = 0; i<40; i = i + 1){
        var model = response.data['list'][i];

        var dth = formatter.format(DateTime.fromMicrosecondsSinceEpoch(
          model['dt'] * 1000000,
          isUtc: true
        ));

        var dtm = DateFormat.MMMd().format(DateTime.fromMicrosecondsSinceEpoch(
          model['dt'] * 1000000,
          isUtc: true
        ));

        // if (kDebugMode) {
        //   print(dt.toString());
        // }

        ForecastDaysModel forecastDaysModel = ForecastDaysModel(model['weather'][0]['main'], model['weather'][0]['description'], model['main']['temp'], dtm , model["weather"][0]["icon"],dth);

        list.add(forecastDaysModel);
      } 

      streamForecastDays.add(list);
      

    }on DioException catch (e) {
      if (kDebugMode) {
        print(e);
      }
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('hi there')));
    }

  }
}