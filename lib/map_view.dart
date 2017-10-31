import 'dart:async';

import 'package:flutter/services.dart';

class MapView {
  MethodChannel _channel = const MethodChannel("com.apptreesoftware.map_view");
  StreamController<MapAnnotation> _annotationStreamController =
      new StreamController.broadcast();
  StreamController<Location> _locationChangeStreamController =
      new StreamController.broadcast();
  StreamController<Location> _mapInteractionStreamController =
      new StreamController.broadcast();
  StreamController<CameraPosition> _cameraStreamController =
      new StreamController.broadcast();

  List<MapAnnotation> _annotations;

  MapView() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  void show(MapOptions mapOptions) {
    _channel.invokeMethod('show', mapOptions.toMap());
  }

  void dismiss() {
    _channel.invokeMethod('dismiss');
  }

  void updateAnnotations(List<MapAnnotation> annotations) {
    _annotations = annotations;
    _channel.invokeMethod('setAnnotations',
        annotations.map((a) => a.toMap()).toList(growable: false));
  }

  void zoomToFit() {
    _channel.invokeMethod('zoomToFit');
  }

  void setCameraPosition(double latitude, double longitude, double zoom) {
    _channel.invokeMethod("setCamera",
        {"latitude": latitude, "longitude": longitude, "zoom": zoom});
  }

  Future<Location> get centerLocation async {
    Map locationMap = await _channel.invokeMethod("getCenter");
    return new Location(locationMap["latitude"], locationMap["longitude"]);
  }

  Future<Location> get zoomLevel async {
    return await _channel.invokeMethod("getZoomLevel");
  }

  Stream<MapAnnotation> get onTouchAnnotation =>
      _annotationStreamController.stream;

  Stream<Location> get onLocationUpdated =>
      _locationChangeStreamController.stream;

  Stream<Location> get onMapTapped => _mapInteractionStreamController.stream;

  Stream<CameraPosition> get onCameraChanged => _cameraStreamController.stream;

  Future<dynamic> _handleMethod(MethodCall call) async {
    print("Received method call ${call.method}");
    switch (call.method) {
      case "locationUpdated":
        Map args = call.arguments;
        _locationChangeStreamController.add(new Location.fromMap(args));
        return new Future.value("");
      case "annotationTapped":
        String id = call.arguments;
        var annotation = _annotations?.firstWhere((a) => a.id == id);
        if (annotation != null) {
          _annotationStreamController.add(annotation);
        }
        return new Future.value("");
      case "mapTapped":
        Map locationMap = call.arguments;
        Location location = new Location.fromMap(locationMap);
        _mapInteractionStreamController.add(location);
        return new Future.value("");
      case "cameraPositionChanged":
        _cameraStreamController.add(new CameraPosition.fromMap(call.arguments));
        return new Future.value("");
    }
    return new Future.value("");
  }
}

class MapAnnotation {
  final String id;
  final String title;
  final double latitude;
  final double longitude;

  MapAnnotation(this.id, this.title, this.latitude, this.longitude);

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "latitude": latitude,
      "longitude": longitude,
      "type": "pin"
    };
  }
}

class ClusterAnnotation extends MapAnnotation {
  final int clusterCount;

  ClusterAnnotation(String id, String title, double latitude, double longitude,
      this.clusterCount)
      : super(id, title, latitude, longitude);

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "latitude": latitude,
      "longitude": longitude,
      "type": "cluster",
      "clusterCount": clusterCount
    };
  }
}

class MapOptions {
  final String apiKey;
  final bool showUserLocation;
  final MapType mapType;

  MapOptions(
      {this.apiKey: "",
      this.showUserLocation: false,
      this.mapType: MapType.google});

  Map<String, dynamic> toMap() {
    return {
      "showUserLocation": showUserLocation,
      "mapType": mapType.toString(),
      "apiKey": apiKey
    };
  }
}

class Location {
  final double latitude;
  final double longitude;

  Location(this.latitude, this.longitude);
  factory Location.fromMap(Map map) {
    return new Location(map["latitude"], map["longitude"]);
  }

  Map toMap() {
    return {"latitude": this.latitude, "longitude": this.longitude};
  }

  @override
  String toString() {
    return 'Location{latitude: $latitude, longitude: $longitude}';
  }
}

class CameraPosition {
  final Location center;
  final double zoom;

  CameraPosition(this.center, this.zoom);

  factory CameraPosition.fromMap(Map map) {
    return new CameraPosition(new Location.fromMap(map), map["zoom"]);
  }

  Map toMap() {
    Map map = center.toMap();
    map["zoom"] = zoom;
    return map;
  }
}

enum MapType { google }
