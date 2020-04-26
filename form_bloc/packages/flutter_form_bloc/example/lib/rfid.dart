class Rfid{
  final String rfid;
  final String weight;
  final String name;
  final DateTime readingTime;
  final int category;
  Rfid(this.weight,this.rfid,this.name,this.readingTime, this.category);

  Rfid.fromJson(Map<String, dynamic> json)
      : rfid=json['RfID'],
        weight=json['Weight'],
        name = json['Name'],
        readingTime=DateTime.parse(json['ReadingTime']),
        category = int.parse(json['CategoryID']);

  Map<String, dynamic> toJson() =>
    {
      'RfID':rfid,
      'Weight':weight,
      'Name': name,
      'ReadingTime':readingTime,
      'CategoryID': category,
    };
}