/// All user-facing text. The app is Arabic only (A3), so one file is enough;
/// moving to ARB files later only touches this class.
abstract final class AppStrings {
  static const appName = 'تفاسير';

  // Startup
  static const preparing = 'جارٍ تجهيز المصحف والتفاسير…';
  static const preparingFirstRun = 'يحدث هذا مرة واحدة فقط';
  static const startupFailed = 'تعذّر فتح بيانات التطبيق';
  static const retry = 'إعادة المحاولة';

  // Home
  static const surahsTab = 'السور';
  static const juzTab = 'الأجزاء';
  static const continueReading = 'متابعة القراءة';
  static const jumpToAyah = 'الانتقال إلى آية';
  static const jumpHint = 'مثال: ٢:٢٥٥';
  static const jumpInvalid = 'اكتب رقم السورة ثم رقم الآية، مثل ٢:٢٥٥';
  static const go = 'انتقال';
  static const cancel = 'إلغاء';
  static const bookmarks = 'العلامات';
  static const settings = 'الإعدادات';
  static const meccan = 'مكية';
  static const medinan = 'مدنية';
  static String ayahCount(String n) => '$n آية';
  static String juz(String n) => 'الجزء $n';
  static String hizb(String n) => 'الحزب $n';
  static String surahPrefix(String name) => 'سورة $name';

  // Reader
  static const longPressHint = 'اضغط مطولاً على الآية لعرض تفسيرها';
  static const gotIt = 'حسناً';
  static const showTafsirAction = 'عرض التفسير';
  static const nextSurah = 'السورة التالية';
  static const previousSurah = 'السورة السابقة';

  // Tafsir sheet
  static const copy = 'نسخ';
  static const share = 'مشاركة';
  static const bookmark = 'حفظ علامة';
  static const removeBookmark = 'إزالة العلامة';
  static const copied = 'تم النسخ';
  static const bookmarkAdded = 'حُفظت العلامة';
  static const bookmarkRemoved = 'أُزيلت العلامة';
  static const nextAyah = 'الآية التالية';
  static const previousAyah = 'الآية السابقة';
  static const isnad = 'السند';
  static const footnote = 'حاشية';
  static const editorNote = 'ملاحظة المحقق';
  static const noTafsir = 'لا يوجد تفسير لهذه الآية';
  static const tafsirLoadFailed = 'تعذّر تحميل التفسير';
  static String minutes(String n) => '$n د';
  static String commentaryRange(String range) => 'تفسير الآيات $range';

  // Bookmarks
  static const noBookmarks = 'لا توجد علامات بعد.\nافتح تفسير آية واضغط على أيقونة العلامة لحفظها.';

  // Settings
  static const theme = 'المظهر';
  static const themeSystem = 'تلقائي';
  static const themeLight = 'فاتح';
  static const themeDark = 'داكن';
  static const themeSepia = 'بني';
  static const quranFontSize = 'حجم خط المصحف';
  static const tafsirFontSize = 'حجم خط التفسير';
  static const tafsirLineHeight = 'تباعد أسطر التفسير';
  static const showTashkeel = 'إظهار التشكيل في التفسير';
  static const hideIsnad = 'إخفاء الأسانيد';
  static const hideIsnadHint = 'تظهر الأسانيد كزر صغير يمكن فتحه';
  static const sources = 'المصادر';
  static const sourcesBody =
      'نص المصحف وخطه: مجمع الملك فهد لطباعة المصحف الشريف.\n'
      'التفاسير: المكتبة القرآنية الشاملة (QUL) من Tarteel.\n'
      'التفسير الميسر: مجمع الملك فهد لطباعة المصحف الشريف.\n'
      'بيانات الأجزاء والأحزاب: Tanzil.net (CC BY 3.0).';
}
