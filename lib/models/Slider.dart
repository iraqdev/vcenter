import 'dart:convert';
List<SliderBar> sliderFromJson(String str) => List<SliderBar>.from(json.decode(str).map((x) => SliderBar.fromJson(x)));
String sliderToJson(List<SliderBar> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
class SliderBar {
  int id;
  String title;
  String image;
  String link;
  SliderBar({
    required this.id,
    required this.title,
    required this.image,
    this.link = '',
  });
  factory SliderBar.fromJson(Map<String, dynamic> json) => SliderBar(
    id: json["id"] is int ? json["id"] : int.tryParse('${json["id"]}') ?? 0,
    title: json["title"]?.toString() ?? '',
    image: json["image"]?.toString() ?? '',
    link: json["link"]?.toString() ?? '',
  );
  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "image": image,
    "link": link,
  };
}
