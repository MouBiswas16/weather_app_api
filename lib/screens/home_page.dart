// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_print, unnecessary_string_interpolations

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:jiffy/jiffy.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    position = await Geolocator.getCurrentPosition();
    getWeatherData();

    print(
        "My Latitude is ${position!.latitude} and Longitude is ${position!.longitude}");
  }

  Position? position;

  @override
  void initState() {
    determinePosition();
    super.initState();
  }

  Map<String, dynamic>? weatherMap;
  Map<String, dynamic>? forecastMap;

  getWeatherData() async {
    var weather = await http.get(Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?lat=${position!.latitude}&lon=${position!.longitude}&appid=1e7f678c58634c3f4766ed291ee4a114"));
    print("My Weather Data is : ${weather.body}");

    print("**********************************************************");

    var forecast = await http.get(Uri.parse(
        "https://api.openweathermap.org/data/2.5/forecast?lat=${position!.latitude}&lon=${position!.longitude}&appid=20b417354a35213f23b6030bd2e9908c"));
    print(forecast.body);

    var weatherData = jsonDecode(weather.body);
    var foreCastData = jsonDecode(forecast.body);

    // weatherMap = Map<String, dynamic>.from(jsonDecode(weather.body));
    // forecastMap = Map<String, dynamic>.from(jsonDecode(forecast.body));

    setState(() {
      weatherMap = Map<String, dynamic>.from(weatherData);
      forecastMap = Map<String, dynamic>.from(foreCastData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: weatherMap != null
          ? Scaffold(
              body: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Column(
                        children: [
                          Text(
                            "${Jiffy.parse('${DateTime.now()}').format(pattern: 'MMMM do yyyy')},${Jiffy.parse('${DateTime.now()}').format(pattern: 'h:mm:ss a')}",
                          ),
                          Text("${weatherMap!["name"]}"),
                        ],
                      ),
                    ),
                    Image.network(
                      "https://openweathermap.org/img/wn/${weatherMap!["weather"][0]["icon"]}@2x.png",
                    ),
                    Text("${weatherMap!["main"]["temp"]}°"),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        children: [
                          Text(
                              "Feels Like ${weatherMap!["main"]["feels_like"]}"),
                          Text("${weatherMap!["weather"][0]["description"]}"),
                        ],
                      ),
                    ),
                    Text(
                      "Humidity ${weatherMap!["main"]["humidity"]}, Pressure${weatherMap!["main"]["pressure"]}",
                    ),
                    Text(
                      "Sunrise ${Jiffy.parse("${DateTime.fromMicrosecondsSinceEpoch(weatherMap!["sys"]["sunrise"] * 1000)}").format(pattern: "hh mm a")}, Sunset ${Jiffy.parse("${DateTime.fromMicrosecondsSinceEpoch(weatherMap!["sys"]["sunset"] * 1000)}").format(pattern: "hh mm a")}",
                    ),
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: forecastMap!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              color: Colors.teal,
                              width: 150,
                              margin: EdgeInsets.only(right: 10),
                              child: Column(
                                children: [
                                  Text(
                                    "${Jiffy.parse("${forecastMap!["list"][index]["dt_txt"]}").format(pattern: 'MMM do yyyy')}",
                                  ),
                                  Image.network(
                                    "https://openweathermap.org/img/wn/${forecastMap!["list"][index]["weather"][0]["icon"]}@2x.png",
                                  ),
                                  Text(
                                    "${forecastMap!["list"][index]["main"]["temp_min"]}",
                                  ),
                                  Text(
                                      "${forecastMap!["list"][index]["weather"][0]["description"]},"),
                                ],
                              ),
                            );
                          }),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
