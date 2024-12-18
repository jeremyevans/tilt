Tilt Templates
==============

While all Tilt templates use the same basic interface for template loading and
evaluation, each varies in its capabilities and available options. Detailed
documentation on each supported template engine is provided below.

There are also some file extensions that have several implementations
(currently ERB and Markdown). These template classes have certain features
which are guaranteed to work across all the implementations. If you wish to be
compatible with all of these template classes, you should only depend on the
cross-implementation features.

 * [ERB](#erb) - Generic ERB implementation (backed by erb.rb or Erubi)
 * [erb.rb](#erbrb) - `Tilt::ERBTemplate`
 * [Erubi](#erubi) - `Tilt::ErubiTemplate`
 * [Haml](#haml) - `Tilt::HamlTemplate`
 * [Liquid](#liquid) - `Tilt::LiquidTemplate`
 * Nokogiri - `Tilt::NokogiriTemplate`
 * Builder - `Tilt::BuilderTemplate`
 * Markaby - `Tilt::MarkabyTemplate`
 * [Radius](#radius) - `Tilt::RadiusTemplate`

Tilt also includes support for CSS processors like [Sass][sass],
[CoffeeScript][coffee-script] and some simple text formats.

 * Sass - `Tilt::SassTemplate`
 * Scss - `Tilt::ScssTemplate`
 * CoffeeScript - `Tilt::CoffeeScriptTemplate`
 * Literate CoffeeScript - `Tilt::CoffeeScriptLiterateTemplate`
 * LiveScript - `Tilt::LiveScriptTemplate`
 * [Textile](#redcloth) - `Tilt::RedClothTemplate`
 * reStructuredText - `Tilt::RstPandocTemplate`
 * Creole - `Tilt::CreoleTemplate`
 * [RDoc](#rdoc) - `Tilt::RDocTemplate`

Tilt has extensive support for Markdown, backed by one of seven different
implementations (depending on which are available on your system):

 * [Markdown](#markdown) - Generic Markdown implementation
 * [RDiscount](#rdiscount) - `Tilt::RDiscountTemplate`
 * Redcarpet - `Tilt::RedcarpetTemplate`
 * Kramdown - `Tilt::KramdownTemplate`
 * Pandoc - `Tilt::PandocTemplate`
 * CommonMarker - `Tilt::CommonMarkerTemplate`

<a name='erb'></a>
ERB (`erb`, `rhtml`)
--------------------

ERB is a simple but powerful template languge for Ruby. In Tilt it's backed by
[Erubi](#erubi) (if installed on your system) or by
[erb.rb](#erbrb) (which
is included in Ruby's standard library). This documentation applies to all three
implementations.

### Example

    Hello <%= world %>!

### Usage

ERB templates support custom evaluation scopes and locals:

    >> require 'erb'
    >> template = Tilt.new('hello.html.erb')
    >> template.render(self, :world => 'World!')
    => "Hello World!"

Or, use `Tilt['erb']` directly to process strings:

    template = Tilt['erb'].new { "Hello <%= world %>!" }
    template.render(self, :world => 'World!')

### Options

#### `:trim => trim`

Omits newlines and spaces around certain lines (usually those that starts with
`<%` and ends with `%>`). There isn't a specification for how trimming in ERB
should work, so if you need more control over the whitespace, you should use
[erb.rb](#erbrb) or [Erubi](#erubi) directly.


#### `:outvar => '_erbout'`

The name of the variable used to accumulate template output. This can be
any valid Ruby expression but must be assignable. By default a local
variable named `_erbout` is used.

#### `:freeze => false`

If set to true, will set the `frozen_string_literal` flag in the compiled
template code, so that string literals inside the templates will be frozen.

<a name='erbrb'></a>
erb.rb (`erb`, `rhtml`)
-----------------------

[ERB](#erb) implementation available in Ruby's standard library.

All the documentation of [ERB](#erb) applies in addition to the following:

### Usage

The `Tilt::ERBTemplate` class is registered for all files ending in `.erb` or
`.rhtml` by default, but with a *lower* priority than ErubiTemplate.
If you specifically want to use ERB, it's recommended to use
`#prefer`:

    Tilt.prefer Tilt::ERBTemplate

__NOTE:__ It's suggested that your program `require 'erb'` at load time when
using this template engine within a threaded environment.

### Options

#### `:trim => true`

The ERB trim mode flags. This is a string consisting of any combination of the
following characters:

  * `'>'`  omits newlines for lines ending in `>`
  * `'<>'` omits newlines for lines starting with `<%` and ending in `%>`
  * `'%'`  enables processing of lines beginning with `%`
  * `true` is an alias of `<>`

### See also

  * [ERB documentation](https://docs.ruby-lang.org/en/master/ERB.html)


<a name='erubi'></a>
Erubi (`erb`, `rhtml`, `erubi`)
---------------------------------

[Erubi][erubi] is an ERB implementation that uses the same algorithm as
the erubis gem, but is maintained and offers numerous improvements.

All the documentation of [ERB](#erb) applies in addition to the following:

### Usage

The `Tilt::ErubiTemplate` class is registered for all files ending in `.erb` or
`.rhtml` by default, with the *highest* priority.

__NOTE:__ It's suggested that your program `require 'erubi'` at load time when
using this template engine within a threaded environment.

### Options

#### `:engine_class => Erubi::Engine`

Allows you to specify a custom engine class to use instead of the
default which is `Erubi::Engine`.

#### Other

Other options are passed to the constructor of the engine class.

### See also

  * [Erubi Home][erubi]


<a name='haml'></a>
Haml (`haml`)
-------------

[Haml][haml] is a markup language that’s used to cleanly and simply describe
the HTML of any web document without the use of inline code. Haml functions as
a replacement for inline page templating systems such as PHP, ASP, and ERB, the
templating language used in most Ruby on Rails applications. However, Haml
avoids the need for explicitly coding HTML into the template, because it itself
is a description of the HTML, with some code to generate dynamic content.
([more](http://haml.info/about.html))


### Example

    %html
      %head
        %title= @title
      %body
        %h1
          Hello
          = world + '!'

### Usage

The `Tilt::HamlTemplate` class is registered for all files ending in `.haml`
by default. Haml templates support custom evaluation scopes and locals:

    >> require 'haml'
    >> template = Tilt.new('hello.haml')
    => #<Tilt::HamlTemplate @file='hello.haml'>
    >> @title = "Hello Haml!"
    >> template.render(self, :world => 'Haml!')
    => "
    <html>
      <head>
        <title>Hello Haml!</title>
      </head>
      <body>
        <h1>Hello Haml!</h1>
      </body>
    </html>"

Or, use the `Tilt::HamlTemplate` class directly to process strings:

    >> require 'haml'
    >> template = Tilt::HamlTemplate.new { "%h1= 'Hello Haml!'" }
    => #<Tilt::HamlTemplate @file=nil ...>
    >> template.render
    => "<h1>Hello Haml!</h1>"

__NOTE:__ It's suggested that your program `require 'haml'` at load time when
using this template engine within a threaded environment.

### Options

Please see the [Haml Reference](http://haml.info/docs/yardoc/file.HAML_REFERENCE.html#options) for all available options.

### See also

  * [#haml.docs](http://haml.info/docs.html)
  * [Haml Tutorial](http://haml.info/tutorial.html)
  * [Haml Reference](http://haml.info/docs/yardoc/file.HAML_REFERENCE.html)


<a name='liquid'></a>
Liquid (`liquid`)
-----------------

[Liquid][liquid] is for rendering safe templates which cannot affect the
security of the server they are rendered on.

### Example

    <html>
      <head>
        <title>{{ title }}</title>
      </head>
      <body>
        <h1>Hello {{ world }}!</h1>
      </body>
    </html>

### Usage

`Tilt::LiquidTemplate` is registered for all files ending in `.liquid` by
default. Liquid templates support locals and objects that respond to
`#to_h` as scopes:

    >> require 'liquid'
    >> require 'tilt'
    >> template = Tilt.new('hello.liquid')
    => #<Tilt::LiquidTemplate @file='hello.liquid'>
    >> scope = { :title => "Hello Liquid Templates" }
    >> template.render(nil, :world => "Liquid")
    => "
    <html>
      <head>
        <title>Hello Liquid Templates</title>
      </head>
      <body>
        <h1>Hello Liquid!</h1>
      </body>
    </html>"

Or, use `Tilt::LiquidTemplate` directly to process strings:

    >> require 'liquid'
    >> template = Tilt::LiquidTemplate.new { "<h1>Hello Liquid!</h1>" }
    => #<Tilt::LiquidTemplate @file=nil ...>
    >> template.render
    => "<h1>Hello Liquid!</h1>"

__NOTE:__ It's suggested that your program `require 'liquid'` at load
time when using this template engine within a threaded environment.

### See also

  * [Liquid for Programmers](https://wiki.github.com/Shopify/liquid/liquid-for-programmers)
  * [Liquid Docs](http://liquid.rubyforge.org/)
  * GitHub: [Shopify/liquid](https://github.com/Shopify/liquid/)


<a name='radius'></a>
Radius (`radius`)
-----------------

[Radius][radius] is the template language used by [Radiant CMS][radiant]. It is
a tag language designed to be valid XML/HTML.

### Example

    <html>
    <body>
      <h1><r:title /></h1>
      <ul class="<r:type />">
      <r:repeat times="3">
        <li><r:hello />!</li>
      </r:repeat>
      </ul>
      <r:yield />
    </body>
    </html>

### Usage

To render a template such as the one above.

    scope = OpenStruct.new
    scope.title = "Radius Example"
    scope.hello = "Hello, World!"

    require 'radius'
    template = Tilt::RadiusTemplate.new('example.radius', :tag_prefix=>'r')
    template.render(scope, :type=>'hlist'){ "Jackpot!" }

The result will be:

    <html>
    <body>
      <h1>Radius Example</h1>
      <ul class="hlist">
        <li>Hello, World!</li>
        <li>Hello, World!</li>
        <li>Hello, World!</li>
      </ul>
      Jackpot!
    </body>
    </html>

### See also

  * [Radius][radius]
  * [Radiant CMS][radiant]


<a name='textile'></a>
Textile (`textile`)
-------------------

Textile is a lightweight markup language originally developed by Dean Allen and
billed as a "humane Web text generator". Textile converts its marked-up text
input to valid, well-formed XHTML and also inserts character entity references
for apostrophes, opening and closing single and double quotation marks,
ellipses and em dashes.

Textile formatted texts are converted to HTML with the [RedCloth][redcloth]
engine, which is a Ruby extension written in C.

### Example

    h1. Hello Textile Templates

    Hello World. This is a paragraph.

### Usage

__NOTE:__ It's suggested that your program `require 'redcloth'` at load time
when using this template engine in a threaded environment.

### See Also

  * [RedCloth][redcloth]

<a name='rst'></a>
reStructuredText (`rst`)
-------------------

reStructuredText is a lightweight markup language originally developed by David Goodger,
based on StructuredText and Setext. reStructuredText is primarily used for technical
documentation in the Python programming language community, e.g. by the
[Sphinx](http://www.sphinx-doc.org/en/stable/rest.html) Python documentation generator.

reStructuredText formatted texts are converted to HTML with [Pandoc][pandoc], which
is an application written in Haskell, with a Ruby wrapper provided by the
[pandoc-ruby][pandoc-ruby] gem.

### Example

    Hello Rst Templates
    ===================

    Hello World. This is a paragraph.

### See Also

  * [Pandoc][pandoc]
  * [pandoc-ruby][pandoc-ruby]


<a name='rdoc'></a>
RDoc (`rdoc`)
-------------

[RDoc][rdoc] is the simple text markup system that comes with Ruby's standard
library.

### Example

    = Hello RDoc Templates

    Hello World. This is a paragraph.

### Usage

__NOTE:__ It's suggested that your program `require 'rdoc'`,
`require 'rdoc/markup'`, and `require 'rdoc/markup/to_html'` at load time
when using this template engine in a threaded environment.

### See also

 * [RDoc][rdoc]


<a name='markdown'></a>
Markdown (`markdown`, `md`, `mkd`)
----------------------------------

[Markdown][markdown] is a lightweight markup language, created by John Gruber
and Aaron Swartz. For any markup that is not covered by Markdown’s syntax, HTML
is used.  Marking up plain text with Markdown markup is easy and Markdown
formatted texts are readable.

Markdown formatted texts are converted to HTML with one of these libraries:

  * [RDiscount](#rdiscount) - `Tilt::RDiscountTemplate`
  * Redcarpet - `Tilt::RedcarpetTemplate`
  * Kramdown - `Tilt::KramdownTemplate`
  * Pandoc - `Tilt::PandocTemplate`
  * CommonMarker - `Tilt::CommonMarkerTemplate`

### Example

    Hello Markdown Templates
    ========================

    Hello World. This is a paragraph.

### Usage

To wrap a Markdown formatted document with a layout:

    layout = Tilt['erb'].new do
      "<!doctype html><title></title><%= yield %>"
    end
    data = Tilt['md'].new { "# hello tilt" }
    layout.render { data.render }
    # => "<!doctype html><title></title><h1>hello tilt</h1>\n"

### Options

Every implementation of Markdown *should* support these options, but there are
some known problems with the Kramdown engine.

#### `:smartypants => true|false`

Set `true` to enable [Smarty Pants][smartypants] style punctuation replacement.

In Kramdown this option only applies to smart quotes. It will apply a
subset of Smarty Pants (e.g. `...` to `…`) regardless of any option.

#### `:escape_html => true|false`

Set `true` disallow raw HTML in Markdown contents. HTML is converted to
literal text by escaping `<` characters.

Kramdown doesn't support this option.

### See also

 * [Markdown Syntax Documentation](http://daringfireball.net/projects/markdown/syntax)

<a name='rdiscount'></a>
RDiscount (`markdown`, `md`, `mkd`)
-----------------------------------

[Discount][discount] is an implementation of the Markdown markup language in C.
[RDiscount][rdiscount] is a Ruby wrapper around Discount.

All the documentation of [Markdown](#markdown) applies in addition to the following:

### Usage

The `Tilt::RDiscountTemplate` class is registered for all files ending in
`.markdown`, `.md` or `.mkd` by default with the highest priority. If you
specifically want to use RDiscount, it's recommended to use `#prefer`:

    Tilt.prefer Tilt::RDiscountTemplate

__NOTE:__ It's suggested that your program `require 'rdiscount'` at load time when
using this template engine within a threaded environment.

### See also

  * [Discount][discount]
  * [RDiscount][rdiscount]
  * GitHub: [rtomayko/rdiscount][rdiscount]


[sass]: http://sass-lang.com/ "Sass"
[coffee-script]: http://jashkenas.github.com/coffee-script/ "Coffee Script"
[erubi]: https://github.com/jeremyevans/erubi "Erubi"
[haml]: http://haml.info/ "Haml"
[liquid]: http://www.liquidmarkup.org/ "Liquid"
[radius]: http://radius.rubyforge.org/ "Radius"
[radiant]: http://radiantcms.org/ "Radiant CMS"
[redcloth]: http://redcloth.org/ "RedCloth"
[rdoc]: http://rdoc.rubyforge.org/ "RDoc"
[discount]: http://www.pell.portland.or.us/~orc/Code/discount/ "Discount"
[rdiscount]: http://github.com/rtomayko/rdiscount/ "RDiscount"
[smartypants]: http://daringfireball.net/projects/smartypants/ "Smarty Pants"
[markdown]: http://en.wikipedia.org/wiki/Markdown "Markdown"
[pandoc]: http://pandoc.org/ "Pandoc"
[pandoc-ruby]: https://github.com/alphabetum/pandoc-ruby "pandoc-ruby"
