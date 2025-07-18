## master

* Make the rendering of Prawn templates idempotent (rickenharp) (#20)

## 2.6.1 (2025-07-07)

* Fix race condition during parallel coverage testing using Template compiled_path option/method (jeremyevans)

## 2.6.0 (2025-01-13)

* Support :compiled_path option, needed for compiled paths when using :scope_class and fixed locals (jeremyevans)
* Support :scope_class option to force a specific scope class, instead of using the class of the provided scope (jeremyevans)
* Support fallback fixed locals for templates without extracted locals via :default_fixed_locals option (jeremyevans)
* Add Tilt.extract_fixed_locals accessor for enabling :extract_fixed_locals globally (jeremyevans)
* Support embedded fixed locals for templates via magic comments via :extract_fixed_locals option (jeremyevans)
* Support fixed locals for templates via :fixed_locals option (jeremyevans)

## 2.5.0 (2024-12-20)

* Deprecate creole templates as they require modifying frozen string literals (jeremyevans)
* Remove deprecated erubis, wikicloth, and maruku templates (jeremyevans)
* Avoid spurious frozen string literal warnings for chilled strings when using Ruby 3.4 (jeremyevans)

## 2.4.0 (2024-06-27)

* Support commonmarker 1.0+ API (unasuke) (#10)
* Make etanni template work with frozen string literals (jeremyevans)
* Deprecate erubis, wikicloth, and maruku templates as they require modifying frozen string literals (jeremyevans)
* Make SassTemplate ignore unsupported options when using sass-embedded (jeremyevans)

## 2.3.0 (2023-09-14)

* Remove deprecated support for non-string template code in PrawnTemplate (jeremyevans)
* Remove deprecated support for {ERB,Erubis}Template#default_output_variable{,=} (jeremyevans)
* Remove deprecated support for CoffeeScriptTemplate.default_no_wrap{,=} (jeremyevans)
* Remove deprecated support for RedCarpet 1.x (jeremyevans)
* Remove deprecated support for Tilt.current_template (jeremyevans)
* Make Template#freeze_string_literals? work correctly with Template#compiled_path (jeremyevans)
* Support :freeze option for StringTemplate to support frozen string literals (jeremyevans)
* Make Tilt.finalize! a no-op if it has already been called (jeremyevans)

## 2.2.0 (2023-06-05)

* Remove deprecated BlueCloth, Less, and Sigil support (jeremyevans)
* Drop support for RDoc < 4 (jeremyevans)
* Deprecate Tilt::Cache (jeremyevans)
* Deprecate Tilt.current_template (jeremyevans)
* Deprecate support for RedCarpet 1.x (jeremyevans)
* Deprecate CoffeeScriptTemplate.default_no_wrap{,=} aliases of default_bare{,=} (jeremyevans)
* Deprecate {ERB,Erubis}Template#default_output_variable{,=} (jeremyevans)
* Deprecate non-string template code in PrawnTemplate (jeremyevans)
* Deprecate default lazy loading of handlebars/org/emacs_org/jbuilder external template engines (jeremyevans)
* Handle `locals` as a local variable in templates (timriley) (#3) 
* Do not cache output in PrawnTemplate#evaluate (jeremyevans)
* Do not mark PrawnTemplate as not allowing script, since it can be used to execute arbitrary Ruby code (jeremyevans)
* Remove Redcarpet1Template and Redcarpet2Template from the RedCarpet support (jeremyevans)
* Separate CoffeeScriptTemplate.default_bare and CoffeeScriptLiterateTemplate.default_bare (jeremyevans)
* Fix possible issue in KramdownTemplate under concurrent use (jeremyevans)
* Do not define yield tag for RadiusTemplate if no block is given to render (jeremyevans)
* Avoid holding mutex while compiling template methods (jeremyevans)
* Template#prepare no longer needs to be overridden if no preparation work is needed (jeremyevans)
* Fix potential concurrency issues in Mapping (jeremyevans)
* Stop modifying given locals hash in tilt/prawn (jeremyevans)
* Change visibility of Template#compiled_method to public (jeremyevans)
* Add Tilt::StaticTemplate for templates that return the same output for every render (jeremyevans)
* Add Tilt::Mapping#finalized and Tilt.finalize! for finalized mappings that do not require mutex synchronization (jeremyevans)
* Add frozen_string_literal magic comment to all source files (jeremyevans)
* Support templates with frozen compiled source code (jeremyevans)
* Support :skip_compiled_encoding_detection template option to not scan compiled source code for encoding lines (jeremyevans)
* Ship slim template support with tilt (minad) (#4)
* Template#extract_{encoding,magic_comment} private methods now require a block (jeremyevans)

The repository switched to https://github.com/jeremyevans/tilt, so issue references above are for that
repository, and issue references below are for the previous repository (https://github.com/rtomayko/tilt).

## 2.1.0 (2023-02-17)

* Use UnboundMethod#bind_call on Ruby 2.7+ for better performance (#380, jeremyevans)
* Add Tilt::Template#freeze_string_literals? for freezing string literals in compiled templates (#301, jeremyevans)
* Use Haml::Template for Tilt::HamlTemplate if available (Haml 6+) (#391, ntkme) 
* Deprecate BlueCloth, Less, and Sigil support (#382, jeremyevans)
* Add Template#compiled_path accessor to save compiled template output to file (#369, jeremyevans)
* Add Mapping#unregister to remove registered extensions (#376, jeremyevans)
* Add Mapping#register_pipeline to register template pipelines (#259, jeremyevans)
* Remove Tilt::Dummy (#364, jeremyevans)
* Ensure Mapping#extensions\_for returns unique values (#342, mojavelinux)
* Remove opal support, since the the opal API changed (#374, jeremyevans)
* Remove .livescript extension for LiveScript (#374, jeremyevans)
* Set required\_ruby\_version in gemspec (#371, jeremyevans)

## 2.0.11 (2022-07-22)

* Fix #extensions\_for for RedcarpetTemplate (judofyr)
* Support the new sass-embedded gem (#367, ntkme)
* Add Tilt::EmacsOrg support (#366, hacktivista)
* Improve rendering of BasicObject instances (#348, jeremyevans)
* Fix Ruby 3.0 compatibility (#360, voxik)

## 2.0.10 (2019-09-23)

* Remove test files from bundled gem (#339, greysteil)
* Fix warning when using yield in templates on ruby 2.7 (#343, jeremyevans)

## 2.0.9 (2018-11-28)

* Use new ERB API in Ruby 2.6 (#329, koic)
* Support the new sassc gem (#336, jdickey, judofyr)

## 2.0.8 (2017-07-24)

* Register .tsx for TypeScript (#315, backus)
* Use Haml 5's new API (#312, k0kubun)
* Use correct parser options for CommonMarker (#320, rewritten)
* Suppress warnings when no locals are used (#304, amatsuda)
* Haml: Accept `outvar` (#317, k0kubun)

## 2.0.7 (2017-03-19)

* Do not modify BasicObject during template compilation on ruby 2.0+ (#309, jeremyevans)

## 2.0.6 (2017-01-26)

* Add support for LiveScript (#286, @Announcement Jacob Francis Powers)
* Add support for Sigil (#302, winebarrel)
* Add support for Erubi (#308, jeremyevans)
* Add support for options in Liquid (#298, #299, laCour)
* Always sort locals by strings (#307, jeremyevans)

* Fix test warnings (#305, amatsuda)
* Fix indentation (#293, yui-knk)
* Use SVG badges in README (#294, vasinov)
* Fix typo and trailing space (#295, #296, karloescota)

## 2.0.5 (2016-06-02)

* Add support for reST using Pandoc (#284, mfenner)
* Make lazy loading thread-safe; remove warning (judofyr)

## 2.0.4 (2016-05-16)

* Fix regression in BuilderTemplate (#283, judofyr)

## 2.0.3 (2016-05-12)

* Add Pandoc support (#276, jmuheim)
* Add CommonMark support (#282, raphink)
* Add TypeScript support (#278, nghitran)
* Work with frozen string literal (#274, jeremyevans)
* Add MIME type for Babel (#273, SaitoWu)

## 2.0.2 (2016-01-06)

* Pass options to Redcarpet (#250, hughbien)
* Haml: Improve error message on frozen self (judofyr)
* Add basic support for Babel (judofyr)
* Add support for .litcoffee (#243, judofyr, mr-vinn)
* Document Tilt::Cache (#266, tommay)
* Sort local keys for better caching (#257, jeremyevans)
* Add more CSV options (#256, Juanmcuello)
* Add Prawn template (kematzy)
* Improve cache-miss performance in Tilt::Cache (#251, tommay)
* Add man page (#241, josephholsten)
* Support YAML/JSON data in bin/tilt (#241, josephholsten)

## 2.0.1 (2014-03-21)

* Fix Tilt::Mapping bug in Ruby 2.1.0 (9589652c569760298f2647f7a0f9ed4f85129f20)
* Fix `tilt --list` (#223, Achrome)
* Fix circular require (#221, amarshall)

## 2.0.0 (2013-11-30)

* Support Pathname in Template#new (#219, kabturek)
* Add Mapping#templates_for (judofyr)
* Support old-style #register (judofyr)
* Add Handlebars as external template engine (#204, judofyr, jimothyGator)
* Add org-ruby as external template engine (#207, judofyr, minad)
* Documentation typo (#208, elgalu)

## 2.0.0.beta1 (2013-07-16)

* Documentation typo (#202, chip)
* Use YARD for documentation (#189, judofyr)
* Add Slim as an external template engine (judofyr)
* Add Tilt.templates_for (#121, judofyr)
* Add Tilt.current_template (#151, judofyr)
* Avoid loading all files in tilt.rb (#160, #187, judofyr)
* Implement lazily required templates classes (#178, #187, judofyr)
* Move #allows_script and default_mime_type to metadata (#187, judofyr)
* Introduce Tilt::Mapping (#187, judofyr)
* Make template compilation thread-safe (#191, judofyr)

## 1.4.1 (2013-05-08)

* Support Arrays in pre/postambles (#193, jbwiv)

## 1.4.0 (2013-05-01)

* Better encoding support

## 1.3.7 (2013-04-09)

* Erubis: Check for the correct constant (#183, mattwildig)
* Don't fail when BasicObject is defined in 1.8 (#182, technobrat, judofyr)

## 1.3.6 (2013-03-17)

* Accept Hash that implements #path as options (#180, lawso017)
* Changed extension for CsvTemplate from '.csv' to '.rcsv' (#177, alexgb)

## 1.3.5 (2013-03-06)

* Fixed extension for PlainTemplate (judofyr)
* Improved local variables regexp (#174, razorinc)
* Added CHANGELOG.md

## 1.3.4 (2013-02-28)

* Support RDoc 4.0 (#168, judofyr)
* Add mention of Org-Mode support (#165, aslakknutsen)
* Add AsciiDoctorTemplate (#163, #164, aslakknutsen)
* Add PlainTextTemplate (nathanaeljones)
* Restrict locals to valid variable names (#158, thinkerbot)
* ERB: Improve trim mode support (#156, ssimeonov)
* Add CSVTemplate (#153, alexgb)
* Remove special case for 1.9.1 (#147, guilleiguaran)
* Add allows\_script? method to Template (#143, bhollis)
* Default to using Redcarpet2 (#139, DAddYE)
* Allow File/Tempfile as filenames (#134, jamesotron)
* Add EtanniTemplate (#131, manveru)
* Support RDoc 3.10 (#112, timfel)
* Always compile templates; remove old source evaluator (rtomayko)
* Less: Options are now being passed to the parser (#106, cowboyd)
