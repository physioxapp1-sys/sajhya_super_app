// "AI mode" home search -- deliberately NOT an LLM call (no API key/SDK
// exists anywhere in this backend, and adding one is real infra + per-
// search cost; see the conversation this shipped from). Instead: split a
// natural-language query into clauses, recognize which of the app's four
// catalogs each clause is probably about via keyword sets, and run the
// existing per-catalog search endpoints in parallel -- "find me knee
// braces and needed medication list" becomes a Shop search for "knee" and
// a Pharmacy section with no specific drug named (prompts to browse
// instead of a futile name search -- see _specificTerm's doc comment).

import '../models/exercise_library.dart';
import '../models/pharmacy_product.dart';
import '../models/shop_product.dart';
import '../screens/lab_test_screen.dart' show LabTest;
import 'api_service.dart';

class SmartCategoryResult<T> {
  final bool triggered;
  final bool genericOnly;
  final String? searchTerm;
  final List<T> items;
  final bool failed;

  const SmartCategoryResult({
    required this.triggered,
    required this.genericOnly,
    this.searchTerm,
    required this.items,
    this.failed = false,
  });

  static SmartCategoryResult<T> notTriggered<T>() =>
      SmartCategoryResult<T>(triggered: false, genericOnly: false, items: const []);
}

class SmartSearchResults {
  final String query;
  final SmartCategoryResult<ShopProduct> shop;
  final SmartCategoryResult<PharmacyProduct> pharmacy;
  final SmartCategoryResult<LabTest> lab;
  final SmartCategoryResult<LibraryExercise> exercise;

  const SmartSearchResults({
    required this.query,
    required this.shop,
    required this.pharmacy,
    required this.lab,
    required this.exercise,
  });

  bool get nothingTriggered => !shop.triggered && !pharmacy.triggered && !lab.triggered && !exercise.triggered;
}

const Set<String> _shopKeywords = {
  'brace', 'braces', 'support', 'supports', 'equipment', 'aid', 'aids', 'walker', 'walkers',
  'wheelchair', 'wheelchairs', 'crutch', 'crutches', 'splint', 'splints', 'belt', 'belts',
  'collar', 'collars', 'cane', 'canes', 'orthotic', 'orthotics', 'bandage', 'bandages',
  'sling', 'slings', 'mobility', 'cushion', 'cushions', 'strap', 'straps', 'guard', 'guards',
  'stocking', 'stockings', 'compression',
};

const Set<String> _pharmacyKeywords = {
  'medicine', 'medicines', 'medication', 'medications', 'tablet', 'tablets', 'pill', 'pills',
  'capsule', 'capsules', 'syrup', 'drug', 'drugs', 'pharmacy', 'prescription', 'prescriptions',
  'dose', 'dosage', 'antibiotic', 'antibiotics', 'painkiller', 'painkillers', 'vitamin',
  'vitamins', 'supplement', 'supplements', 'ointment', 'cream', 'injection', 'injections',
  'drops',
};

const Set<String> _labKeywords = {
  'test', 'tests', 'blood', 'lab', 'labs', 'panel', 'panels', 'checkup', 'checkups',
  'screening', 'report', 'reports', 'diagnostic', 'diagnostics', 'diagnosis',
};

const Set<String> _exerciseKeywords = {
  'exercise', 'exercises', 'stretch', 'stretches', 'stretching', 'workout', 'workouts',
  'physiotherapy', 'rehab', 'rehabilitation', 'strengthening', 'therapy',
};

const Set<String> _stopwords = {
  'find', 'me', 'show', 'i', 'need', 'needed', 'want', 'wanted', 'looking', 'for', 'can',
  'you', 'search', 'get', 'please', 'list', 'some', 'any', 'a', 'the', 'my', 'to', 'of',
  'also', 'with', 'us', 'an',
};

List<String> _splitClauses(String query) {
  final normalized = query.toLowerCase().replaceAll(RegExp(r'[,&;]'), ' and ');
  return normalized.split(RegExp(r'\band\b')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
}

String _stripStopwords(String clause) {
  return clause.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && !_stopwords.contains(w)).join(' ').trim();
}

// What's left of a clause once its own category-trigger word(s) are removed
// -- e.g. clause "knee braces", trigger "braces" -> specific term "knee".
// Empty means the clause was ONLY a generic category reference ("medication",
// "medicines list") with nothing specific to actually search a product/test
// name for; these endpoints match by name substring, so searching the bare
// category word itself would mostly return nothing even though the intent
// is clear -- that case shows a "browse" prompt instead (see
// SmartSearchResultsScreen) rather than a dead, empty search.
String _specificTerm(String clause, Set<String> categoryKeywords) {
  return clause.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && !categoryKeywords.contains(w)).join(' ').trim();
}

Future<SmartSearchResults> runSmartSearch(String rawQuery) async {
  final clauses = _splitClauses(rawQuery).map(_stripStopwords).where((c) => c.isNotEmpty).toList();

  bool shopHit = false, pharmacyHit = false, labHit = false, exerciseHit = false;
  String? shopTerm, pharmacyTerm, labTerm, exerciseTerm;

  for (final clause in clauses) {
    final words = clause.split(RegExp(r'\s+')).toSet();
    if (!shopHit && words.any(_shopKeywords.contains)) {
      shopHit = true;
      shopTerm = _specificTerm(clause, _shopKeywords);
    }
    if (!pharmacyHit && words.any(_pharmacyKeywords.contains)) {
      pharmacyHit = true;
      pharmacyTerm = _specificTerm(clause, _pharmacyKeywords);
    }
    if (!labHit && words.any(_labKeywords.contains)) {
      labHit = true;
      labTerm = _specificTerm(clause, _labKeywords);
    }
    if (!exerciseHit && words.any(_exerciseKeywords.contains)) {
      exerciseHit = true;
      exerciseTerm = _specificTerm(clause, _exerciseKeywords);
    }
  }

  // Nothing recognized in any clause -- fall back to running the whole
  // (stopword-stripped) query across all four catalogs rather than
  // returning nothing just because it didn't match this heuristic's
  // keyword lists.
  if (!shopHit && !pharmacyHit && !labHit && !exerciseHit) {
    final fallback = clauses.isNotEmpty ? clauses.join(' ') : rawQuery.trim();
    if (fallback.isNotEmpty) {
      shopHit = pharmacyHit = labHit = exerciseHit = true;
      shopTerm = pharmacyTerm = labTerm = exerciseTerm = fallback;
    }
  }

  final results = await Future.wait<Object>([
    _searchShop(shopHit, shopTerm),
    _searchPharmacy(pharmacyHit, pharmacyTerm),
    _searchLab(labHit, labTerm),
    _searchExercise(exerciseHit, exerciseTerm),
  ]);

  return SmartSearchResults(
    query: rawQuery,
    shop: results[0] as SmartCategoryResult<ShopProduct>,
    pharmacy: results[1] as SmartCategoryResult<PharmacyProduct>,
    lab: results[2] as SmartCategoryResult<LabTest>,
    exercise: results[3] as SmartCategoryResult<LibraryExercise>,
  );
}

Future<SmartCategoryResult<ShopProduct>> _searchShop(bool hit, String? term) async {
  if (!hit) return SmartCategoryResult.notTriggered<ShopProduct>();
  if (term == null || term.isEmpty) {
    return const SmartCategoryResult(triggered: true, genericOnly: true, items: []);
  }
  try {
    final raw = await ApiService().getShopProducts(search: term);
    return SmartCategoryResult(triggered: true, genericOnly: false, searchTerm: term, items: raw.map(ShopProduct.fromJson).toList());
  } catch (_) {
    return SmartCategoryResult(triggered: true, genericOnly: false, searchTerm: term, items: const [], failed: true);
  }
}

Future<SmartCategoryResult<PharmacyProduct>> _searchPharmacy(bool hit, String? term) async {
  if (!hit) return SmartCategoryResult.notTriggered<PharmacyProduct>();
  if (term == null || term.isEmpty) {
    return const SmartCategoryResult(triggered: true, genericOnly: true, items: []);
  }
  try {
    final raw = await ApiService().getPharmacyProducts(search: term);
    return SmartCategoryResult(triggered: true, genericOnly: false, searchTerm: term, items: raw.map(PharmacyProduct.fromJson).toList());
  } catch (_) {
    return SmartCategoryResult(triggered: true, genericOnly: false, searchTerm: term, items: const [], failed: true);
  }
}

// LabTest has no server-side search param (the catalog is small enough
// that lab_test_screen.dart already fetches it whole and filters client-
// side for its own search sheet) -- mirrored here the same way.
Future<SmartCategoryResult<LabTest>> _searchLab(bool hit, String? term) async {
  if (!hit) return SmartCategoryResult.notTriggered<LabTest>();
  if (term == null || term.isEmpty) {
    return const SmartCategoryResult(triggered: true, genericOnly: true, items: []);
  }
  try {
    final raw = await ApiService().getLabTests();
    final all = raw.map(LabTest.fromJson).toList();
    final q = term.toLowerCase();
    final matched = all
        .where((t) => t.name.toLowerCase().contains(q) || t.subtitle.toLowerCase().contains(q) || t.description.toLowerCase().contains(q))
        .toList();
    return SmartCategoryResult(triggered: true, genericOnly: false, searchTerm: term, items: matched);
  } catch (_) {
    return SmartCategoryResult(triggered: true, genericOnly: false, searchTerm: term, items: const [], failed: true);
  }
}

Future<SmartCategoryResult<LibraryExercise>> _searchExercise(bool hit, String? term) async {
  if (!hit) return SmartCategoryResult.notTriggered<LibraryExercise>();
  if (term == null || term.isEmpty) {
    return const SmartCategoryResult(triggered: true, genericOnly: true, items: []);
  }
  try {
    final raw = await ApiService().searchExercises(term);
    return SmartCategoryResult(triggered: true, genericOnly: false, searchTerm: term, items: raw.map(LibraryExercise.fromJson).toList());
  } catch (_) {
    return SmartCategoryResult(triggered: true, genericOnly: false, searchTerm: term, items: const [], failed: true);
  }
}
