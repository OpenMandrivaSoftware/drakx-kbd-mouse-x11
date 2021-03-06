package keyboard; # $Id$

use diagnostics;
use strict;

#-######################################################################################
#- misc imports
#-######################################################################################
use common;
use detect_devices;
use run_program;
use lang;
use log;
use c;
use bootloader;

#-######################################################################################
#- Globals
#-######################################################################################
my $KMAP_MAGIC = 0x8B39C07F;
my $localectl = "/usr/bin/localectl";

#- a best guess of the keyboard layout, based on the choosen locale
#- beware only the first 5 characters of the locale are used
our %lang2keyboard =
(
  'af'  => 'us_intl',
  'am'  => 'us:90',
  'ar'  => 'ara:90',
  'as'  => 'ben:90 ben2:80 us_intl:5',
  'ast' => 'es:85 lat:80 us_intl:50 ast:20',
  'az'  => 'az:90 tr_q:10 us_intl:5',
'az_IR' => 'ir:90',
  'be'  => 'by:90 ru:50 ru_yawerty:40',
  'ber' => 'tifinagh:80 tifinagh_p:70',
  'bg'  => 'bg_phonetic:60 bg:50',
  'bn'  => 'ben:90 ben2:80 dev:20 us_intl:5',
  'bo'	=> 'bt',
  'br'  => 'fr:90',
  'bs'  => 'bs:90',
  'ca'  => 'es:90 fr:15',
  'ca@valencian'  => 'es',
  'chr' => 'chr:80 us:60 us_intl:60',
  'cs'  => 'cz_qwerty:70 cz:50',
  'cy'  => 'gb:89 us:60 us_intl:50 dvorak_gb:10 fr:1',
  'da'  => 'dk:90',
  'de'  => 'de:70 de_nodeadkeys:50 be:50 ch_de:50',
  'dz'	=> 'bt',
  'el'  => 'gr:90',
  'en'  => 'us:89 us3:80 us_intl:50 qc:50 gb:50 dvorak:10',
'en_AU' => 'us:80 us3:70 us_intl:50 gb:40 dvorak:10 dvorak_gb:5',
'en_CA' => 'us:80 us3:70 us_intl:50 qc:50 gb:40 dvorak:10',
'en_GB' => 'gb:89 us:60 us_intl:50 dvorak_gb:10',
'en_IE' => 'ie:80 gb:70 dvorak_gb:10',
'en_NG' => 'ng:80 us:60',
'en_NZ' => 'us:80 us3:70 us_intl:50 gb:40 dvorak:10 dvorak_gb:5',
'en_US' => 'us:89 us3:80 us_intl:50 dvorak:10 us_mac:5',
  'eo'  => 'us_intl:89 dvorak_eo:30 dvorak:10',
  'es'  => 'es:85 lat:80 us_intl:50',
  'et'  => 'ee:90',
  'eu'  => 'es:90 fr:15',
  'fa'  => 'ir:90',
  'fi'  => 'fi:90',
  'fo'  => 'fo:80 is:70 dk:60',
  'fr'  => 'fr:89 qc:85 be:85 ch_fr:70 dvorak_fr:20 fr_bepo:10 fr_bepo_latin9:10',
'fr_CA' => 'qc:89',
'fr_CH' => 'ch_fr:89',
'fr_BE' => 'be:89',
  'fur' => 'it:90',
  'ga'  => 'ie:80 gb:70 dvorak_gb:10',
  'gd'  => 'gb:80 ie:70 dvorak_gb:10',
  'gl'  => 'es:90',
  'gn'  => 'lat:85 es:80 us_intl:50',
  'gu'  => 'guj:90',
  'gv'  => 'gb:80 ie:70',
  'ha'  => 'ng',
  'he'  => 'il:90 il_phonetic:10',
  'hi'  => 'dev:90',
  'hr'  => 'hr:90 si:50',
  'hu'  => 'hu:90',
  'hy'  => 'am:90 am_old:10 am_phonetic:5',
  'ia'  => 'us:90 us_intl:20',
  'id'  => 'us:90 us_intl:20',
  'ig'  => 'ng',
  'is'  => 'is:90',
  'it'  => 'it:90 ch_fr:50 ch_de:50',
  'iu'  => 'iku:90',
  'ja'  => 'jp:90',
  'ka'  => 'ge_la:90 ge_ru:50',
  'kl'  => 'dk:80 us_intl:30',
  'kn'  => 'kan:90',
  'ko'  => 'kr:90 us:60',
  'ku'  => 'tr_q:90 tr_f:30',
'ku_IQ' => 'kur:90',
  'kw'  => 'gb:80 ie:70',
  'ky'  => 'kg:90 ru_yawerty:40',
  'lb'  => 'ch_fr:89 be:85 us_intl:70 fr:60 dvorak_fr:20',
  'li'  => 'us_intl:80 be:70 nl:10 us:5',
  'lo'  => 'lao:90',
  'lt'  => 'lt:80',
  'ltg' => 'lv:90 lt:40 ee:5',
  'lv'  => 'lv:90 lt:40 ee:5',
  'mi'  => 'mao:90 gb:30 us_intl:20',
  'mk'  => 'mk:90',
  'ml'  => 'mal:90',
  'mn'  => 'mn:90 ru:20 ru_yawerty:5',
  'mr'  => 'dev:90',
  'ms'  => 'us:90 us_intl:20',
  'mt'  => 'mt:90 mt_us:35 us_intl:10',
  'my'  => 'mm:90',
  'nb'  => 'no:90 dvorak_no:10',
  'nds' => 'de_nodeadkeys:70 de:50 us_intl:40 nl:10 us:5',
  'ne'  => 'dev:90',
  'nl'  => 'us_intl:80 be:70 nl:10 us:5',
  'nn'  => 'no:90 dvorak_no:10',
  'no'  => 'no:90 dvorak_no:10', # for compatiblity only
  'oc'  => 'fr:90',
  'or'  => 'ori:90',
  'pa'  => 'gur:90',
  'ph'  => 'us:90 us_intl:20',
  'pl'  => 'pl:90 pl2:60 dvorak_pl:10',
  'pp'  => 'br:80 lat:20 pt:10 us_intl:30',
  'ps'  => 'pus:80 snd:60',
'pt_BR' => 'br:90 lat:20 pt:10 us_intl:30',
  'pt'  => 'pt:90',
  'ro'  => 'ro:80 ro_qwertz:40 ro_basic:20 us_intl:10',
  'ru'  => 'ru:85 ru_yawerty:80 ua:50',
  'sc'  => 'it:90',
  'sd'  => 'snd:80 ara:20',
  'se'  => 'smi:70 smi_sefi:50',
  'sh'  => 'yu:80',
  'si'  => 'sin',
  'sk'  => 'sk_qwerty:80 sk:70',
  'sl'  => 'si:90 hr:50',
  'sq'  => 'al:90',
  'sr'  => 'srp:80',
  'ss'  => 'us_intl',
  'st'  => 'us_intl',
  'sv'  => 'se:90 fi:30 dvorak_se:10',
  'ta'  => 'tscii:80 tml:20',
  'te'  => 'tel:90',
  'tg'  => 'tj:90 ru_yawerty:40',
  'th'  => 'th:80 th_pat:50 th_tis:60',
  'tk'  => 'tm:80 tr_q:50 tr_f:40',
  'tl'  => 'us:90 us_intl:20',
  'tr'  => 'tr_q:90 tr_f:30',
  'tt'  => 'ru:50 ru_yawerty:40',
  'uk'  => 'ua:90 ru:50 ru_yawerty:40',
  'ur'  => 'urd:80 snd:60 ara:20',
  'uz'  => 'uz:80 ru_yawerty:40',
  'uz\@Cyrl'  => 'uz:80 ru_yawerty:40',
  'uz\@Latn'  => 'us:80 uz:80',
  've'  => 'us_intl',
  'vi'  => 'vn:80 us:70 us_intl:60',
  'wa'  => 'be:90 fr:5',
  'xh'  => 'us_intl',
  'yi'  => 'il_phonetic:90 il:10 us_intl:10',
  'yo'  => 'ng',
'zh_CN' => 'us:90',
'zh_TW' => 'us:90',
  'zu'  => 'us_intl',
);

# USB kbd table
# The numeric values are the bCountryCode field (5th byte)  of HID descriptor
# NOTE: we do not trust when the layout is declared as US layout (0x21)
# as most manufacturers just use that value when selling physical devices
# with different layouts printed on the keys.
my @usb2keyboard =
(
  qw(SKIP ara_SKIP be ca_SKIP qc cz dk fi fr de gr il hu us_intl it jp),
#- 0x10
  qw(kr lat nl no ir pl pt ru sk es se ch_fr ch_de ch_de tw_SKIP tr_q),
#- 0x20
  qw(gb us_SKIP yu tr_f),
#- higher codes not attribued as of 2002-02
);

#- key = extension for Xmodmap file, [0] = description of the keyboard,
#- [1] = name for loadkeys, [2] = layout for XKB, [3] = variant for XKB,
#- [4] = "1" if it is a multigroup layout (eg: one with latin/non-latin letters)
#-
#- note: there seems to be a limit of 4 stackable xkb layouts
my %keyboards = (
 "al"		=> [ N_("_: keyboard\nAlbanian"),			"al",			"al",		"",		0 ],
# "am_old"	=> [ N_("_: keyboard\nArmenian (old)"), 		"am_old",		"am",		"old",		1 ], # X11 variant BROKEN (was: am(old) )
 "am"		=> [ N_("_: keyboard\nArmenian (typewriter)"),		"am-armscii8",		"am",		"",		1 ],
 "am_phonetic"	=> [ N_("_: keyboard\nArmenian (phonetic)"),		"am_phonetic",		"am",		"phonetic",	1 ],
 "ara"		=> [ N_("_: keyboard\nArabic"), 			"us",			"ara",		"digits",	1 ],
 "ast"		=> [ N_("_: keyboard\nAsturian"),			"es-latin1",		"es",		"ast",		0 ],
 "az"		=> [ N_("_: keyboard\nAzerbaidjani (latin)"),		"az",			"az",		"",		0 ],
 "be"		=> [ N_("_: keyboard\nBelgian"),			"be2-latin1",		"be",		"",		0 ],
 "ben"		=> [ N_("_: keyboard\nBengali (Inscript-layout)"),	"us",			"in",		"ben",		1 ],
 "ben2" 	=> [ N_("_: keyboard\nBengali (Probhat)"),		"us",			"in",		"ben_probhat",	1 ],
 "bg_phonetic"	=> [ N_("_: keyboard\nBulgarian (phonetic)"),		"bg",			"bg",		"phonetic",	1 ],
 "bg"		=> [ N_("_: keyboard\nBulgarian (BDS)"),		"bg_bds",		"bg",		"",		1 ],
 "br"		=> [ N_("_: keyboard\nBrazilian (ABNT-2)"),		"br-abnt2",		"br",		"",		0 ],
 "bs"		=> [ N_("_: keyboard\nBosnian"),			"croat",		"ba",		"",		0 ],
 "bt"		=> [ N_("_: keyboard\nDzongkha/Tibetan"),		"us",			"bt",		"",		1 ],
 "by"		=> [ N_("_: keyboard\nBelarusian"),			"by-cp1251",		"by",		"",		1 ],
 "ch_de"	=> [ N_("_: keyboard\nSwiss (German layout)"),		"sg-latin1",		"ch",		"de",		0 ],
 "ch_fr"	=> [ N_("_: keyboard\nSwiss (French layout)"),		"fr_CH-latin1", 	"ch",		"fr",		0 ],
# TODO: console map
# "chr"		=> [ N_("_: keyboard\nCherokee syllabics"),		"us",			"chr",		"",		1 ], # BROKEN
 "cz"		=> [ N_("_: keyboard\nCzech (QWERTZ)"), 		"cz",			"cz",		"",		0 ],
 "cz_qwerty"	=> [ N_("_: keyboard\nCzech (QWERTY)"), 		"cz-lat2",		"cz",		"qwerty",	0 ],
 "de"		=> [ N_("_: keyboard\nGerman"), 			"de-latin1",		"de",		"",		0 ],
 "de_nodeadkeys"=> [ N_("_: keyboard\nGerman (no dead keys)"),		"de-latin1-nodeadkeys", "de",		"nodeadkeys",	0 ],
 "dev"		=> [ N_("_: keyboard\nDevanagari"),			"us",			"in",		"deva", 	1 ],
 "dk"		=> [ N_("_: keyboard\nDanish"), 			"dk-latin1",		"dk",		"",		0 ],
 "dvorak"	=> [ N_("_: keyboard\nDvorak (US)"),			"pc-dvorak-latin1",	"us",		"dvorak",	0 ],
# "dvorak_eo"	=> [ N_("_: keyboard\nDvorak (Esperanto)"),		"eo-dvorak",		"dvorak",	"eo",		0 ], # BROKEN
 "dvorak_fr"	=> [ N_("_: keyboard\nDvorak (French)"),		"fr-dvorak",		"fr",		"dvorak",	0 ],
 "dvorak_gb"	=> [ N_("_: keyboard\nDvorak (UK)"),			"pc-dvorak-latin1",	"gb",		"dvorak",	0 ],
 "dvorak_no"	=> [ N_("_: keyboard\nDvorak (Norwegian)"),		"no-dvorak",		"no",		"dvorak",	0 ],
 "dvorak_pl"	=> [ N_("_: keyboard\nDvorak (Polish)"),		"pl-dvorak",		"pl",		"dvorak",	0 ],
 "dvorak_se"	=> [ N_("_: keyboard\nDvorak (Swedish)"),		"se-dvorak",		"se",		"dvorak",	0 ],
 "ee"		=> [ N_("_: keyboard\nEstonian"),			"ee-latin9",		"ee",		"",		0 ],
 "es"		=> [ N_("_: keyboard\nSpanish"),			"es-latin1",		"es",		"",		0 ],
 "fi"		=> [ N_("_: keyboard\nFinnish"),			"fi-latin1",		"fi",		"",		0 ],
 "fo"		=> [ N_("_: keyboard\nFaroese"),			"is-latin1",		"fo",		"",		0 ],
 "fr"		=> [ N_("_: keyboard\nFrench"), 			"fr-latin1",		"fr",		"",		0 ],
 "fr_bepo"	=> [ N_("_: keyboard\nFrench (Bepo)"),			"fr-bepo",		"fr",		"bepo", 	0 ],
 "fr_bepo_latin9" => [ N_("_: keyboard\nFrench (Bepo, only latin-9)"),	"fr-bepo-latin9",	"fr",		"bepo_latin9",	0 ],
 "gb"		=> [ N_("UK keyboard"), 				"uk-latin1",		"gb",		"",		0 ],
 "ge_ru"	=> [ N_("_: keyboard\nGeorgian (\"Russian\" layout)"),	"ge_ru-georgian_academy", "ge",		"ru",		1 ],
 "ge_la" 	=> [ N_("_: keyboard\nGeorgian (\"Latin\" layout)"),	"ge_la-georgian_academy", "ge", 	"qwerty", 	1 ],
 "gr"		=> [ N_("_: keyboard\nGreek"),				"gr-8859_7",		"gr", 		"extended",	1 ],
 "gr_pl"	=> [ N_("_: keyboard\nGreek (polytonic)"),		"gr-8859_7",		"gr",		"polytonic",	1 ],
 "guj"		=> [ N_("_: keyboard\nGujarati"),			"us",			"in",		"guj",		1 ],
 "gur"		=> [ N_("_: keyboard\nGurmukhi"),			"us",			"in",		"guru", 	1 ],
 "hr"		=> [ N_("_: keyboard\nCroatian"),			"croat",		"hr",		"",		0 ],
 "hu"		=> [ N_("_: keyboard\nHungarian"),			"hu-latin2",		"hu",		"",		0 ],
 "ie"		=> [ N_("_: keyboard\nIrish"),				"uk-latin1",		"ie",		"",		0 ],
 "iku"		=> [ N_("_: keyboard\nInuktitut"),			"us",			"ca",		"ike",		1 ],
 "il"		=> [ N_("_: keyboard\nIsraeli"),			"il-8859_8",		"il",		"",		1 ],
 "il_phonetic"	=> [ N_("_: keyboard\nIsraeli (phonetic)"),		"hebrew",		"il",	 	"phonetic",	1 ],
 "ir"		=> [ N_("_: keyboard\nIranian"),			"ir-isiri_3342",	"ir",		"",		1 ],
 "is"		=> [ N_("_: keyboard\nIcelandic"),			"is-latin1",		"is",		"",		0 ],
 "it"		=> [ N_("_: keyboard\nItalian"),			"it-latin1",		"it",		"",		0 ],
# Japanese keyboard is dual latin/kana; but telling it here shows a
# message to choose the switching key that is misleading, as input methods
# are not automatically enabled when typing in kana
 "jp"		=> [ N_("_: keyboard\nJapanese 106 keys"),		"jp106",		"jp",		"",		0 ],
 "kan"		=> [ N_("_: keyboard\nKannada"),			"us",			"in",		"kan",		1 ],
 "kg"		=> [ N_("_: keyboard\nKyrgyz"), 			"ky",			"kg",		"",		1 ],
 "kr"		=> [ N_("_: keyboard\nKorean"), 			"us",			"kr",		"kr104",	0 ],
# TODO: console map
 "kur"		=> [ N_("_: keyboard\nKurdish (arabic script)"),	"us",			"iq",		"ku_ara",	1 ],
 "lat"		=> [ N_("_: keyboard\nLatin American"), 		"la-latin1",		"latam",	"",		0 ],
# TODO: console map
 "lao"		=> [ N_("_: keyboard\nLaotian"),			"us",			"la",		"",		1 ],
 "lt"		=> [ N_("_: keyboard\nLithuanian"),			"lt-latin7",		"lt,us",	",",		1 ],
 "lv"		=> [ N_("_: keyboard\nLatvian"),			"lv-latin7",		"lv",		"",		0 ],
 "mal"		=> [ N_("_: keyboard\nMalayalam"),			"us",			"in",		"mal",		1 ],
 "mao"		=> [ N_("_: keyboard\nMaori"),				"us",			"mao",		"",		0 ],
 "mk"		=> [ N_("_: keyboard\nMacedonian"),			"mk",			"mk",		"",		1 ],
 "mm"		=> [ N_("_: keyboard\nMyanmar (Burmese)"),		"us",			"mm",		"",		1 ],
 "mn"		=> [ N_("_: keyboard\nMongolian (cyrillic)"),		"us",			"mn",		"",		1 ],
 "mt"		=> [ N_("_: keyboard\nMaltese (UK)"),			"mt",			"mt",		"",		0 ],
 "mt_us"	=> [ N_("_: keyboard\nMaltese (US)"),			"mt_us",		"mt",		"us",		0 ],
 "ng"		=> [ N_("_: keyboard\nNigerian"),			"us",			"ng",		"",		0 ],
 "nl"		=> [ N_("_: keyboard\nDutch"),				"nl-latin1",		"nl",		"",		0 ],
 "no"		=> [ N_("_: keyboard\nNorwegian"),			"no-latin1",		"no",		"",		0 ],
 "ori"		=> [ N_("_: keyboard\nOriya"),				"us",			"in",		"ori",		1 ],
 "pl"		=> [ N_("_: keyboard\nPolish (qwerty layout)"), 	"pl",			"pl",		"",		0 ],
 "pl2"		=> [ N_("_: keyboard\nPolish (qwertz layout)"), 	"pl-latin2",		"pl",		"qwertz",	0 ],
# TODO: console map
 "pus"		=> [ N_("_: keyboard\nPashto"), 			"us",			"af",		"ps",		1 ],
 "pt"		=> [ N_("_: keyboard\nPortuguese"),			"pt-latin1",		"pt",		"",		0 ],
 "qc"		=> [ N_("_: keyboard\nCanadian (Quebec)"),		"qc-latin1",		"ca",		"",		0 ],
 "ro_qwertz"	=> [ N_("_: keyboard\nRomanian (qwertz)"),		"ro2",			"ro",		"winkeys",	0 ],
 "ro"		=> [ N_("_: keyboard\nRomanian (qwerty)"),		"ro",			"ro",		"std_cedilla",	0 ],
 "ro_basic"	=> [ N_("_: keyboard\nRomanian (basic)"),		"ro",			"ro",		"basic",	0 ],
 "ru"		=> [ N_("_: keyboard\nRussian"),			"ru",			"ru",		"",		1 ],
 "ru_yawerty"	=> [ N_("_: keyboard\nRussian (phonetic)"),		"ru-yawerty",		"ru", 		"phonetic",	1 ],
 "se"		=> [ N_("_: keyboard\nSwedish"),			"se-latin1",		"se",		"",		0 ],
 "si"		=> [ N_("_: keyboard\nSlovenian"),			"slovene",		"si",		"",		0 ],
# TODO: console map
 "sin"		=> [ N_("_: keyboard\nSinhala"),			"us",			"lk",		"",		1 ],
 "sk"		=> [ N_("_: keyboard\nSlovakian (QWERTZ)"),		"sk-qwertz",		"sk",		"",		0 ],
 "sk_qwerty"	=> [ N_("_: keyboard\nSlovakian (QWERTY)"),		"sk-qwerty",		"sk",		"qwerty",	0 ],
 "smi"		=> [ N_("_: keyboard\nSaami (norwegian)"),		"no-latin1",		"no",		"smi",		0 ],
 "smi_sefi"	=> [ N_("_: keyboard\nSaami (swedish/finnish)"),	"se-latin1",		"se",		"smi",		0 ],
# TODO: console map
# "snd" 	=> [ N_("_: keyboard\nSindhi"), 			"us", 			"snd", 		"digits", 	1 ], # BROKEN
# TODO: console map
 "srp"		=> [ N_("_: keyboard\nSerbian (cyrillic)"),		"sr",			"srp,srp",	"basic,latin",	1 ],
 "syr"		=> [ N_("_: keyboard\nSyriac"), 			"us",			"sy",		"syc",		1 ],
 "syr_p"	=> [ N_("_: keyboard\nSyriac (phonetic)"),		"us",			"sy",		"syc_phonetic", 1 ],
 "tel"		=> [ N_("_: keyboard\nTelugu"), 			"us",			"in",		"tel",		1 ],
# no console kbd that I'm aware of
 "tml"		=> [ N_("_: keyboard\nTamil (ISCII-layout)"),		"us",			"in",		"tam",		1 ],
 "tscii"	=> [ N_("_: keyboard\nTamil (Typewriter-layout)"),	"us",			"in",		"tam_unicode",	1 ],
 "th"		=> [ N_("_: keyboard\nThai (Kedmanee)"),		"th",			"th",		"",		1 ],
 "th_tis"	=> [ N_("_: keyboard\nThai (TIS-820)"), 		"th",			"th",		"tis",		1 ],
# TODO: console map
 "th_pat" 	=> [ N_("_: keyboard\nThai (Pattachote)"), 		"us", 			"th", 		"pat", 		1 ],
# NOTE: we define a triple layout here
 "tifinagh"	=> [ N_("_: keyboard\nTifinagh (moroccan layout) (+latin/arabic)"), "fr-tifinagh",  "fr,ma,ara", ",tifinagh,azerty",	   1 ],
 "tifinagh_p"	=> [ N_("_: keyboard\nTifinagh (phonetic) (+latin/arabic)"),	    "fr-tifinaghp", "fr,ma,ara", ",tifinagh-phonetic,azerty", 1 ],
# TODO: console map
 "tj" 		=> [ N_("_: keyboard\nTajik"), 				"ru", 			"tj", 		"", 		1 ],
# TODO: console map
 "tm"		=> [ N_("_: keyboard\nTurkmen"),			"us",			"tm",		"",		0 ],
 "tr_f" 	=> [ N_("_: keyboard\nTurkish (\"F\" model)"),		"trf",			"tr",		"f",		0 ],
 "tr_q" 	=> [ N_("_: keyboard\nTurkish (\"Q\" model)"),		"tr_q-latin5",		"tr",		"",		0 ],
#-"tw		=> [ N_("_: keyboard\nChineses bopomofo"),		"tw",			"tw",		"",		1 ],
 "ua"		=> [ N_("_: keyboard\nUkrainian"),			"ua",			"ua",		"",		1 ],
#-"tw => [ N_("_: keyboard\nChineses bopomofo"), "tw",           "tw",    1 ],
 "ua" 		=> [ N_("_: keyboard\nUkrainian"),      		"ua",              	"ua",    			1 ],
# TODO: console map
 "urd"		=> [ N_("_: keyboard\nUrdu keyboard"),			"us",			"pk",		"urd",		1 ],
 "us"		=> [ N_("US keyboard"), 				"us",			"us",		"",		0 ],
 "us_intl"	=> [ N_("US keyboard (international)"), 		"us-intl",		"us",		"alt-intl",	0 ],
 "us_mac"	=> [ N_("US keyboard (Macintosh)"),			"mac-us",		"us",		"mac",		0 ],
 "us3"		=> [ N_("ISO9995-3 (US keyboard with 3 levels per key)"), "us", 		"latin+level3", "ralt_switch",	0 ],
 "uz"		=> [ N_("_: keyboard\nUzbek (cyrillic)"),		"uz",			"uz",		"cyrillic",	1 ],
# old XKB layout
 "vn"		=> [ N_("_: keyboard\nVietnamese \"numeric row\" QWERTY"), "vn-tcvn",		"vn",		"",		0 ],
 "yu"		=> [ N_("_: keyboard\nYugoslavian (latin)"),		"sr",			"srp",		"latin",	0 ],
);

#- list of  possible choices for the key combinations to toggle XKB groups
#- (eg in X86Config file: XkbOptions "grp:toggle")
my %grp_toggles = (
    toggle => N_("Right Alt key"),
    shifts_toggle => N_("Both Shift keys simultaneously"),
    ctrl_shift_toggle => N_("Control and Shift keys simultaneously"),
    caps_toggle => N_("CapsLock key"),
    shift_caps_toggle => N_("Shift and CapsLock keys simultaneously"),
    ctrl_alt_toggle => N_("Ctrl and Alt keys simultaneously"),
    alt_shift_toggle => N_("Alt and Shift keys simultaneously"),
    menu_toggle => N_("\"Menu\" key"),
    lwin_toggle => N_("Left \"Windows\" key"),
    rwin_toggle => N_("Right \"Windows\" key"),
    ctrls_toggle => N_("Both Control keys simultaneously"),
    alts_toggle => N_("Both Alt keys simultaneously"),
    lshift_toggle => N_("Left Shift key"),
    rshift_toggle => N_("Right Shift key"),
    lalt_toggle => N_("Left Alt key"),
    lctrl_toggle => N_("Left Control key"),
    rctrl_toggle => N_("Right Control key"),
);


#-######################################################################################
#- Functions
#-######################################################################################
sub KEYBOARDs() { keys %keyboards }
sub KEYBOARD2text { $keyboards{$_[0]} && $keyboards{$_[0]}[0] }
sub _keyboards() { map { { KEYBOARD => $_ } } keys %keyboards }
sub _keyboard2one {
    my ($keyboard, $nb) = @_;
    ref $keyboard or (detect_devices::is_xbox() ? return undef : internal_error());
    my $l = $keyboards{$keyboard->{KEYBOARD}} or return;
    $l->[$nb];
}
sub keyboard2text { _keyboard2one($_[0], 0) }
sub keyboard2kmap { _keyboard2one($_[0], 1) }
sub _keyboard2xkbl  { _keyboard2one($_[0], 2) }
sub _keyboard2xkbv  { _keyboard2one($_[0], 3) }

sub _xkb2keyboardkey {
    my ($xkb) = @_;
    $xkb =~ s/^us,(.*)$/$1/;
    $xkb =~ /n\/a/ and return;
    my $keyboardkey = "custom";
    foreach (keys %keyboards) {
	$keyboards{$_}[2] eq $xkb and $keyboardkey = $_, last;
    }
    $keyboardkey;
}

sub xkb_models() {
    my $models = _parse_xkb_rules()->{model};
    [ map { $_->[0] } @$models ], { map { @$_ } @$models };
}

sub _grp_toggles {
    my ($keyboard) = @_;
    _keyboard2one($keyboard, 4) or return;
    \%grp_toggles;
}

sub group_toggle_choose {
    my ($in, $keyboard) = @_;

    if (my $grp_toggles = _grp_toggles($keyboard)) {
	my $KEYMAP_TOGGLE = $keyboard->{KEYMAP_TOGGLE} || 'alt_shift_toggle';
	$KEYMAP_TOGGLE = $in->ask_from_listf('', N("Here you can choose the key or key combination that will 
allow switching between the different keyboard layouts
(eg: latin and non latin)"), sub { translate($grp_toggles->{$_[0]}) }, [ sort keys %$grp_toggles ], $KEYMAP_TOGGLE) or return;

        if ($::isInstall && $KEYMAP_TOGGLE ne 'rctrl_toggle') {
	    $in->ask_warn(N("Warning"), formatAlaTeX(
N("This setting will be activated after the installation.
During installation, you will need to use the Right Control
key to switch between the different keyboard layouts.")));
	}
        log::l("KEYMAP_TOGGLE: $KEYMAP_TOGGLE");
        $keyboard->{KEYMAP_TOGGLE} = $KEYMAP_TOGGLE;
    } else {
        $keyboard->{KEYMAP_TOGGLE} = '';
    }
    1;
}

# used by rescue's make_rescue_img:
sub loadkeys_files {
    my ($err) = @_;
    my $archkbd = arch() =~ /i.86|x86_64/ ? "i386" : arch();
    my $p = "/lib/kbd/keymaps/$archkbd";
    my $post = ".map.gz";
    my %trans = ("cz-latin2" => "cz-lat2");
    my %find_file;
    foreach my $dir (all($p)) {
	$find_file{$dir} = '';
	foreach (all("$p/$dir")) {
	    $find_file{$_} and $err->("file $_ is both in $find_file{$_} and $dir") if $err;
	    $find_file{$_} = "$p/$dir/$_";
	}
    }
    my (@l, %l);
    foreach (values %keyboards) {
	local $_ = $trans{$_->[1]} || $_->[1];
	my $l = $find_file{"$_$post"} || $find_file{first(/(..)/) . $post};
	if ($l) {
	    push @l, $l;
	    foreach (`zgrep include $l | grep "^include"`) {
		/include\s+"(.*)"/ or die "bad line $_";
		@l{grep { -e $_ } ("$p/$1.inc.gz")} = ();
	    }
	} else {
	    $err->("invalid loadkeys keytable $_") if $err;
	}
    }
    uniq(@l, keys %l, grep { -e $_ } map { "$p/$_.inc.gz" } qw(compose euro windowkeys linux-keys-bare));
}

sub _unpack_keyboards {
    my ($k) = @_; $k or return;
    [ grep {
	my $b = $keyboards{$_->[0]};
	$b or log::l("bad keyboard $_->[0] in %keyboard::lang2keyboard");
	$b;
    } map { [ split ':' ] } split ' ', $k ];
}
sub lang2keyboards {
    my @li = sort { $b->[1] <=> $a->[1] } map { @$_ } map {
	my $h = lang::analyse_locale_name($_);
	#- example: pt_BR and pt
	my @l = (if_($h->{country}, $h->{main} . '_' . $h->{country}), $h->{main}, 'en');
	my $k = find { $_ } map { $lang2keyboard{$_} } @l;
	_unpack_keyboards($k) || internal_error();
    } @_;
    \@li;
}
sub lang2keyboard {
    my ($l) = @_;

    my $kb = lang2keyboards($l)->[0][0];
    { KEYBOARD => $keyboards{$kb} ? $kb : 'us' }; #- handle incorrect keyboard mapping to us.
}

sub default {
    my ($o_locale) = @_;

    my $keyboard = from_usb() || lang2keyboard(($o_locale || lang::read())->{lang});
    add2hash($keyboard, from_DMI());
    $keyboard;
}

sub from_usb() {
    return if $::noauto;
    my ($usb_kbd) = detect_devices::usbKeyboards() or return;
    my $country_code = detect_devices::usbKeyboard2country_code($usb_kbd) or return;
    my $keyboard = $usb2keyboard[$country_code];
    $keyboard !~ /SKIP/ && { KEYBOARD => $keyboard };
}

sub from_DMI() {
    my $XkbModel = detect_devices::probe_unique_name('XkbModel');
    $XkbModel && { XkbModel => $XkbModel };
}

sub _builtin_loadkeys {
    my ($keymap) = @_;
    return if $::testing;

    my ($magic, $tables_given, @tables) = common::unpack_with_refs('I' . 
								   'i' . c::MAX_NR_KEYMAPS() . 
								   's' . c::NR_KEYS() . '*',
								   $keymap);
    $magic != $KMAP_MAGIC and die "failed to read kmap magic";

    sysopen(my $F, "/dev/console", 2) or die "failed to open /dev/console: $!";

    my $i_tables = 0;
    each_index {
	my $table_index = $::i;
	if (!$_) {
	    #- deallocate table
	    ioctl($F, c::KDSKBENT(), pack("CCS", $table_index, 0, c::K_NOSUCHMAP())) or log::l("removing table $table_index failed: $!");
	} else {
	    each_index {
		ioctl($F, c::KDSKBENT(), pack("CCS", $table_index, $::i, $_)) or log::l("keymap ioctl failed ($table_index $::i $_): $!");
	    } @{$tables[$i_tables++]};
	}
    } @$tables_given;
}

sub _parse_xkb_rules() {
    my $cat;
    my %l;
    my $lst_file = "$::prefix/usr/share/X11/xkb/rules/xorg.lst";
    foreach (cat_($lst_file)) {
	next if m!^\s*//! || m!^\s*$!;
	chomp;
	if (/^!\s*(\S+)$/) {
	    $cat = $1;
	} elsif (/^\s*(\w\S*)\s+(.*)/) {
	    push @{$l{$cat}}, [ $1, $2 ];
	} else {
	    log::l("_parse_xkb_rules:$lst_file: bad line $_");
	}
    }
    \%l;
}

sub default_XkbModel {
    my ($keyboard) = @_;

    my $Layout = _keyboard2xkbl($keyboard);

    $Layout eq 'jp' ? 'jp106' : 
       $Layout eq 'br' ? 'abnt2' : 'pc105';
}

sub keyboard2full_xkb {
    my ($keyboard) = @_;

    my $Layout = _keyboard2xkbl($keyboard) or return { XkbDisable => '' };
    my $Variant = _keyboard2xkbv($keyboard);
    if ($keyboard->{GRP_TOGGLE} && $Layout !~ /,/) {
	$Layout = join(',', 'us', $Layout);
	$Variant = join(',', '', $Variant);
    }

    my $Model = $keyboard->{XkbModel} || default_XkbModel($keyboard);

    my $Options = join(',', 
	if_($keyboard->{KEYMAP_TOGGLE}, "grp:$keyboard->{KEYMAP_TOGGLE}", 'grp_led:scroll'),
	if_($keyboard->{KEYMAP_TOGGLE} ne 'rwin_toggle', 'compose:rwin'), 
    );

    { XkbModel => $Model, XkbLayout => $Layout, XkbVariant => $Variant, XkbOptions => $Options };
}

sub _xmodmap_file {
    my ($keyboard) = @_;
    my $f = "$ENV{SHARE_PATH}/xmodmap/xmodmap.$keyboard->{KEYBOARD}";
    -e $f && $f;
}

sub _setxkbmap {
    my ($keyboard) = @_;
    my $xkb = keyboard2full_xkb($keyboard) or return;
    run_program::run('setxkbmap', '-option', '') if $xkb->{XkbOptions}; #- need re-initialised other toggles are cumulated
    run_program::run('setxkbmap', $xkb->{XkbLayout}, '-variant' => $xkb->{XkbVariant}, '-model' => $xkb->{XkbModel}, '-option' => $xkb->{XkbOptions} || '', '-compat' => $xkb->{XkbCompat} || '');
}

sub setup_install {
    my ($keyboard) = @_;

    return if $::local_install;

    my $kmap = keyboard2kmap($keyboard) or return;

    log::l("loading keymap $kmap");
    if (-e (my $f = "$ENV{SHARE_PATH}/keymaps/$kmap.bkmap")) {
	_builtin_loadkeys(scalar cat_($f));
    } elsif (-x '/bin/loadkeys') {
	run_program::run('loadkeys', $kmap);
    } else {
	log::l("ERROR: can not load keymap");
    }
    setup_install_X11($keyboard) if $::o->{interactive} ne "curses";
}

sub setup_install_X11 {
    my ($keyboard) = @_;
    if (-x "/usr/bin/setxkbmap") {
	_setxkbmap($keyboard) or log::l("setxkbmap failed");
    } else {
	my $f = _xmodmap_file($keyboard);
	#- timeout is needed for drakx-in-chroot to kill xmodmap when it gets crazy with:
	#- please release the following keys within 2 seconds: Alt_L (keysym 0xffe9, keycode 64)
	eval { run_program::raw({ timeout => 3 }, 'xmodmap', $f) } if $f && !$::testing && $ENV{DISPLAY};
    }
}

sub write {
    my ($keyboard) = @_;
    log::l("keyboard::write $keyboard->{KEYBOARD}");

    $keyboard = { %$keyboard };
    put_in_hash($keyboard, keyboard2full_xkb($keyboard));
    delete $keyboard->{unsafe};
    $keyboard->{KEYMAP} = keyboard2kmap($keyboard);

    if ($keyboard->{KEYTABLE}) {
        my $h2 = { 'KEYMAP' => $keyboard->{KEYTABLE} };
	addVarsInShMode("$::prefix/etc/vconsole.conf", 0644, $h2);
    }

    my $xorgconf = qq(# Read and parsed by systemd-localed. It's probably wise not to edit this file
# manually too freely.
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
);
    my $isus = $keyboard->{XkbLayout} && $keyboard->{XkbLayout} eq "us";
    # kbd_option => enabled?
    my %is_opt_enabled = (
	XkbLayout  => sub { !$isus },
	XkbModel   => sub { !$isus || $keyboard->{XkbModel} ne "pc105" },
	XkbVariant => sub { 1 },
	XkbOptions => sub { 1 },
	);
    foreach my $opt (keys %is_opt_enabled) {
	if ($keyboard->{$opt} && $is_opt_enabled{$opt}) {
	    $xorgconf .= sprintf(q( Option "%s" "%s") . "\n", $opt, $keyboard->{$opt});
	}
    }
    $xorgconf .= "EndSection\n";
    output_p("$::prefix/etc/X11/xorg.conf.d/00-keyboard.conf", $xorgconf);
    run_program::rooted($::prefix, '/bin/dumpkeys', '>', '/etc/sysconfig/console/default.kmap') or log::l("dumpkeys failed");
    if (-x $localectl) { # systemd service
	run_program::run($localectl, '--no-convert', 'set-keymap',
		$keyboard->{KEYMAP}, $keyboard->{KEYMAP_TOGGLE});
	run_program::run($localectl, '--no-convert', 'set-x11-keymap',
		$keyboard->{XkbLayout}, $keyboard->{XkbModel}, $keyboard->{XkbVariant}, $keyboard->{XkbOptions});
        bootloader::set_default_grub_var('vconsole.keymap', $keyboard->{KEYMAP});
	# (tpg) restart these services to pull keyboard settings into environment
       run_program::run('systemctl', 'restart', 'systemd-localed.service');
       run_program::run('systemctl', 'restart', 'systemd-vconsole-setup.service');
    } else {
	setVarsInSh("$::prefix/etc/vconsole.conf", $keyboard);
	run_program::run('mandriva-setup-keyboard');
    }
}

sub configure_and_set_standalone {
    my ($keyboard) = @_;

    _setxkbmap($keyboard);
    run_program::run('loadkeys', keyboard2kmap($keyboard));

    &write($keyboard);
    # (tpg) restart this service to pull keyboard settings into environment
    run_program::run('systemctl', 'restart', 'systemd-localed.service');
}

sub read() {
    local $ENV{LANGUAGE} = 'C';
    my %keyboard;
  if (-x $localectl) { # systemd dbus based service
    foreach (run_program::rooted_get_stdout($::prefix, $localectl)) {
	/^ *VC Keymap: (.*)$/ and $keyboard{KEYMAP} = $1;
	/^ *VC Toggle Keymap: (.*)$/ and $keyboard{KEYMAP_TOGGLE} = $1;
	/^ *X11 Layout: (.*)$/ and $keyboard{XkbLayout} = $1;
	/^ *X11 Model: (.*)$/ and $keyboard{XkbModel} = $1;
	/^ *X11 Variant: (.*)$/ and $keyboard{XkbVariant} = $1;
	/^ *X11 Options: (.*)$/ and $keyboard{XkbOptions} = $1;
    }
    $keyboard{KEYBOARD} = _xkb2keyboardkey($keyboard{XkbLayout});
    # if keyboard not defined, we fallback to old config file
    if ($keyboard{XkbModel} =~ m/n\/a/ || $keyboard{KEYMAP} =~  m/n\/a/ ) {
	%keyboard = getVarsFromSh("$::prefix/etc/sysconfig/keyboard") or return;
    }
  } else {
    %keyboard = getVarsFromSh("$::prefix/etc/vconsole.conf") or return;
  }
    if (!$keyboard{KEYBOARD}) {
	add2hash(\%keyboard, grep { keyboard2kmap($_) eq $keyboard{KEYMAP} } _keyboards());
    }
    keyboard2text(\%keyboard) && \%keyboard;

}

sub read_or_default() { &read() || default() }

sub check() {
    $^W = 0;

    my $not_ok = 0;
    my $warn = sub {
	print STDERR "$_[0]\n";
    };
    my $err = sub {
	&$warn;
	$not_ok = 1;
    };

    if (my @l = grep { is_empty_array_ref(lang2keyboards($_)) } lang::list_langs()) {
	$warn->("no keyboard for langs " . join(" ", @l));
    }
    foreach my $lang (lang::list_langs()) {
	my $l = lang2keyboards($lang);
	foreach (@$l) {
	    0 <= $_->[1] && $_->[1] <= 100 or $err->("invalid value $_->[1] in $lang2keyboard{$lang} for $lang in \%lang2keyboard keyboard.pm");
	    $keyboards{$_->[0]} or $err->("invalid keyboard $_->[0] in $lang2keyboard{$lang} for $lang in \%lang2keyboard keyboard.pm");
	}
    }
    /SKIP/ || $keyboards{$_} or $err->("invalid keyboard $_ in \@usb2keyboard keyboard.pm") foreach @usb2keyboard;
    $usb2keyboard[0x21] eq 'us_SKIP' or $err->('@usb2keyboard is badly modified, 0x21 is not us keyboard');

    my @xkb_groups = map { if_(/grp:(\S+)/, $1) } cat_('/usr/lib/X11/xkb/rules/xfree86.lst');
    $err->("invalid xkb group toggle '$_' in \%grp_toggles") foreach difference2([ keys %grp_toggles ], \@xkb_groups);
    $warn->("unused xkb group toggle '$_'") foreach grep { !/switch/ } difference2(\@xkb_groups, [ keys %grp_toggles ]);

    my @xkb_layouts = (#- (map { (split)[0] } grep { /^! layout/ .. /^\s*$/ } cat_('/usr/lib/X11/xkb/rules/xfree86.lst')),
		       all('/usr/lib/X11/xkb/symbols'),
		       (map { (split)[2] } cat_('/usr/lib/X11/xkb/symbols.dir')));
    $err->("invalid xkb layout $_") foreach difference2([ map { _keyboard2xkbl($_) } _keyboards() ], \@xkb_layouts);

    my @kmaps_available = map { if_(m|.*/(.*)\.bkmap|, $1) } `tar tfj share/keymaps.tar.bz2`;
    my @kmaps_wanted = map { keyboard2kmap($_) } _keyboards();
    $err->("missing KEYMAP $_ (either share/keymaps.tar.bz2 need updating or $_ is bad)") foreach difference2(\@kmaps_wanted, \@kmaps_available);
    $err->("unused KEYMAP $_ (update share/keymaps.tar.bz2 using share/keymaps_generate)") foreach difference2(\@kmaps_available, \@kmaps_wanted);

    loadkeys_files($err);

    exit($not_ok);
}

1;
