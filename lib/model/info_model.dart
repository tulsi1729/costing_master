class InfoModel {
  String clientName;
  String sariName;
  int? designNo;
  String imageUrl;
  InfoModel({
    required this.clientName,
    required this.sariName,
    this.designNo,
    required this.imageUrl,
  });

  InfoModel copyWith({
    String? clientName,
    String? sariName,
    int? designNo,
    String? imageUrl,
  }) {
    return InfoModel(
      clientName: clientName ?? this.clientName,
      sariName: sariName ?? this.sariName,
      designNo: designNo ?? this.designNo,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return "url: $imageUrl and name is $sariName";
  }
}
