import 'package:latlong2/latlong.dart';

/// Predefined coordinates and metadata for Georgian settlements and municipalities
class GeorgianGeoEntry {
  final String name;
  final String region;
  final LatLng coordinates;

  const GeorgianGeoEntry({
    required this.name,
    required this.region,
    required this.coordinates,
  });
}

/// Comprehensive Georgian spatial database for instant, zero-latency reverse geocoding
const List<GeorgianGeoEntry> kGeorgianSettlements = [
  // კახეთი (Kakheti)
  GeorgianGeoEntry(name: 'გურჯაანი', region: 'კახეთი', coordinates: LatLng(41.7456, 45.7983)),
  GeorgianGeoEntry(name: 'თელავი', region: 'კახეთი', coordinates: LatLng(41.9198, 45.4731)),
  GeorgianGeoEntry(name: 'ყვარელი', region: 'კახეთი', coordinates: LatLng(41.9547, 45.8153)),
  GeorgianGeoEntry(name: 'სიღნაღი', region: 'კახეთი', coordinates: LatLng(41.6212, 45.9214)),
  GeorgianGeoEntry(name: 'საგარეჯო', region: 'კახეთი', coordinates: LatLng(41.7333, 45.3333)),
  GeorgianGeoEntry(name: 'ახმეტა', region: 'კახეთი', coordinates: LatLng(42.0333, 45.2167)),
  GeorgianGeoEntry(name: 'დედოფლისწყარო', region: 'კახეთი', coordinates: LatLng(41.4667, 46.1000)),
  GeorgianGeoEntry(name: 'ლაგოდეხი', region: 'კახეთი', coordinates: LatLng(41.8267, 46.2789)),
  GeorgianGeoEntry(name: 'წნორი', region: 'კახეთი', coordinates: LatLng(41.6117, 45.9733)),
  GeorgianGeoEntry(name: 'ველისციხე', region: 'კახეთი', coordinates: LatLng(41.8167, 45.7667)),
  GeorgianGeoEntry(name: 'წინანდალი', region: 'კახეთი', coordinates: LatLng(41.8953, 45.5714)),
  GeorgianGeoEntry(name: 'შილდა', region: 'კახეთი', coordinates: LatLng(42.0000, 45.7167)),

  // აჭარა (Adjara)
  GeorgianGeoEntry(name: 'ბათუმი', region: 'აჭარა', coordinates: LatLng(41.6168, 41.6367)),
  GeorgianGeoEntry(name: 'ქობულეთი', region: 'აჭარა', coordinates: LatLng(41.8214, 41.7792)),
  GeorgianGeoEntry(name: 'ხელვაჩაური', region: 'აჭარა', coordinates: LatLng(41.5833, 41.6667)),
  GeorgianGeoEntry(name: 'ახალშენი', region: 'ხელვაჩაური', coordinates: LatLng(41.6033, 41.6917)),
  GeorgianGeoEntry(name: 'მასაურა', region: 'ხელვაჩაური', coordinates: LatLng(41.6120, 41.7100)),
  GeorgianGeoEntry(name: 'სამება', region: 'ხელვაჩაური', coordinates: LatLng(41.6322, 41.6950)),
  GeorgianGeoEntry(name: 'ჩაქვი', region: 'ქობულეთი', coordinates: LatLng(41.7244, 41.7314)),
  GeorgianGeoEntry(name: 'მახინჯაური', region: 'ხელვაჩაური', coordinates: LatLng(41.6742, 41.6947)),
  GeorgianGeoEntry(name: 'ქედა', region: 'აჭარა', coordinates: LatLng(41.6000, 41.9333)),
  GeorgianGeoEntry(name: 'შუახევი', region: 'აჭარა', coordinates: LatLng(41.6256, 42.1856)),
  GeorgianGeoEntry(name: 'ხულო', region: 'აჭარა', coordinates: LatLng(41.6444, 42.3167)),
  GeorgianGeoEntry(name: 'გონიო', region: 'ხელვაჩაური', coordinates: LatLng(41.5736, 41.5722)),
  GeorgianGeoEntry(name: 'სარფი', region: 'ხელვაჩაური', coordinates: LatLng(41.5219, 41.5519)),

  // იმერეთი (Imereti)
  GeorgianGeoEntry(name: 'ქუთაისი', region: 'იმერეთი', coordinates: LatLng(42.2679, 42.6946)),
  GeorgianGeoEntry(name: 'სამტრედია', region: 'იმერეთი', coordinates: LatLng(42.1625, 42.3417)),
  GeorgianGeoEntry(name: 'ზესტაფონი', region: 'იმერეთი', coordinates: LatLng(42.1089, 43.0336)),
  GeorgianGeoEntry(name: 'წყალტუბო', region: 'იმერეთი', coordinates: LatLng(42.3267, 42.5997)),
  GeorgianGeoEntry(name: 'ბაღდათი', region: 'იმერეთი', coordinates: LatLng(42.0667, 42.8167)),
  GeorgianGeoEntry(name: 'ვანი', region: 'იმერეთი', coordinates: LatLng(42.0833, 42.5000)),
  GeorgianGeoEntry(name: 'ხონი', region: 'იმერეთი', coordinates: LatLng(42.3167, 42.4167)),
  GeorgianGeoEntry(name: 'თერჯოლა', region: 'იმერეთი', coordinates: LatLng(42.1833, 42.9833)),
  GeorgianGeoEntry(name: 'საჩხერე', region: 'იმერეთი', coordinates: LatLng(42.3400, 43.4150)),
  GeorgianGeoEntry(name: 'ჭიათურა', region: 'იმერეთი', coordinates: LatLng(42.2900, 43.2800)),
  GeorgianGeoEntry(name: 'ხარაგაული', region: 'იმერეთი', coordinates: LatLng(42.0167, 43.2000)),

  // შიდა ქართლი (Shida Kartli)
  GeorgianGeoEntry(name: 'გორი', region: 'შიდა ქართლი', coordinates: LatLng(41.9842, 44.1158)),
  GeorgianGeoEntry(name: 'კასპი', region: 'შიდა ქართლი', coordinates: LatLng(41.9250, 44.4250)),
  GeorgianGeoEntry(name: 'ხაშური', region: 'შიდა ქართლი', coordinates: LatLng(41.9967, 43.5986)),
  GeorgianGeoEntry(name: 'ქარელი', region: 'შიდა ქართლი', coordinates: LatLng(42.0231, 43.8944)),

  // ქვემო ქართლი (Kvemo Kartli)
  GeorgianGeoEntry(name: 'რუსთავი', region: 'ქვემო ქართლი', coordinates: LatLng(41.5495, 45.0186)),
  GeorgianGeoEntry(name: 'მარნეული', region: 'ქვემო ქართლი', coordinates: LatLng(41.4747, 44.8089)),
  GeorgianGeoEntry(name: 'ბოლნისი', region: 'ქვემო ქართლი', coordinates: LatLng(41.4489, 44.5381)),
  GeorgianGeoEntry(name: 'გარდაბანი', region: 'ქვემო ქართლი', coordinates: LatLng(41.4600, 45.0928)),
  GeorgianGeoEntry(name: 'დმანისი', region: 'ქვემო ქართლი', coordinates: LatLng(41.3300, 44.3400)),
  GeorgianGeoEntry(name: 'თეთრიწყარო', region: 'ქვემო ქართლი', coordinates: LatLng(41.5500, 44.4600)),
  GeorgianGeoEntry(name: 'წალკა', region: 'ქვემო ქართლი', coordinates: LatLng(41.6000, 44.0889)),

  // სამეგრელო-ზემო სვანეთი (Samegrelo)
  GeorgianGeoEntry(name: 'ზუგდიდი', region: 'სამეგრელო', coordinates: LatLng(42.5088, 41.8709)),
  GeorgianGeoEntry(name: 'ფოთი', region: 'სამეგრელო', coordinates: LatLng(42.1462, 41.6720)),
  GeorgianGeoEntry(name: 'სენაკი', region: 'სამეგრელო', coordinates: LatLng(42.2689, 42.0678)),
  GeorgianGeoEntry(name: 'აბაშა', region: 'სამეგრელო', coordinates: LatLng(42.2039, 42.2064)),
  GeorgianGeoEntry(name: 'მარტვილი', region: 'სამეგრელო', coordinates: LatLng(42.4142, 42.3789)),
  GeorgianGeoEntry(name: 'ხობი', region: 'სამეგრელო', coordinates: LatLng(42.3167, 41.9000)),
  GeorgianGeoEntry(name: 'ჩხოროწყუ', region: 'სამეგრელო', coordinates: LatLng(42.5200, 42.1300)),
  GeorgianGeoEntry(name: 'წალენჯიხა', region: 'სამეგრელო', coordinates: LatLng(42.6050, 42.0700)),
  GeorgianGeoEntry(name: 'მესტია', region: 'სვანეთი', coordinates: LatLng(43.0442, 42.7297)),

  // გურია (Guria)
  GeorgianGeoEntry(name: 'ოზურგეთი', region: 'გურია', coordinates: LatLng(41.9269, 42.0006)),
  GeorgianGeoEntry(name: 'ლანჩხუთი', region: 'გურია', coordinates: LatLng(42.0875, 42.0361)),
  GeorgianGeoEntry(name: 'ჩოხატაური', region: 'გურია', coordinates: LatLng(42.0189, 42.2394)),
  GeorgianGeoEntry(name: 'ურეკი', region: 'გურია', coordinates: LatLng(41.9900, 41.7700)),

  // მცხეთა-მთიანეთი (Mtskheta-Mtianeti)
  GeorgianGeoEntry(name: 'მცხეთა', region: 'მცხეთა-მთიანეთი', coordinates: LatLng(41.8458, 44.7188)),
  GeorgianGeoEntry(name: 'დუშეთი', region: 'მცხეთა-მთიანეთი', coordinates: LatLng(42.0833, 44.7000)),
  GeorgianGeoEntry(name: 'თიანეთი', region: 'მცხეთა-მთიანეთი', coordinates: LatLng(42.1089, 44.9628)),
  GeorgianGeoEntry(name: 'ყაზბეგი', region: 'მცხეთა-მთიანეთი', coordinates: LatLng(42.6567, 44.6433)),
  GeorgianGeoEntry(name: 'გუდაური', region: 'მცხეთა-მთიანეთი', coordinates: LatLng(42.4778, 44.4756)),

  // სამცხე-ჯავახეთი (Samtskhe-Javakheti)
  GeorgianGeoEntry(name: 'ახალციხე', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.6389, 42.9861)),
  GeorgianGeoEntry(name: 'ბორჯომი', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.8389, 43.3792)),
  GeorgianGeoEntry(name: 'ბაკურიანი', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.7500, 43.5333)),
  GeorgianGeoEntry(name: 'ასპინძა', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.5700, 43.2500)),
  GeorgianGeoEntry(name: 'ახალქალაქი', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.4056, 43.4861)),
  GeorgianGeoEntry(name: 'ნინოწმინდა', region: 'სამცხე-ჯავახეთი', coordinates: LatLng(41.2647, 43.5900)),

  // რაჭა-ლეჩხუმი
  GeorgianGeoEntry(name: 'ამბროლაური', region: 'რაჭა', coordinates: LatLng(42.5200, 43.1400)),
  GeorgianGeoEntry(name: 'ონი', region: 'რაჭა', coordinates: LatLng(42.5800, 43.4400)),
  GeorgianGeoEntry(name: 'ცაგერი', region: 'ლეჩხუმი', coordinates: LatLng(42.6500, 42.7700)),
  GeorgianGeoEntry(name: 'ლენტეხი', region: 'სვანეთი', coordinates: LatLng(42.7900, 42.7200)),

  // თბილისი (Tbilisi)
  GeorgianGeoEntry(name: 'თბილისი', region: 'დედაქალაქი', coordinates: LatLng(41.7151, 44.8271)),
  GeorgianGeoEntry(name: 'ვაკე-საბურთალო', region: 'თბილისი', coordinates: LatLng(41.7250, 44.7500)),
  GeorgianGeoEntry(name: 'გლდანი-ნაძალადევი', region: 'თბილისი', coordinates: LatLng(41.7800, 44.8100)),
  GeorgianGeoEntry(name: 'ისანი-სამგორი', region: 'თბილისი', coordinates: LatLng(41.6900, 44.8700)),
];

