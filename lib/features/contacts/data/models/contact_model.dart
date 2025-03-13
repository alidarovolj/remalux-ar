class LocalizedText {
  final String ru;
  final String kz;
  final String en;

  LocalizedText({
    required this.ru,
    required this.kz,
    required this.en,
  });

  factory LocalizedText.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return LocalizedText(ru: '', kz: '', en: '');
    }
    return LocalizedText(
      ru: json['ru'] as String? ?? '',
      kz: json['kz'] as String? ?? '',
      en: json['en'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ru': ru,
      'kz': kz,
      'en': en,
    };
  }
}

class City {
  final int id;
  final LocalizedText title;

  City({
    required this.id,
    required this.title,
  });

  factory City.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return City(id: 0, title: LocalizedText(ru: '', kz: '', en: ''));
    }
    return City(
      id: json['id'] as int? ?? 0,
      title: LocalizedText.fromJson(json['title'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title.toJson(),
    };
  }
}

class ContactItem {
  final int id;
  final String title;
  final String value;
  final String type;

  ContactItem({
    required this.id,
    required this.title,
    required this.value,
    required this.type,
  });

  factory ContactItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ContactItem(id: 0, title: '', value: '', type: '');
    }
    return ContactItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      value: json['value'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'type': type,
    };
  }
}

class ContactItems {
  final List<ContactItem> email;
  final List<ContactItem> phone;

  ContactItems({
    required this.email,
    required this.phone,
  });

  factory ContactItems.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ContactItems(email: [], phone: []);
    }
    return ContactItems(
      email: (json['email'] as List<dynamic>?)
              ?.map((e) => ContactItem.fromJson(e as Map<String, dynamic>?))
              .toList() ??
          [],
      phone: (json['phone'] as List<dynamic>?)
              ?.map((e) => ContactItem.fromJson(e as Map<String, dynamic>?))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email.map((e) => e.toJson()).toList(),
      'phone': phone.map((e) => e.toJson()).toList(),
    };
  }
}

class WorkTime {
  final String? startTime;
  final String? endTime;

  WorkTime({
    this.startTime,
    this.endTime,
  });

  factory WorkTime.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return WorkTime();
    }
    return WorkTime(
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}

class BreakTime {
  final String? startTime;
  final String? endTime;

  BreakTime({
    this.startTime,
    this.endTime,
  });

  factory BreakTime.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return BreakTime();
    }
    return BreakTime(
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}

class ContactInnerItem {
  final String latitude;
  final String longitude;
  final ContactItems contactItems;
  final LocalizedText address;
  final String mainPhone;
  final String mainEmail;
  final String? office;
  final String? floor;
  final List<WorkTime> workTime;
  final BreakTime breakTime;
  final City city;

  ContactInnerItem({
    required this.latitude,
    required this.longitude,
    required this.contactItems,
    required this.address,
    required this.mainPhone,
    required this.mainEmail,
    this.office,
    this.floor,
    required this.workTime,
    required this.breakTime,
    required this.city,
  });

  factory ContactInnerItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ContactInnerItem(
        latitude: '',
        longitude: '',
        contactItems: ContactItems(email: [], phone: []),
        address: LocalizedText(ru: '', kz: '', en: ''),
        mainPhone: '',
        mainEmail: '',
        workTime: [],
        breakTime: BreakTime(),
        city: City(id: 0, title: LocalizedText(ru: '', kz: '', en: '')),
      );
    }
    return ContactInnerItem(
      latitude: json['latitude'] as String? ?? '',
      longitude: json['longitude'] as String? ?? '',
      contactItems:
          ContactItems.fromJson(json['contact_items'] as Map<String, dynamic>?),
      address: LocalizedText.fromJson(json['address'] as Map<String, dynamic>?),
      mainPhone: json['main_phone'] as String? ?? '',
      mainEmail: json['main_email'] as String? ?? '',
      office: json['office'] as String?,
      floor: json['floor'] as String?,
      workTime: (json['work_time'] as List<dynamic>?)
              ?.map((e) => WorkTime.fromJson(e as Map<String, dynamic>?))
              .toList() ??
          [],
      breakTime:
          BreakTime.fromJson(json['break_time'] as Map<String, dynamic>?),
      city: City.fromJson(json['city'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'contact_items': contactItems.toJson(),
      'address': address.toJson(),
      'main_phone': mainPhone,
      'main_email': mainEmail,
      'office': office,
      'floor': floor,
      'work_time': workTime.map((e) => e.toJson()).toList(),
      'break_time': breakTime.toJson(),
      'city': city.toJson(),
    };
  }
}

class Contact {
  final int id;
  final City city;
  final LocalizedText address;
  final String mainPhone;
  final String mainEmail;
  final List<ContactInnerItem> innerItems;

  Contact({
    required this.id,
    required this.city,
    required this.address,
    required this.mainPhone,
    required this.mainEmail,
    required this.innerItems,
  });

  factory Contact.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Contact(
        id: 0,
        city: City(id: 0, title: LocalizedText(ru: '', kz: '', en: '')),
        address: LocalizedText(ru: '', kz: '', en: ''),
        mainPhone: '',
        mainEmail: '',
        innerItems: [],
      );
    }
    return Contact(
      id: json['id'] as int? ?? 0,
      city: City.fromJson(json['city'] as Map<String, dynamic>?),
      address: LocalizedText.fromJson(json['address'] as Map<String, dynamic>?),
      mainPhone: json['main_phone'] as String? ?? '',
      mainEmail: json['main_email'] as String? ?? '',
      innerItems: (json['inner_items'] as List<dynamic>?)
              ?.map(
                  (e) => ContactInnerItem.fromJson(e as Map<String, dynamic>?))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city': city.toJson(),
      'address': address.toJson(),
      'main_phone': mainPhone,
      'main_email': mainEmail,
      'inner_items': innerItems.map((e) => e.toJson()).toList(),
    };
  }

  Contact copyWith({
    int? id,
    City? city,
    LocalizedText? address,
    String? mainPhone,
    String? mainEmail,
    List<ContactInnerItem>? innerItems,
  }) {
    return Contact(
      id: id ?? this.id,
      city: city ?? this.city,
      address: address ?? this.address,
      mainPhone: mainPhone ?? this.mainPhone,
      mainEmail: mainEmail ?? this.mainEmail,
      innerItems: innerItems ?? this.innerItems,
    );
  }
}
