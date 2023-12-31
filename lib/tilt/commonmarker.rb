# frozen_string_literal: true
require_relative 'template'
require 'commonmarker'

module Tilt
  class CommonMarkerTemplate < StaticTemplate
    ALIASES = {
      :smartypants => :SMART
    }.freeze
    PARSE_OPTS = [
      :FOOTNOTES,
      :LIBERAL_HTML_TAG,
      :SMART,
      :smartypants,
      :STRIKETHROUGH_DOUBLE_TILDE,
      :UNSAFE,
      :VALIDATE_UTF8,
    ].freeze
    RENDER_OPTS = [
      :FOOTNOTES,
      :FULL_INFO_STRING,
      :GITHUB_PRE_LANG,
      :HARDBREAKS,
      :NOBREAKS,
      :SAFE, # Removed in v0.18.0 (2018-10-17)
      :SOURCEPOS,
      :TABLE_PREFER_STYLE_ATTRIBUTES,
      :UNSAFE,
    ].freeze
    EXTS = [
      :autolink,
      :strikethrough,
      :table,
      :tagfilter,
      :tasklist,
    ].freeze

    V1_PARSE_OPTS = [
      :smart,
      :default_info_string,
    ].freeze
    V1_RENDER_OPTS = [
      :hardbreaks,
      :github_pre_lang,
      :width,
      :unsafe,
      :escape,
      :sourcepos,
    ].freeze
    V1_EXTS = [
      :strikethrough,
      :tagfilter,
      :table,
      :autolink,
      :tasklist,
      :superscript,
      :header_ids,
      :footnotes,
      :description_lists,
      :front_matter_delimiter,
      :shortcodes,
    ].freeze

    def prepare
      if commonmaker_v1_or_later?
        prepare_v1
      else
        prepare_pre
      end
    end

    private def prepare_pre
      extensions = EXTS.select do |extension|
        @options[extension]
      end

      parse_options, render_options = [PARSE_OPTS, RENDER_OPTS].map do |opts|
        opts = opts.select do |option|
          @options[option]
        end.map! do |option|
          ALIASES[option] || option
        end

        opts = :DEFAULT unless opts.any?
        opts
      end

      @output = CommonMarker.render_doc(@data, parse_options, extensions).to_html(render_options, extensions)
    end

    private def prepare_v1
      parse_options = @options.select { |key, _| V1_PARSE_OPTS.include?(key) }
      render_options = @options.select { |key, _| V1_RENDER_OPTS.include?(key) }
      extensions = @options.select { |key, _| V1_EXTS.include?(key) }
      @output = Commonmarker.to_html(@data, options: { parse: parse_options, render: render_options, extension: extensions })
    end

    private def commonmaker_v1_or_later?
      defined?(::Commonmarker) ? true : false
    end
  end
end
