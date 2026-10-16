class ParsedPropertyData {
  String? propertyType;
  String? location;
  String? area;
  String? price;
  String? phone;
  String? ownerName;
  String? details;

  ParsedPropertyData({
    this.propertyType,
    this.location,
    this.area,
    this.price,
    this.phone,
    this.ownerName,
    this.details,
  });
}

class SmartTextParser {
  static ParsedPropertyData parseMessage(String rawText) {
    String text = rawText.trim();
    
    // 1. استخراج رقم الهاتف (11 رقم يبدأ بـ 01)
    RegExp phoneRegex = RegExp(r'(01[0125]\d{8})');
    Match? phoneMatch = phoneRegex.firstMatch(text);
    String? phone = phoneMatch?.group(0);

    // 2. استخراج المساحة (أرقام يتبعها متر أو م2)
    RegExp areaRegex = RegExp(r'(\d+)\s*(متر|م2|م)');
    Match? areaMatch = areaRegex.firstMatch(text);
    String? area = areaMatch?.group(1);

    // 3. استخراج السعر
    RegExp priceRegex = RegExp(r'(\d+[\d,.]*)\s*(مليون|ألف|الف|جنيه|ج)');
    Match? priceMatch = priceRegex.firstMatch(text);
    String? price = priceMatch?.group(0);

    // 4. استخراج نوع العقار
    String propertyType = 'شقة'; // افتراضي
    if (text.contains('فيلا')) propertyType = 'فيلا';
    if (text.contains('روف')) propertyType = 'روف';
    if (text.contains('محل')) propertyType = 'محل';
    if (text.contains('أرض') || text.contains('ارض')) propertyType = 'أرض';

    // 5. استخراج اسم العميل/المالك (الكلمات بعد للتواصل أو أ/ أو كابتن)
    RegExp nameRegex = RegExp(r'(للتواصل|المالك|أ\/|كابتن|أستاذ)\s+([\u0600-\u06FF]+(?:\s+[\u0600-\u06FF]+)?)');
    Match? nameMatch = nameRegex.firstMatch(text);
    String? ownerName = nameMatch?.group(2);

    return ParsedPropertyData(
      propertyType: propertyType,
      area: area != null ? '$area متر' : '',
      price: price ?? '',
      phone: phone ?? '',
      ownerName: ownerName ?? '',
      details: text,
    );
  }
}