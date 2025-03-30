class Address {
  String userId;
  String addressLabel;
  String flatNumber;
  String buildingComplex;
  String area;
  String city;
  String state;
  String pincode;

  Address({
    required this.userId,
    required this.addressLabel,
    required this.flatNumber,
    required this.buildingComplex,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'addressLabel': addressLabel,
      'flatNumber': flatNumber,
      'buildingComplex': buildingComplex,
      'area': area,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      userId: map['userId'] ?? '',
      addressLabel: map['addressLabel'] ?? '',
      flatNumber: map['flatNumber'] ?? '',
      buildingComplex: map['buildingComplex'] ?? '',
      area: map['area'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
    );
  }
}
