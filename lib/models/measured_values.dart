class MeasuredValues {
  final String? mTimeStamp;
  final String? lednum;
  final double? one;
  final double? two;
  final double? three;
  final double? four;
  final double? five;
  final double? six;
  final double? seven;
  final double? eight;
  final double? nine;
  final double? ten;
  final double? eleven;
  final double? twelve;

  MeasuredValues({
    this.mTimeStamp,
    this.lednum,
    this.one,
    this.two,
    this.three,
    this.four,
    this.five,
    this.six,
    this.seven,
    this.eight,
    this.nine,
    this.ten,
    this.eleven,
    this.twelve,
  });

  Map<String, dynamic> toMap() => {
    'mTimeStamp': mTimeStamp,
    'lednum': lednum,
    'one': one,
    'two': two,
    'three': three,
    'four': four,
    'five': five,
    'six': six,
    'seven': eight,
    'eight': eight,
    'nine': nine,
    'ten': ten,
    'eleven': eleven,
    'twelve': twelve
  };
}