Tilt
====

Tilt is a thin interface over a bunch of different Ruby template engines in
an attempt to make their usage as generic as possible. This is useful for web
frameworks, static site generators, and other systems that support multiple
template engines but don't want to code for each of them individually.

The following features are supported for all template engines (assuming the
feature is relevant to the engine):

 * Custom template evaluation scopes / bindings
 * Ability to pass locals to template evaluation
 * Support for passing a block to template evaluation for "yield"
 * Backtraces with correct filenames and line numbers
 * Template file caching and reloading
 * Fast, method-based template source compilation

The primary goal is to get all of the things listed above right for all
template engines included in the distribution.

Support for these template engines is included with Tilt:

| Engine               | File Extensions        | Required Libraries            |
| ---------------------| -----------------------| ------------------------------|
| Asciidoctor          | .ad, .adoc, .asciidoc  | asciidoctor                   |
| Babel                | .es6, .babel, .jsx     | babel-transpiler              |
| Builder              | .builder               | builder                       |
| CoffeeScript         | .coffee                | coffee-script (+ javascript)  |
| CoffeeScriptLiterate | .litcoffee             | coffee-script (+ javascript)  |
| CommonMarker         | .markdown, .mkd, .md   | commonmarker                  |
| Creole               | .wiki, .creole         | creole                        |
| CSV                  | .rcsv                  | csv (ruby stdlib)             |
| ERB                  | .erb, .rhtml           | erb (ruby stdlib)             |
| Erubi                | .erb, .rhtml, .erubi   | erubi                         |
| Etanni               | .ern, .etanni          | none                          |
| Haml                 | .haml                  | haml                          |
| Kramdown             | .markdown, .mkd, .md   | kramdown                      |
| Liquid               | .liquid                | liquid                        |
| LiveScript           | .ls                    | livescript (+ javascript)     |
| Markaby              | .mab                   | markaby                       |
| Nokogiri             | .nokogiri              | nokogiri                      |
| Pandoc               | .markdown, .mkd, .md   | pandoc                        |
| Plain                | .html                  | none                          |
| Prawn                | .prawn                 | prawn                         |
| Radius               | .radius                | radius                        |
| RDiscount            | .markdown, .mkd, .md   | rdiscount                     |
| RDoc                 | .rdoc                  | rdoc                          |
| Redcarpet            | .markdown, .mkd, .md   | redcarpet                     |
| RedCloth             | .textile               | redcloth                      |
| RstPandoc            | .rst                   | pandoc                        |
| Slim                 | .slim                  | slim                          |
| Sass                 | .sass                  | sass-embedded, sassc, or sass |
| Scss                 | .scss                  | sass-embedded, sassc, or sass |
| String               | .str                   | none                          |
| TypeScript           | .ts                    | typescript (+ javascript)     |
| Yajl                 | .yajl                  | yajl-ruby                     |

See [TEMPLATES.md][t] for detailed information on template engine
options and supported features.

[t]: http://github.com/jeremyevans/tilt/blob/master/docs/TEMPLATES.md
   "Tilt Template Engine Documentation"

Basic Usage
-----------

Instant gratification:

~~~ruby
require 'tilt'
require 'tilt/erb'
template = Tilt.new('templates/foo.erb')
=> #<Tilt::ERBTemplate @file="templates/foo.erb" ...>
output = template.render
=> "Hello world!"
~~~

It's recommended that calling programs explicitly require the Tilt template
engine libraries (like 'tilt/erb' above) at load time. Tilt attempts to
lazy require the template engine library the first time a template is
created, but this is prone to error in threaded environments.

The Tilt module contains generic implementation classes for all supported
template engines. Each template class adheres to the same interface for
creation and rendering. In the instant gratification example, we let Tilt
determine the template implementation class based on the filename, but
Tilt::Template implementations can also be used directly:

~~~ruby
require 'tilt/haml'
template = Tilt::HamlTemplate.new('templates/foo.haml')
output = template.render
~~~

The `render` method takes an optional evaluation scope and locals hash
arguments. Here, the template is evaluated within the context of the
`Person` object with locals `x` and `y`:

~~~ruby
require 'tilt/erb'
template = Tilt::ERBTemplate.new('templates/foo.erb')
joe = Person.find('joe')
output = template.render(joe, :x => 35, :y => 42)
~~~

If no scope is provided, the template is evaluated within the context of an
object created with `Object.new`.

A single `Template` instance's `render` method may be called multiple times
with different scope and locals arguments. Continuing the previous example,
we render the same compiled template but this time in jane's scope:

~~~ruby
jane = Person.find('jane')
output = template.render(jane, :x => 22, :y => nil)
~~~

Blocks can be passed to `render` for templates that support running
arbitrary ruby code (usually with some form of `yield`). For instance,
assuming the following in `foo.erb`:

~~~ruby
Hey <%= yield %>!
~~~

The block passed to `render` is called on `yield`:

~~~ruby
template = Tilt::ERBTemplate.new('foo.erb')
template.render { 'Joe' }
# => "Hey Joe!"
~~~

Fixed Locals
------------

By default, Tilt templates that support local variables can be called with
any locals, and a separate template method is compiled for each combination
of local variable names.  This causes multiple issues:

* It is inefficient, especially for large templates that are called with
  many combinations of locals.
* It hides issues if unused local variable names are passed to the template
* It does not support default values for local variables
* It does not support required local variables
* It does not support cases where you want to pass values via a keyword splat
* It does not support named blocks

You can pass the `:fixed_locals` option when creating the template to fix the
local variables.  This will only compile a single template method per template
(per scope class, see below).
The value of the `:fixed_locals` option is a Ruby method parameter string, which
should start and end with parentheses. For example, if the template does not
use local variables, you can set it to `"()"`.  This will cause an ArgumentError
to be raised if you call the template with locals:

~~~ruby
template = Tilt::ERBTemplate.new('templates/foo.erb', fixed_locals: "()")
output = template.render(Object.new) # No ArgumentError
output = template.render(Object.new, x: 1) # ArgumentError
~~~

If the template must be passed the `x` local variable to work correctly, and
optionally can be provided the `y` local variable:

~~~ruby
template = Tilt::ERBTemplate.new('templates/foo.erb', fixed_locals: "(x:, y: nil)")
output = template.render(Object.new) # ArgumentError
output = template.render(Object.new, x: 1) # No ArgumentError
output = template.render(Object.new, x: 1, y: 2) # No ArgumentError
output = template.render(Object.new, x: 1, y: 2, z: 3) # ArgumentError
~~~

If the template wants to accept arbitrary local variables, in order to pass
the variables to a method inside the template, you can provide a keyword splat
or a single positional argument (with an optional empty hash value if you want
to support being called with no local variables):

~~~ruby
template = Tilt::ERBTemplate.new('templates/foo.erb', fixed_locals: "(**args)") # or "(args={})"
~~~

If you would like to name the block passed to the template, so you can pass
it to a method inside the template:

~~~ruby
template = Tilt::ERBTemplate.new('templates/foo.erb', fixed_locals: "(&block)")
~~~

Embedded Fixed Locals
---------------------

In many cases, Tilt is used in situations where you do not have direct control
over the options passed when creating each separate template.  In these cases
and others, it can be helpful to embed the fixed locals inside the template
using a magic comment.  This can be enabled using the `:extract_fixed_locals`
template option.  It can also be enabled globally via:

~~~ruby
Tilt.extract_fixed_locals = true
~~~

If `:extract_fixed_locals` option is given, or extraction is globally enabled,
and the `:fixed_locals` option is not provided when creating the template,
Tilt will scan the template code looking for a magic comment of
the form (whitespace around `locals:` is optional but recommended):

```
# locals: ()
```

In ERB templates, you can use the following comment format:

```
<%# locals: () %>
```

In slim templates, the comment format looks like this:

```
//# locals: ()
```

In string templates, it is a little ackward, but still possible (note that the
closing `}` goes on a separate line:

```
#{# locals: ()
}
```

If Tilt finds the magic comment, it will use it as fixed locals.  To disable
the scanning for fixed locals even if `Tilt.extract_fixed_locals = true` is
set, pass the `fixed_locals: false` or `extract_fixed_locals: false` option.

When embedded fixed locals are supported, it can be useful to support a
default for fixed locals if they are not specified in the template.  This
is useful mostly to default templates to not supporting local variables
without having to specify that in each template.  Tilt support this via the
`:default_fixed_locals` option.

To recap, in order of preference, Tilt will use fixed locals from the
following sources:

* `:fixed_locals` template option
* embedded fixed locals magic comment (if `:extract_fixed_locals` template
  option is given or `Tilt.extract_fixed_locals = true`)
* `:default_fixed_locals` template option

It is expected that embedded fixed locals magic comments will be supported
by default in Tilt 3 (i.e. `Tilt.extract_fixed_locals` will default to `true`).

# `:scope_class` option

You can now specify the `:scope_class` option when creating the template, which
will fix the scope class for the template.  By default, Tilt uses the class
of the provide scope, and will compile a separate method per scope class. By
using the `:scope_class` option to fix the scope class, and using fixed locals,
you can ensure only a single template method is compiled per Tilt::Template
instance.

Template Mappings
-----------------

The Tilt::Mapping class includes methods for associating template
implementation classes with filename patterns and for locating/instantiating
template classes based on those associations.

The Tilt module has a global instance of `Mapping` that is populated with the
table of template engines above.

The Tilt.register method associates a filename pattern with a specific
template implementation. To use ERB for files ending in a `.bar` extension:

~~~ruby
>> Tilt.register Tilt::ERBTemplate, 'bar'
>> Tilt.new('views/foo.bar')
=> #<Tilt::ERBTemplate @file="views/foo.bar" ...>
~~~

Retrieving the template class for a file or file extension:

~~~ruby
>> Tilt['foo.bar']
=> Tilt::ERBTemplate
>> Tilt['haml']
=> Tilt::HamlTemplate
~~~

Retrieving a list of template classes for a file:

~~~ruby
>> Tilt.templates_for('foo.bar')
=> [Tilt::ERBTemplate]
>> Tilt.templates_for('foo.haml.bar')
=> [Tilt::ERBTemplate, Tilt::HamlTemplate]
~~~

The template class is determined by searching for a series of decreasingly
specific name patterns. When creating a new template with
`Tilt.new('views/foo.html.erb')`, we check for the following template
mappings:

  1. `views/foo.html.erb`
  2. `foo.html.erb`
  3. `html.erb`
  4. `erb`

Template Pipelines
------------------

In some cases, it is useful to take the output of one template engine,
and use it as input to another template engine.  This can be useful
when a template engine does not support locals or a scope, and you
want to customize the output per different locals.  For example, let's
say you have an scss file that you want to allow customization with
erb, such as:

~~~scss
.foo {
  .bar {
    .<%= hide_class %> {
      display: none;
    }
  }
}
~~~

You can do this manually:

~~~ruby
scss = Tilt.new("file.scss.erb").render(nil, hide_class: 'baz')
css = Tilt.new("scss"){scss}.render
~~~

A more automated way to handle it is to register a template pipeline:

~~~ruby
  Tilt.register_pipeline("scss.erb")
~~~

Then Tilt will automatically take the output of the erb engine,
and pass it to the scss engine, automating the above code.

~~~ruby
  css = Tilt.new("file.scss.erb").render(nil, hide_class: 'baz')
~~~

Finalizing Mappings
-------------------

By default, Tilt::Mapping instances will lazy load files for template
classes, and will allow for registering an unregistering template classes.
To make sure this is safe in a multithreaded environment, a mutex is used
to synchronize access. To improve performance, and prevent additional lazy
loading of template classes, you can finalize mappings.  Finalizing a mapping
returns a new finalized mapping that is frozen, cannot be modified, and will
not lazy load template classes not already loaded.  Users of Tilt are
encouraged to manually require the template libraries they desire to use,
and then freeze the mappings. Tilt.finalize! will replace Tilt's default
mapping with a finalized versions, as well as freeze Tilt so that no
further changes can be made.

~~~ruby
require 'tilt/erubi'
require 'tilt/string'
require 'tilt/sass'
Tilt.finalize!
Tilt['erb'] # => Tilt::ErubiTemplate
Tilt['str'] # => Tilt::StringTemplate
Tilt['scss'] # => Tilt::ScssTemplate
Tilt['haml'] # => nil # even if haml is installed
~~~

Encodings
---------

Tilt needs to know the encoding of the template in order to work properly:

Tilt will use `Encoding.default_external` as the encoding when reading external
files. If you're mostly working with one encoding (e.g. UTF-8) we *highly*
recommend setting this option. When providing a custom reader block (`Tilt.new
{ custom_string }`) you'll have ensure the string is properly encoded yourself.

Most of the template engines in Tilt also allows you to override the encoding
using the `:default_encoding`-option:

~~~ruby
tmpl = Tilt.new('hello.erb', :default_encoding => 'Big5')
~~~

Ultimately it's up to the template engine how to handle the encoding: It might
respect `:default_encoding`, it might always assume it's UTF-8 (like
CoffeeScript), or it can do its own encoding detection.

Template Compilation
--------------------

Tilt compiles generated Ruby source code produced by template engines and reuses
it on subsequent template invocations. Benchmarks show this yields a 5x-10x
performance increase over evaluating the Ruby source on each invocation.

Template compilation is currently supported for these template engines:
StringTemplate, ERB, Erubi, Etanni, Haml, Nokogiri, Builder, CSV,
Prawn, and Yajl.

LICENSE
-------

Tilt is distributed under the MIT license. See the `COPYING` file for more info.
