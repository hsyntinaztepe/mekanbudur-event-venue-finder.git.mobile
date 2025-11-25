class ServiceCategory {
  final int id;
  final String name;

  ServiceCategory({required this.id, required this.name});

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'],
      name: json['name'],
    );
  }
}

class ListingItem {
  final String id;
  final int categoryId;
  final String categoryName;
  final double budget;
  final String status;

  ListingItem({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.budget,
    required this.status,
  });

  factory ListingItem.fromJson(Map<String, dynamic> json) {
    return ListingItem(
      id: json['id'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? '',
      budget: (json['budget'] as num).toDouble(),
      status: json['status'] ?? 'Open',
    );
  }
}

enum ListingVisibility { passive, active, deleted }

class Listing {
  final String id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String? location;
  final double? latitude;
  final double? longitude;
  final double? radius;
  final String? addressLabel;
  final double totalBudget;
  final List<ListingItem> items;
  final String status;
  final DateTime createdAt;
  final ListingVisibility visibility;

  Listing({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.location,
    this.latitude,
    this.longitude,
    this.radius,
    this.addressLabel,
    required this.totalBudget,
    required this.items,
    required this.status,
    required this.createdAt,
    this.visibility = ListingVisibility.active,
  });

  Listing copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? eventDate,
    String? location,
    double? latitude,
    double? longitude,
    double? radius,
    String? addressLabel,
    double? totalBudget,
    List<ListingItem>? items,
    String? status,
    DateTime? createdAt,
    ListingVisibility? visibility,
  }) {
    return Listing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      addressLabel: addressLabel ?? this.addressLabel,
      totalBudget: totalBudget ?? this.totalBudget,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      visibility: visibility ?? this.visibility,
    );
  }

  static ListingVisibility _visibilityFromJson(dynamic value) {
    final intValue = value is int
        ? value
        : int.tryParse(value?.toString() ?? '') ??
            ListingVisibility.active.index;
    return ListingVisibility.values.firstWhere(
      (v) => v.index == intValue,
      orElse: () => ListingVisibility.active,
    );
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      eventDate: DateTime.parse(json['eventDate']),
      location: json['location'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radius: (json['radius'] as num?)?.toDouble(),
      addressLabel: json['addressLabel'],
      totalBudget: (json['totalBudget'] as num).toDouble(),
      items:
          (json['items'] as List).map((i) => ListingItem.fromJson(i)).toList(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAtUtc']),
      visibility: _visibilityFromJson(json['visibility']),
    );
  }
}
