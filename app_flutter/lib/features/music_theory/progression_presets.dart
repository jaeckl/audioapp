part of 'progression_templates.dart';

// Backward-compat named presets (also in progressionPresetList).
const pop1564Preset = ProgressionTemplate(
  id: 'pop_1564',
  label: 'I–V–vi–IV',
  degrees: [1, 5, 6, 4],
  subgenreId: 'pop_radio',
);

const canon1563Preset = ProgressionTemplate(
  id: 'canon_1563',
  label: 'I–V–vi–iii',
  degrees: [1, 5, 6, 3],
  subgenreId: 'pop_anthem',
);

const blues1451Preset = ProgressionTemplate(
  id: 'blues_1451',
  label: 'I–IV–V–I',
  degrees: [1, 4, 5, 1],
  subgenreId: 'rock_straight',
);

const jazz2511Preset = ProgressionTemplate(
  id: 'jazz_2511',
  label: 'ii–V–I–I',
  degrees: [2, 5, 1, 1],
  subgenreId: 'rnb_alt',
);

const sad6415Preset = ProgressionTemplate(
  id: 'sad_6415',
  label: 'vi–IV–I–V',
  degrees: [6, 4, 1, 5],
  subgenreId: 'pop_radio',
);

const modal1475Preset = ProgressionTemplate(
  id: 'modal_1475',
  label: 'I–IV–vii–V',
  degrees: [1, 4, 7, 5],
  subgenreId: 'elec_trance',
);

const loop1Preset = ProgressionTemplate(
  id: 'loop_1',
  label: 'I–I–IV–V',
  degrees: [1, 1, 4, 5],
  subgenreId: 'rock_straight',
);

const progressionPresetList = <ProgressionTemplate>[
  // elec_edm
  ProgressionTemplate(
    id: 'elec_edm_1564',
    label: 'I–V–vi–IV',
    degrees: [1, 5, 6, 4],
    subgenreId: 'elec_edm',
  ),
  ProgressionTemplate(
    id: 'elec_edm_6415',
    label: 'vi–IV–I–V',
    degrees: [6, 4, 1, 5],
    subgenreId: 'elec_edm',
  ),
  ProgressionTemplate(
    id: 'elec_edm_1364',
    label: 'I–iii–vi–IV',
    degrees: [1, 3, 6, 4],
    subgenreId: 'elec_edm',
  ),
  ProgressionTemplate(
    id: 'elec_edm_4516',
    label: 'IV–V–I–vi',
    degrees: [4, 5, 1, 6],
    subgenreId: 'elec_edm',
  ),
  ProgressionTemplate(
    id: 'elec_edm_1563',
    label: 'I–V–vi–iii',
    degrees: [1, 5, 6, 3],
    subgenreId: 'elec_edm',
  ),
  ProgressionTemplate(
    id: 'elec_edm_6545',
    label: 'vi–V–IV–V',
    degrees: [6, 5, 4, 5],
    subgenreId: 'elec_edm',
  ),
  ProgressionTemplate(
    id: 'elec_edm_1454',
    label: 'I–IV–V–IV',
    degrees: [1, 4, 5, 4],
    subgenreId: 'elec_edm',
  ),
  ProgressionTemplate(
    id: 'elec_edm_1645',
    label: 'I–vi–IV–V',
    degrees: [1, 6, 4, 5],
    subgenreId: 'elec_edm',
  ),
  ProgressionTemplate(
    id: 'elec_edm_4151',
    label: 'IV–I–V–I',
    degrees: [4, 1, 5, 1],
    subgenreId: 'elec_edm',
  ),
  ProgressionTemplate(
    id: 'elec_edm_1546',
    label: 'I–V–IV–vi',
    degrees: [1, 5, 4, 6],
    subgenreId: 'elec_edm',
  ),
  ProgressionTemplate(
    id: 'elec_edm_6345',
    label: 'vi–iii–IV–V',
    degrees: [6, 3, 4, 5],
    subgenreId: 'elec_edm',
  ),

  // elec_trance
  modal1475Preset,
  ProgressionTemplate(
    id: 'elec_trance_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'elec_trance',
  ),
  ProgressionTemplate(
    id: 'elec_trance_1637',
    label: 'i–VI–III–VII',
    degrees: [1, 6, 3, 7],
    subgenreId: 'elec_trance',
  ),
  ProgressionTemplate(
    id: 'elec_trance_1716',
    label: 'i–VII–i–VI',
    degrees: [1, 7, 1, 6],
    subgenreId: 'elec_trance',
  ),
  ProgressionTemplate(
    id: 'elec_trance_6711',
    label: 'VI–VII–i–i',
    degrees: [6, 7, 1, 1],
    subgenreId: 'elec_trance',
  ),
  ProgressionTemplate(
    id: 'elec_trance_1376',
    label: 'i–III–VII–VI',
    degrees: [1, 3, 7, 6],
    subgenreId: 'elec_trance',
  ),
  ProgressionTemplate(
    id: 'elec_trance_1671',
    label: 'i–VI–VII–i',
    degrees: [1, 6, 7, 1],
    subgenreId: 'elec_trance',
  ),
  ProgressionTemplate(
    id: 'elec_trance_1761',
    label: 'i–VII–VI–i',
    degrees: [1, 7, 6, 1],
    subgenreId: 'elec_trance',
  ),
  ProgressionTemplate(
    id: 'elec_trance_1473',
    label: 'i–iv–VII–III',
    degrees: [1, 4, 7, 3],
    subgenreId: 'elec_trance',
  ),
  ProgressionTemplate(
    id: 'elec_trance_1647',
    label: 'i–VI–iv–VII',
    degrees: [1, 6, 4, 7],
    subgenreId: 'elec_trance',
  ),
  ProgressionTemplate(
    id: 'elec_trance_1367',
    label: 'i–III–VI–VII',
    degrees: [1, 3, 6, 7],
    subgenreId: 'elec_trance',
  ),

  // elec_techno
  ProgressionTemplate(
    id: 'elec_techno_1167',
    label: 'i–i–VI–VII',
    degrees: [1, 1, 6, 7],
    subgenreId: 'elec_techno',
  ),
  ProgressionTemplate(
    id: 'elec_techno_17',
    label: 'i–VII',
    degrees: [1, 7],
    subgenreId: 'elec_techno',
  ),
  ProgressionTemplate(
    id: 'elec_techno_16',
    label: 'i–VI',
    degrees: [1, 6],
    subgenreId: 'elec_techno',
  ),
  ProgressionTemplate(
    id: 'elec_techno_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'elec_techno',
  ),
  ProgressionTemplate(
    id: 'elec_techno_1473',
    label: 'i–iv–VII–III',
    degrees: [1, 4, 7, 3],
    subgenreId: 'elec_techno',
  ),
  ProgressionTemplate(
    id: 'elec_techno_171',
    label: 'i–VII–i',
    degrees: [1, 7, 1],
    subgenreId: 'elec_techno',
  ),
  ProgressionTemplate(
    id: 'elec_techno_167',
    label: 'i–VI–VII',
    degrees: [1, 6, 7],
    subgenreId: 'elec_techno',
  ),
  ProgressionTemplate(
    id: 'elec_techno_141',
    label: 'i–iv–i',
    degrees: [1, 4, 1],
    subgenreId: 'elec_techno',
  ),
  ProgressionTemplate(
    id: 'elec_techno_137',
    label: 'i–III–VII',
    degrees: [1, 3, 7],
    subgenreId: 'elec_techno',
  ),
  ProgressionTemplate(
    id: 'elec_techno_1736',
    label: 'i–VII–III–VI',
    degrees: [1, 7, 3, 6],
    subgenreId: 'elec_techno',
  ),
  ProgressionTemplate(
    id: 'elec_techno_1147',
    label: 'i–i–iv–VII',
    degrees: [1, 1, 4, 7],
    subgenreId: 'elec_techno',
  ),

  // elec_dnb
  ProgressionTemplate(
    id: 'elec_dnb_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'elec_dnb',
  ),
  ProgressionTemplate(
    id: 'elec_dnb_1637',
    label: 'i–VI–III–VII',
    degrees: [1, 6, 3, 7],
    subgenreId: 'elec_dnb',
  ),
  ProgressionTemplate(
    id: 'elec_dnb_1471',
    label: 'i–iv–VII–i',
    degrees: [1, 4, 7, 1],
    subgenreId: 'elec_dnb',
  ),
  ProgressionTemplate(
    id: 'elec_dnb_1761',
    label: 'i–VII–VI–i',
    degrees: [1, 7, 6, 1],
    subgenreId: 'elec_dnb',
  ),
  ProgressionTemplate(
    id: 'elec_dnb_1671',
    label: 'i–VI–VII–i',
    degrees: [1, 6, 7, 1],
    subgenreId: 'elec_dnb',
  ),
  ProgressionTemplate(
    id: 'elec_dnb_1467',
    label: 'i–iv–VI–VII',
    degrees: [1, 4, 6, 7],
    subgenreId: 'elec_dnb',
  ),
  ProgressionTemplate(
    id: 'elec_dnb_1367',
    label: 'i–III–VI–VII',
    degrees: [1, 3, 6, 7],
    subgenreId: 'elec_dnb',
  ),
  ProgressionTemplate(
    id: 'elec_dnb_1736',
    label: 'i–VII–III–VI',
    degrees: [1, 7, 3, 6],
    subgenreId: 'elec_dnb',
  ),
  ProgressionTemplate(
    id: 'elec_dnb_1641',
    label: 'i–VI–iv–i',
    degrees: [1, 6, 4, 1],
    subgenreId: 'elec_dnb',
  ),
  ProgressionTemplate(
    id: 'elec_dnb_1716',
    label: 'i–VII–i–VI',
    degrees: [1, 7, 1, 6],
    subgenreId: 'elec_dnb',
  ),
  ProgressionTemplate(
    id: 'elec_dnb_1476',
    label: 'i–iv–VII–VI',
    degrees: [1, 4, 7, 6],
    subgenreId: 'elec_dnb',
  ),

  // house_classic
  ProgressionTemplate(
    id: 'house_classic_17',
    label: 'i–VII',
    degrees: [1, 7],
    subgenreId: 'house_classic',
  ),
  ProgressionTemplate(
    id: 'house_classic_14',
    label: 'i–IV',
    degrees: [1, 4],
    subgenreId: 'house_classic',
  ),
  ProgressionTemplate(
    id: 'house_classic_1415',
    label: 'I–IV–I–V',
    degrees: [1, 4, 1, 5],
    subgenreId: 'house_classic',
  ),
  ProgressionTemplate(
    id: 'house_classic_167',
    label: 'i–VI–VII',
    degrees: [1, 6, 7],
    subgenreId: 'house_classic',
  ),
  ProgressionTemplate(
    id: 'house_classic_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'house_classic',
  ),
  ProgressionTemplate(
    id: 'house_classic_1451',
    label: 'I–IV–V–I',
    degrees: [1, 4, 5, 1],
    subgenreId: 'house_classic',
  ),
  ProgressionTemplate(
    id: 'house_classic_171',
    label: 'i–VII–i',
    degrees: [1, 7, 1],
    subgenreId: 'house_classic',
  ),
  ProgressionTemplate(
    id: 'house_classic_137',
    label: 'i–III–VII',
    degrees: [1, 3, 7],
    subgenreId: 'house_classic',
  ),
  ProgressionTemplate(
    id: 'house_classic_1637',
    label: 'i–VI–III–VII',
    degrees: [1, 6, 3, 7],
    subgenreId: 'house_classic',
  ),
  ProgressionTemplate(
    id: 'house_classic_1471',
    label: 'i–iv–VII–i',
    degrees: [1, 4, 7, 1],
    subgenreId: 'house_classic',
  ),
  ProgressionTemplate(
    id: 'house_classic_1564',
    label: 'I–V–vi–IV',
    degrees: [1, 5, 6, 4],
    subgenreId: 'house_classic',
  ),

  // house_deep
  ProgressionTemplate(
    id: 'house_deep_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'house_deep',
  ),
  ProgressionTemplate(
    id: 'house_deep_17',
    label: 'i–VII',
    degrees: [1, 7],
    subgenreId: 'house_deep',
  ),
  ProgressionTemplate(
    id: 'house_deep_167',
    label: 'i–VI–VII',
    degrees: [1, 6, 7],
    subgenreId: 'house_deep',
  ),
  ProgressionTemplate(
    id: 'house_deep_1367',
    label: 'i–III–VI–VII',
    degrees: [1, 3, 6, 7],
    subgenreId: 'house_deep',
  ),
  ProgressionTemplate(
    id: 'house_deep_1471',
    label: 'i–iv–VII–i',
    degrees: [1, 4, 7, 1],
    subgenreId: 'house_deep',
  ),
  ProgressionTemplate(
    id: 'house_deep_1716',
    label: 'i–VII–i–VI',
    degrees: [1, 7, 1, 6],
    subgenreId: 'house_deep',
  ),
  ProgressionTemplate(
    id: 'house_deep_1637',
    label: 'i–VI–III–VII',
    degrees: [1, 6, 3, 7],
    subgenreId: 'house_deep',
  ),
  ProgressionTemplate(
    id: 'house_deep_1736',
    label: 'i–VII–III–VI',
    degrees: [1, 7, 3, 6],
    subgenreId: 'house_deep',
  ),
  ProgressionTemplate(
    id: 'house_deep_141',
    label: 'i–iv–i',
    degrees: [1, 4, 1],
    subgenreId: 'house_deep',
  ),
  ProgressionTemplate(
    id: 'house_deep_1647',
    label: 'i–VI–iv–VII',
    degrees: [1, 6, 4, 7],
    subgenreId: 'house_deep',
  ),
  ProgressionTemplate(
    id: 'house_deep_1376',
    label: 'i–III–VII–VI',
    degrees: [1, 3, 7, 6],
    subgenreId: 'house_deep',
  ),

  // house_tech
  ProgressionTemplate(
    id: 'house_tech_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'house_tech',
  ),
  ProgressionTemplate(
    id: 'house_tech_167',
    label: 'i–VI–VII',
    degrees: [1, 6, 7],
    subgenreId: 'house_tech',
  ),
  ProgressionTemplate(
    id: 'house_tech_17',
    label: 'i–VII',
    degrees: [1, 7],
    subgenreId: 'house_tech',
  ),
  ProgressionTemplate(
    id: 'house_tech_1471',
    label: 'i–iv–VII–i',
    degrees: [1, 4, 7, 1],
    subgenreId: 'house_tech',
  ),
  ProgressionTemplate(
    id: 'house_tech_137',
    label: 'i–III–VII',
    degrees: [1, 3, 7],
    subgenreId: 'house_tech',
  ),
  ProgressionTemplate(
    id: 'house_tech_171',
    label: 'i–VII–i',
    degrees: [1, 7, 1],
    subgenreId: 'house_tech',
  ),
  ProgressionTemplate(
    id: 'house_tech_1637',
    label: 'i–VI–III–VII',
    degrees: [1, 6, 3, 7],
    subgenreId: 'house_tech',
  ),
  ProgressionTemplate(
    id: 'house_tech_1167',
    label: 'i–i–VI–VII',
    degrees: [1, 1, 6, 7],
    subgenreId: 'house_tech',
  ),
  ProgressionTemplate(
    id: 'house_tech_1736',
    label: 'i–VII–III–VI',
    degrees: [1, 7, 3, 6],
    subgenreId: 'house_tech',
  ),
  ProgressionTemplate(
    id: 'house_tech_141',
    label: 'i–iv–i',
    degrees: [1, 4, 1],
    subgenreId: 'house_tech',
  ),
  ProgressionTemplate(
    id: 'house_tech_1647',
    label: 'i–VI–iv–VII',
    degrees: [1, 6, 4, 7],
    subgenreId: 'house_tech',
  ),

  // house_prog
  ProgressionTemplate(
    id: 'house_prog_1475',
    label: 'I–IV–vii–V',
    degrees: [1, 4, 7, 5],
    subgenreId: 'house_prog',
  ),
  ProgressionTemplate(
    id: 'house_prog_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'house_prog',
  ),
  ProgressionTemplate(
    id: 'house_prog_1637',
    label: 'i–VI–III–VII',
    degrees: [1, 6, 3, 7],
    subgenreId: 'house_prog',
  ),
  ProgressionTemplate(
    id: 'house_prog_1564',
    label: 'I–V–vi–IV',
    degrees: [1, 5, 6, 4],
    subgenreId: 'house_prog',
  ),
  ProgressionTemplate(
    id: 'house_prog_6415',
    label: 'vi–IV–I–V',
    degrees: [6, 4, 1, 5],
    subgenreId: 'house_prog',
  ),
  ProgressionTemplate(
    id: 'house_prog_1376',
    label: 'i–III–VII–VI',
    degrees: [1, 3, 7, 6],
    subgenreId: 'house_prog',
  ),
  ProgressionTemplate(
    id: 'house_prog_1465',
    label: 'I–IV–vi–V',
    degrees: [1, 4, 6, 5],
    subgenreId: 'house_prog',
  ),
  ProgressionTemplate(
    id: 'house_prog_1671',
    label: 'i–VI–VII–i',
    degrees: [1, 6, 7, 1],
    subgenreId: 'house_prog',
  ),
  ProgressionTemplate(
    id: 'house_prog_4516',
    label: 'IV–V–I–vi',
    degrees: [4, 5, 1, 6],
    subgenreId: 'house_prog',
  ),
  ProgressionTemplate(
    id: 'house_prog_1716',
    label: 'i–VII–i–VI',
    degrees: [1, 7, 1, 6],
    subgenreId: 'house_prog',
  ),
  ProgressionTemplate(
    id: 'house_prog_1645',
    label: 'I–vi–IV–V',
    degrees: [1, 6, 4, 5],
    subgenreId: 'house_prog',
  ),

  // hh_boombap
  ProgressionTemplate(
    id: 'hh_boombap_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'hh_boombap',
  ),
  ProgressionTemplate(
    id: 'hh_boombap_14',
    label: 'i–iv',
    degrees: [1, 4],
    subgenreId: 'hh_boombap',
  ),
  ProgressionTemplate(
    id: 'hh_boombap_1637',
    label: 'i–VI–III–VII',
    degrees: [1, 6, 3, 7],
    subgenreId: 'hh_boombap',
  ),
  ProgressionTemplate(
    id: 'hh_boombap_17',
    label: 'i–VII',
    degrees: [1, 7],
    subgenreId: 'hh_boombap',
  ),
  ProgressionTemplate(
    id: 'hh_boombap_1471',
    label: 'i–iv–VII–i',
    degrees: [1, 4, 7, 1],
    subgenreId: 'hh_boombap',
  ),
  ProgressionTemplate(
    id: 'hh_boombap_171',
    label: 'i–VII–i',
    degrees: [1, 7, 1],
    subgenreId: 'hh_boombap',
  ),
  ProgressionTemplate(
    id: 'hh_boombap_167',
    label: 'i–VI–VII',
    degrees: [1, 6, 7],
    subgenreId: 'hh_boombap',
  ),
  ProgressionTemplate(
    id: 'hh_boombap_137',
    label: 'i–III–VII',
    degrees: [1, 3, 7],
    subgenreId: 'hh_boombap',
  ),
  ProgressionTemplate(
    id: 'hh_boombap_141',
    label: 'i–iv–i',
    degrees: [1, 4, 1],
    subgenreId: 'hh_boombap',
  ),
  ProgressionTemplate(
    id: 'hh_boombap_1761',
    label: 'i–VII–VI–i',
    degrees: [1, 7, 6, 1],
    subgenreId: 'hh_boombap',
  ),
  ProgressionTemplate(
    id: 'hh_boombap_1647',
    label: 'i–VI–iv–VII',
    degrees: [1, 6, 4, 7],
    subgenreId: 'hh_boombap',
  ),

  // hh_modern
  ProgressionTemplate(
    id: 'hh_modern_1637',
    label: 'i–VI–III–VII',
    degrees: [1, 6, 3, 7],
    subgenreId: 'hh_modern',
  ),
  ProgressionTemplate(
    id: 'hh_modern_176',
    label: 'i–VII–VI',
    degrees: [1, 7, 6],
    subgenreId: 'hh_modern',
  ),
  ProgressionTemplate(
    id: 'hh_modern_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'hh_modern',
  ),
  ProgressionTemplate(
    id: 'hh_modern_1471',
    label: 'i–iv–VII–i',
    degrees: [1, 4, 7, 1],
    subgenreId: 'hh_modern',
  ),
  ProgressionTemplate(
    id: 'hh_modern_167',
    label: 'i–VI–VII',
    degrees: [1, 6, 7],
    subgenreId: 'hh_modern',
  ),
  ProgressionTemplate(
    id: 'hh_modern_17',
    label: 'i–VII',
    degrees: [1, 7],
    subgenreId: 'hh_modern',
  ),
  ProgressionTemplate(
    id: 'hh_modern_1376',
    label: 'i–III–VII–VI',
    degrees: [1, 3, 7, 6],
    subgenreId: 'hh_modern',
  ),
  ProgressionTemplate(
    id: 'hh_modern_1736',
    label: 'i–VII–III–VI',
    degrees: [1, 7, 3, 6],
    subgenreId: 'hh_modern',
  ),
  ProgressionTemplate(
    id: 'hh_modern_1641',
    label: 'i–VI–iv–i',
    degrees: [1, 6, 4, 1],
    subgenreId: 'hh_modern',
  ),
  ProgressionTemplate(
    id: 'hh_modern_1716',
    label: 'i–VII–i–VI',
    degrees: [1, 7, 1, 6],
    subgenreId: 'hh_modern',
  ),
  ProgressionTemplate(
    id: 'hh_modern_1467',
    label: 'i–iv–VI–VII',
    degrees: [1, 4, 6, 7],
    subgenreId: 'hh_modern',
  ),

  // trap_main
  ProgressionTemplate(
    id: 'trap_main_1637',
    label: 'i–VI–III–VII',
    degrees: [1, 6, 3, 7],
    subgenreId: 'trap_main',
  ),
  ProgressionTemplate(
    id: 'trap_main_167',
    label: 'i–VI–VII',
    degrees: [1, 6, 7],
    subgenreId: 'trap_main',
  ),
  ProgressionTemplate(
    id: 'trap_main_176',
    label: 'i–VII–VI',
    degrees: [1, 7, 6],
    subgenreId: 'trap_main',
  ),
  ProgressionTemplate(
    id: 'trap_main_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'trap_main',
  ),
  ProgressionTemplate(
    id: 'trap_main_276',
    label: 'i–II–VII–VI',
    degrees: [1, 2, 7, 6],
    subgenreId: 'trap_main',
  ),
  ProgressionTemplate(
    id: 'trap_main_171',
    label: 'i–VII–i',
    degrees: [1, 7, 1],
    subgenreId: 'trap_main',
  ),
  ProgressionTemplate(
    id: 'trap_main_137',
    label: 'i–III–VII',
    degrees: [1, 3, 7],
    subgenreId: 'trap_main',
  ),
  ProgressionTemplate(
    id: 'trap_main_1471',
    label: 'i–iv–VII–i',
    degrees: [1, 4, 7, 1],
    subgenreId: 'trap_main',
  ),
  ProgressionTemplate(
    id: 'trap_main_1671',
    label: 'i–VI–VII–i',
    degrees: [1, 6, 7, 1],
    subgenreId: 'trap_main',
  ),
  ProgressionTemplate(
    id: 'trap_main_1736',
    label: 'i–VII–III–VI',
    degrees: [1, 7, 3, 6],
    subgenreId: 'trap_main',
  ),
  ProgressionTemplate(
    id: 'trap_main_1647',
    label: 'i–VI–iv–VII',
    degrees: [1, 6, 4, 7],
    subgenreId: 'trap_main',
  ),

  // trap_halftime
  ProgressionTemplate(
    id: 'trap_halftime_1637',
    label: 'i–VI–III–VII',
    degrees: [1, 6, 3, 7],
    subgenreId: 'trap_halftime',
  ),
  ProgressionTemplate(
    id: 'trap_halftime_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'trap_halftime',
  ),
  ProgressionTemplate(
    id: 'trap_halftime_167',
    label: 'i–VI–VII',
    degrees: [1, 6, 7],
    subgenreId: 'trap_halftime',
  ),
  ProgressionTemplate(
    id: 'trap_halftime_171',
    label: 'i–VII–i',
    degrees: [1, 7, 1],
    subgenreId: 'trap_halftime',
  ),
  ProgressionTemplate(
    id: 'trap_halftime_1376',
    label: 'i–III–VII–VI',
    degrees: [1, 3, 7, 6],
    subgenreId: 'trap_halftime',
  ),
  ProgressionTemplate(
    id: 'trap_halftime_1471',
    label: 'i–iv–VII–i',
    degrees: [1, 4, 7, 1],
    subgenreId: 'trap_halftime',
  ),
  ProgressionTemplate(
    id: 'trap_halftime_1761',
    label: 'i–VII–VI–i',
    degrees: [1, 7, 6, 1],
    subgenreId: 'trap_halftime',
  ),
  ProgressionTemplate(
    id: 'trap_halftime_1647',
    label: 'i–VI–iv–VII',
    degrees: [1, 6, 4, 7],
    subgenreId: 'trap_halftime',
  ),
  ProgressionTemplate(
    id: 'trap_halftime_1736',
    label: 'i–VII–III–VI',
    degrees: [1, 7, 3, 6],
    subgenreId: 'trap_halftime',
  ),
  ProgressionTemplate(
    id: 'trap_halftime_1636',
    label: 'i–VI–III–VI',
    degrees: [1, 6, 3, 6],
    subgenreId: 'trap_halftime',
  ),
  ProgressionTemplate(
    id: 'trap_halftime_17',
    label: 'i–VII',
    degrees: [1, 7],
    subgenreId: 'trap_halftime',
  ),

  // pop_radio
  pop1564Preset,
  sad6415Preset,
  ProgressionTemplate(
    id: 'pop_radio_1645',
    label: 'I–vi–IV–V',
    degrees: [1, 6, 4, 5],
    subgenreId: 'pop_radio',
  ),
  ProgressionTemplate(
    id: 'pop_radio_4156',
    label: 'IV–I–V–vi',
    degrees: [4, 1, 5, 6],
    subgenreId: 'pop_radio',
  ),
  ProgressionTemplate(
    id: 'pop_radio_1465',
    label: 'I–IV–vi–V',
    degrees: [1, 4, 6, 5],
    subgenreId: 'pop_radio',
  ),
  ProgressionTemplate(
    id: 'pop_radio_1364',
    label: 'I–iii–vi–IV',
    degrees: [1, 3, 6, 4],
    subgenreId: 'pop_radio',
  ),
  ProgressionTemplate(
    id: 'pop_radio_6154',
    label: 'vi–I–V–IV',
    degrees: [6, 1, 5, 4],
    subgenreId: 'pop_radio',
  ),
  ProgressionTemplate(
    id: 'pop_radio_1545',
    label: 'I–V–IV–V',
    degrees: [1, 5, 4, 5],
    subgenreId: 'pop_radio',
  ),
  ProgressionTemplate(
    id: 'pop_radio_1625',
    label: 'I–vi–ii–V',
    degrees: [1, 6, 2, 5],
    subgenreId: 'pop_radio',
  ),
  ProgressionTemplate(
    id: 'pop_radio_1415',
    label: 'I–IV–I–V',
    degrees: [1, 4, 1, 5],
    subgenreId: 'pop_radio',
  ),
  ProgressionTemplate(
    id: 'pop_radio_4515',
    label: 'IV–V–I–V',
    degrees: [4, 5, 1, 5],
    subgenreId: 'pop_radio',
  ),

  // pop_anthem
  canon1563Preset,
  ProgressionTemplate(
    id: 'pop_anthem_1564',
    label: 'I–V–vi–IV',
    degrees: [1, 5, 6, 4],
    subgenreId: 'pop_anthem',
  ),
  ProgressionTemplate(
    id: 'pop_anthem_6415',
    label: 'vi–IV–I–V',
    degrees: [6, 4, 1, 5],
    subgenreId: 'pop_anthem',
  ),
  ProgressionTemplate(
    id: 'pop_anthem_1645',
    label: 'I–vi–IV–V',
    degrees: [1, 6, 4, 5],
    subgenreId: 'pop_anthem',
  ),
  ProgressionTemplate(
    id: 'pop_anthem_4156',
    label: 'IV–I–V–vi',
    degrees: [4, 1, 5, 6],
    subgenreId: 'pop_anthem',
  ),
  ProgressionTemplate(
    id: 'pop_anthem_1465',
    label: 'I–IV–vi–V',
    degrees: [1, 4, 6, 5],
    subgenreId: 'pop_anthem',
  ),
  ProgressionTemplate(
    id: 'pop_anthem_1545',
    label: 'I–V–IV–V',
    degrees: [1, 5, 4, 5],
    subgenreId: 'pop_anthem',
  ),
  ProgressionTemplate(
    id: 'pop_anthem_4515',
    label: 'IV–V–I–V',
    degrees: [4, 5, 1, 5],
    subgenreId: 'pop_anthem',
  ),
  ProgressionTemplate(
    id: 'pop_anthem_1514',
    label: 'I–V–I–IV',
    degrees: [1, 5, 1, 4],
    subgenreId: 'pop_anthem',
  ),
  ProgressionTemplate(
    id: 'pop_anthem_1625',
    label: 'I–vi–ii–V',
    degrees: [1, 6, 2, 5],
    subgenreId: 'pop_anthem',
  ),
  ProgressionTemplate(
    id: 'pop_anthem_1364',
    label: 'I–iii–vi–IV',
    degrees: [1, 3, 6, 4],
    subgenreId: 'pop_anthem',
  ),

  // rnb_quiet
  ProgressionTemplate(
    id: 'rnb_quiet_1625',
    label: 'I–vi–ii–V',
    degrees: [1, 6, 2, 5],
    subgenreId: 'rnb_quiet',
  ),
  ProgressionTemplate(
    id: 'rnb_quiet_6415',
    label: 'vi–IV–I–V',
    degrees: [6, 4, 1, 5],
    subgenreId: 'rnb_quiet',
  ),
  ProgressionTemplate(
    id: 'rnb_quiet_1564',
    label: 'I–V–vi–IV',
    degrees: [1, 5, 6, 4],
    subgenreId: 'rnb_quiet',
  ),
  ProgressionTemplate(
    id: 'rnb_quiet_2516',
    label: 'ii–V–I–vi',
    degrees: [2, 5, 1, 6],
    subgenreId: 'rnb_quiet',
  ),
  ProgressionTemplate(
    id: 'rnb_quiet_1436',
    label: 'I–IV–iii–vi',
    degrees: [1, 4, 3, 6],
    subgenreId: 'rnb_quiet',
  ),
  ProgressionTemplate(
    id: 'rnb_quiet_1645',
    label: 'I–vi–IV–V',
    degrees: [1, 6, 4, 5],
    subgenreId: 'rnb_quiet',
  ),
  ProgressionTemplate(
    id: 'rnb_quiet_6251',
    label: 'vi–ii–V–I',
    degrees: [6, 2, 5, 1],
    subgenreId: 'rnb_quiet',
  ),
  ProgressionTemplate(
    id: 'rnb_quiet_1364',
    label: 'I–iii–vi–IV',
    degrees: [1, 3, 6, 4],
    subgenreId: 'rnb_quiet',
  ),
  ProgressionTemplate(
    id: 'rnb_quiet_4136',
    label: 'IV–I–iii–vi',
    degrees: [4, 1, 3, 6],
    subgenreId: 'rnb_quiet',
  ),
  ProgressionTemplate(
    id: 'rnb_quiet_1463',
    label: 'I–IV–vi–iii',
    degrees: [1, 4, 6, 3],
    subgenreId: 'rnb_quiet',
  ),
  ProgressionTemplate(
    id: 'rnb_quiet_6425',
    label: 'vi–IV–ii–V',
    degrees: [6, 4, 2, 5],
    subgenreId: 'rnb_quiet',
  ),

  // rnb_alt
  jazz2511Preset,
  ProgressionTemplate(
    id: 'rnb_alt_1625',
    label: 'I–vi–ii–V',
    degrees: [1, 6, 2, 5],
    subgenreId: 'rnb_alt',
  ),
  ProgressionTemplate(
    id: 'rnb_alt_6415',
    label: 'vi–IV–I–V',
    degrees: [6, 4, 1, 5],
    subgenreId: 'rnb_alt',
  ),
  ProgressionTemplate(
    id: 'rnb_alt_2516',
    label: 'ii–V–I–vi',
    degrees: [2, 5, 1, 6],
    subgenreId: 'rnb_alt',
  ),
  ProgressionTemplate(
    id: 'rnb_alt_1436',
    label: 'I–IV–iii–vi',
    degrees: [1, 4, 3, 6],
    subgenreId: 'rnb_alt',
  ),
  ProgressionTemplate(
    id: 'rnb_alt_3625',
    label: 'iii–vi–ii–V',
    degrees: [3, 6, 2, 5],
    subgenreId: 'rnb_alt',
  ),
  ProgressionTemplate(
    id: 'rnb_alt_1364',
    label: 'I–iii–vi–IV',
    degrees: [1, 3, 6, 4],
    subgenreId: 'rnb_alt',
  ),
  ProgressionTemplate(
    id: 'rnb_alt_6251',
    label: 'vi–ii–V–I',
    degrees: [6, 2, 5, 1],
    subgenreId: 'rnb_alt',
  ),
  ProgressionTemplate(
    id: 'rnb_alt_4362',
    label: 'IV–iii–vi–ii',
    degrees: [4, 3, 6, 2],
    subgenreId: 'rnb_alt',
  ),
  ProgressionTemplate(
    id: 'rnb_alt_1634',
    label: 'I–vi–iii–IV',
    degrees: [1, 6, 3, 4],
    subgenreId: 'rnb_alt',
  ),
  ProgressionTemplate(
    id: 'rnb_alt_2564',
    label: 'ii–V–vi–IV',
    degrees: [2, 5, 6, 4],
    subgenreId: 'rnb_alt',
  ),

  // rock_straight
  blues1451Preset,
  loop1Preset,
  ProgressionTemplate(
    id: 'rock_straight_1415',
    label: 'I–IV–I–V',
    degrees: [1, 4, 1, 5],
    subgenreId: 'rock_straight',
  ),
  ProgressionTemplate(
    id: 'rock_straight_1541',
    label: 'I–V–IV–I',
    degrees: [1, 5, 4, 1],
    subgenreId: 'rock_straight',
  ),
  ProgressionTemplate(
    id: 'rock_straight_1454',
    label: 'I–IV–V–IV',
    degrees: [1, 4, 5, 4],
    subgenreId: 'rock_straight',
  ),
  ProgressionTemplate(
    id: 'rock_straight_1564',
    label: 'I–V–vi–IV',
    degrees: [1, 5, 6, 4],
    subgenreId: 'rock_straight',
  ),
  ProgressionTemplate(
    id: 'rock_straight_1741',
    label: 'I–VII–IV–I',
    degrees: [1, 7, 4, 1],
    subgenreId: 'rock_straight',
  ),
  ProgressionTemplate(
    id: 'rock_straight_1465',
    label: 'I–IV–vi–V',
    degrees: [1, 4, 6, 5],
    subgenreId: 'rock_straight',
  ),
  ProgressionTemplate(
    id: 'rock_straight_6415',
    label: 'vi–IV–I–V',
    degrees: [6, 4, 1, 5],
    subgenreId: 'rock_straight',
  ),
  ProgressionTemplate(
    id: 'rock_straight_1545',
    label: 'I–V–IV–V',
    degrees: [1, 5, 4, 5],
    subgenreId: 'rock_straight',
  ),
  ProgressionTemplate(
    id: 'rock_straight_1645',
    label: 'I–vi–IV–V',
    degrees: [1, 6, 4, 5],
    subgenreId: 'rock_straight',
  ),

  // rock_drive
  ProgressionTemplate(
    id: 'rock_drive_1564',
    label: 'I–V–vi–IV',
    degrees: [1, 5, 6, 4],
    subgenreId: 'rock_drive',
  ),
  ProgressionTemplate(
    id: 'rock_drive_1451',
    label: 'I–IV–V–I',
    degrees: [1, 4, 5, 1],
    subgenreId: 'rock_drive',
  ),
  ProgressionTemplate(
    id: 'rock_drive_1741',
    label: 'I–VII–IV–I',
    degrees: [1, 7, 4, 1],
    subgenreId: 'rock_drive',
  ),
  ProgressionTemplate(
    id: 'rock_drive_6415',
    label: 'vi–IV–I–V',
    degrees: [6, 4, 1, 5],
    subgenreId: 'rock_drive',
  ),
  ProgressionTemplate(
    id: 'rock_drive_1415',
    label: 'I–IV–I–V',
    degrees: [1, 4, 1, 5],
    subgenreId: 'rock_drive',
  ),
  ProgressionTemplate(
    id: 'rock_drive_1545',
    label: 'I–V–IV–V',
    degrees: [1, 5, 4, 5],
    subgenreId: 'rock_drive',
  ),
  ProgressionTemplate(
    id: 'rock_drive_1645',
    label: 'I–vi–IV–V',
    degrees: [1, 6, 4, 5],
    subgenreId: 'rock_drive',
  ),
  ProgressionTemplate(
    id: 'rock_drive_4151',
    label: 'IV–I–V–I',
    degrees: [4, 1, 5, 1],
    subgenreId: 'rock_drive',
  ),
  ProgressionTemplate(
    id: 'rock_drive_1514',
    label: 'I–V–I–IV',
    degrees: [1, 5, 1, 4],
    subgenreId: 'rock_drive',
  ),
  ProgressionTemplate(
    id: 'rock_drive_6541',
    label: 'vi–V–IV–I',
    degrees: [6, 5, 4, 1],
    subgenreId: 'rock_drive',
  ),
  ProgressionTemplate(
    id: 'rock_drive_1465',
    label: 'I–IV–vi–V',
    degrees: [1, 4, 6, 5],
    subgenreId: 'rock_drive',
  ),

  // reg_skank
  ProgressionTemplate(
    id: 'reg_skank_1564',
    label: 'I–V–vi–IV',
    degrees: [1, 5, 6, 4],
    subgenreId: 'reg_skank',
  ),
  ProgressionTemplate(
    id: 'reg_skank_145',
    label: 'I–IV–V',
    degrees: [1, 4, 5],
    subgenreId: 'reg_skank',
  ),
  ProgressionTemplate(
    id: 'reg_skank_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'reg_skank',
  ),
  ProgressionTemplate(
    id: 'reg_skank_1741',
    label: 'I–VII–IV–I',
    degrees: [1, 7, 4, 1],
    subgenreId: 'reg_skank',
  ),
  ProgressionTemplate(
    id: 'reg_skank_1415',
    label: 'I–IV–I–V',
    degrees: [1, 4, 1, 5],
    subgenreId: 'reg_skank',
  ),
  ProgressionTemplate(
    id: 'reg_skank_1541',
    label: 'I–V–IV–I',
    degrees: [1, 5, 4, 1],
    subgenreId: 'reg_skank',
  ),
  ProgressionTemplate(
    id: 'reg_skank_6415',
    label: 'vi–IV–I–V',
    degrees: [6, 4, 1, 5],
    subgenreId: 'reg_skank',
  ),
  ProgressionTemplate(
    id: 'reg_skank_1645',
    label: 'I–vi–IV–V',
    degrees: [1, 6, 4, 5],
    subgenreId: 'reg_skank',
  ),
  ProgressionTemplate(
    id: 'reg_skank_1464',
    label: 'I–IV–vi–IV',
    degrees: [1, 4, 6, 4],
    subgenreId: 'reg_skank',
  ),
  ProgressionTemplate(
    id: 'reg_skank_1514',
    label: 'I–V–I–IV',
    degrees: [1, 5, 1, 4],
    subgenreId: 'reg_skank',
  ),
  ProgressionTemplate(
    id: 'reg_skank_1671',
    label: 'i–VI–VII–i',
    degrees: [1, 6, 7, 1],
    subgenreId: 'reg_skank',
  ),

  // reg_dancehall
  ProgressionTemplate(
    id: 'reg_dancehall_1564',
    label: 'I–V–vi–IV',
    degrees: [1, 5, 6, 4],
    subgenreId: 'reg_dancehall',
  ),
  ProgressionTemplate(
    id: 'reg_dancehall_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'reg_dancehall',
  ),
  ProgressionTemplate(
    id: 'reg_dancehall_1451',
    label: 'I–IV–V–I',
    degrees: [1, 4, 5, 1],
    subgenreId: 'reg_dancehall',
  ),
  ProgressionTemplate(
    id: 'reg_dancehall_1637',
    label: 'i–VI–III–VII',
    degrees: [1, 6, 3, 7],
    subgenreId: 'reg_dancehall',
  ),
  ProgressionTemplate(
    id: 'reg_dancehall_1741',
    label: 'I–VII–IV–I',
    degrees: [1, 7, 4, 1],
    subgenreId: 'reg_dancehall',
  ),
  ProgressionTemplate(
    id: 'reg_dancehall_6415',
    label: 'vi–IV–I–V',
    degrees: [6, 4, 1, 5],
    subgenreId: 'reg_dancehall',
  ),
  ProgressionTemplate(
    id: 'reg_dancehall_1465',
    label: 'I–IV–vi–V',
    degrees: [1, 4, 6, 5],
    subgenreId: 'reg_dancehall',
  ),
  ProgressionTemplate(
    id: 'reg_dancehall_1761',
    label: 'i–VII–VI–i',
    degrees: [1, 7, 6, 1],
    subgenreId: 'reg_dancehall',
  ),
  ProgressionTemplate(
    id: 'reg_dancehall_1545',
    label: 'I–V–IV–V',
    degrees: [1, 5, 4, 5],
    subgenreId: 'reg_dancehall',
  ),
  ProgressionTemplate(
    id: 'reg_dancehall_1671',
    label: 'i–VI–VII–i',
    degrees: [1, 6, 7, 1],
    subgenreId: 'reg_dancehall',
  ),
  ProgressionTemplate(
    id: 'reg_dancehall_1645',
    label: 'I–vi–IV–V',
    degrees: [1, 6, 4, 5],
    subgenreId: 'reg_dancehall',
  ),

  // lat_tresillo
  ProgressionTemplate(
    id: 'lat_tresillo_1454',
    label: 'I–IV–V–IV',
    degrees: [1, 4, 5, 4],
    subgenreId: 'lat_tresillo',
  ),
  ProgressionTemplate(
    id: 'lat_tresillo_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'lat_tresillo',
  ),
  ProgressionTemplate(
    id: 'lat_tresillo_1564',
    label: 'I–V–vi–IV',
    degrees: [1, 5, 6, 4],
    subgenreId: 'lat_tresillo',
  ),
  ProgressionTemplate(
    id: 'lat_tresillo_251',
    label: 'ii–V–I',
    degrees: [2, 5, 1],
    subgenreId: 'lat_tresillo',
  ),
  ProgressionTemplate(
    id: 'lat_tresillo_1415',
    label: 'I–IV–I–V',
    degrees: [1, 4, 1, 5],
    subgenreId: 'lat_tresillo',
  ),
  ProgressionTemplate(
    id: 'lat_tresillo_1645',
    label: 'I–vi–IV–V',
    degrees: [1, 6, 4, 5],
    subgenreId: 'lat_tresillo',
  ),
  ProgressionTemplate(
    id: 'lat_tresillo_6415',
    label: 'vi–IV–I–V',
    degrees: [6, 4, 1, 5],
    subgenreId: 'lat_tresillo',
  ),
  ProgressionTemplate(
    id: 'lat_tresillo_1545',
    label: 'I–V–IV–V',
    degrees: [1, 5, 4, 5],
    subgenreId: 'lat_tresillo',
  ),
  ProgressionTemplate(
    id: 'lat_tresillo_1465',
    label: 'I–IV–vi–V',
    degrees: [1, 4, 6, 5],
    subgenreId: 'lat_tresillo',
  ),
  ProgressionTemplate(
    id: 'lat_tresillo_2564',
    label: 'ii–V–vi–IV',
    degrees: [2, 5, 6, 4],
    subgenreId: 'lat_tresillo',
  ),
  ProgressionTemplate(
    id: 'lat_tresillo_1514',
    label: 'I–V–I–IV',
    degrees: [1, 5, 1, 4],
    subgenreId: 'lat_tresillo',
  ),

  // lat_clave
  ProgressionTemplate(
    id: 'lat_clave_1454',
    label: 'I–IV–V–IV',
    degrees: [1, 4, 5, 4],
    subgenreId: 'lat_clave',
  ),
  ProgressionTemplate(
    id: 'lat_clave_1767',
    label: 'i–VII–VI–VII',
    degrees: [1, 7, 6, 7],
    subgenreId: 'lat_clave',
  ),
  ProgressionTemplate(
    id: 'lat_clave_1564',
    label: 'I–V–vi–IV',
    degrees: [1, 5, 6, 4],
    subgenreId: 'lat_clave',
  ),
  ProgressionTemplate(
    id: 'lat_clave_2515',
    label: 'ii–V–I–V',
    degrees: [2, 5, 1, 5],
    subgenreId: 'lat_clave',
  ),
  ProgressionTemplate(
    id: 'lat_clave_1645',
    label: 'I–vi–IV–V',
    degrees: [1, 6, 4, 5],
    subgenreId: 'lat_clave',
  ),
  ProgressionTemplate(
    id: 'lat_clave_6415',
    label: 'vi–IV–I–V',
    degrees: [6, 4, 1, 5],
    subgenreId: 'lat_clave',
  ),
  ProgressionTemplate(
    id: 'lat_clave_1415',
    label: 'I–IV–I–V',
    degrees: [1, 4, 1, 5],
    subgenreId: 'lat_clave',
  ),
  ProgressionTemplate(
    id: 'lat_clave_1541',
    label: 'I–V–IV–I',
    degrees: [1, 5, 4, 1],
    subgenreId: 'lat_clave',
  ),
  ProgressionTemplate(
    id: 'lat_clave_2516',
    label: 'ii–V–I–vi',
    degrees: [2, 5, 1, 6],
    subgenreId: 'lat_clave',
  ),
  ProgressionTemplate(
    id: 'lat_clave_1464',
    label: 'I–IV–vi–IV',
    degrees: [1, 4, 6, 4],
    subgenreId: 'lat_clave',
  ),
  ProgressionTemplate(
    id: 'lat_clave_1741',
    label: 'I–VII–IV–I',
    degrees: [1, 7, 4, 1],
    subgenreId: 'lat_clave',
  ),
];
