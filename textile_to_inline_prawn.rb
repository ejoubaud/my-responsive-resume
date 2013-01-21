# encoding: utf-8

# Converts Textile markup into some Prawn inline markup
# Only handles lists (ordered and unordered), italic, bold and links
#
# Usage: Prawn::TextileToInlinePrawn.new(textile_markup).to_s
# Author: Emmanuel Joubaud

module Prawn
  class TextileToInlinePrawn

    def initialize str
      @prawned = str
      # The order matters! link must be called after italic and bold, and bold after ul
      [ :ul, :ol, :italic, :bold, :link ].each do |method|
        @prawned = send method, @prawned
      end
    end

    def to_s
      @prawned
    end

    private

      def italic str
        str.gsub( /_([^\s_]*\S)_/, '<i>\1</i>' )
      end

      def bold str
        str.gsub( /\*([^\s*]*\S)\*/, '<b>\1</b>' )
      end

      def link str
        # Used to remove <i>...</i> unduly deduced from _..._ in link targets
        def remove_markup target
          target.gsub( %r{</?i>}, '_' ).
            gsub( %r{</?b>}, '*' )
        end

        prawned = str.gsub( /
          "(?<text>[^"]+)"
          :\#
          (?<target>[\w-]+)
          /x ) do
            m = Regexp.last_match
            "<link anchor='#{ remove_markup(m[:target]) }'>#{m[:text]}</link>"
        end
        prawned.gsub( /
          "(?<text>[^"]+)"
          :
          (?<target>\S+)
          /x ) do
            m = Regexp.last_match
            "<link href='#{ remove_markup(m[:target]) }'>#{m[:text]}</link>"
        end
      end

      def ul str
        prawned = ''
        str.each_line do |line|
          prawned += line.sub(/^\*+/) do |match|
            # if one * starts the line, returns " o "
            # if two * start  the line, returns "   o "
            Prawn::Text::NBSP +
              Prawn::Text::NBSP * 2 * (match.length-1) +
              '•' +
              Prawn::Text::NBSP
          end
        end
        prawned
      end

      def ol str
        prawned = ''
        indexes = Hash.new(0)
        str.each_line do |line|
          matched = false
          prawned += line.sub(/^#+/) do |match|
            matched = true
            indent = match.length
            indexes[indent] += 1
            # Resets indexes of all lower level when we increase one level
            indexes.each_key { |k, v| indexes[k] = 0 if k > indent }
            # if one # starts the line, returns " 1. "
            # if two # start  the line, returns "    1. "
            Prawn::Text::NBSP +
              Prawn::Text::NBSP * 3 * (indent-1) +
              "#{indexes[indent]}." +
              Prawn::Text::NBSP
          end
          # Resets all indexes when we leave the list
          indexes = Hash.new(0) unless matched
        end
        prawned
      end

  end
end
