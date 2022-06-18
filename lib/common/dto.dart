class VideoSimple {
  late String id;
  late String title;
  late String videoUrl;
  late String thumb;
  late String author;
  late String updateDate;
  late String pageView;
  String? star;
  List<String>? categories;
  List<String>? tags;
  String? source;
  String? sourceName;

  VideoSimple(this.id, this.title, this.videoUrl, this.thumb, this.author,
      this.updateDate, this.pageView);

  Map toJson() => {
        "id": id,
        "categories": categories,
        "title": title,
        "tags": tags,
        "thumb": thumb,
        "star": star,
        "author": author,
        "updateDate": updateDate,
        "source": source,
        "sourceName": sourceName,
        "videoUrl": videoUrl,
        "pageView": pageView,
      };

  VideoSimple.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    title = json["title"] ?? "";
    videoUrl = json["videoUrl"] ?? "";
    categories = (json["categories"] ?? []).cast<String>();
    tags = (json["tags"] ?? []).cast<String>();
    thumb = json["thumb"] ?? "";
    star = json["star"] ?? "";
    author = json["author"] ?? "";
    updateDate = json["updateDate"] ?? "";
    source = json["source"];
    sourceName = json["sourceName"];
    pageView = json["pageView"];
  }
}
