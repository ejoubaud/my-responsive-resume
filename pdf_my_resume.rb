# encoding: utf-8

module Middleman
  module PdfMyResume
    class << self

      def registered(app, options={})

        app.after_configuration do
          resume = data.resume

          unless resume.do_not_generate_pdf
            img_dir = File.join source_dir, images_dir
            # Default file name is the resume's title defined in Yaml file
            file_name = "#{resume.title}.pdf"

            MyResumePdfGenerator.generate(File.join source_dir, file_name) do
              header resume, img_dir

              resume.sections.each do |_, section_data|
                section section_data unless section_data.remove_from_pdf
              end
            end
          end
        end
      end

      alias :included :registered
    end


    # Helpers for PDF generation
    # This whole class is very specific to the data structure of resume.yml
    class MyResumePdfGenerator < Prawn::Document

      require 'textile_to_inline_prawn'
      require 'rqrcode_png'

      BOX_MARGIN = 36
      AVATAR_WIDTH  = 80
      SAFETY_MARGIN = 10

      RHYTHM  = 8
      LEADING = 3
      PADDING = 2

      TITLE_SIZE = 22
      SUBTITLE_SIZE = 16
      PERSONAL_SIZE = 10
      SECTIONH_SIZE = 18
      POINTH_SIZE = 12
      TEXT_SIZE = 10
      AUX_TEXT_SIZE = 10

      TEXT_COL = "515047"
      AUX_TEXT_COL = "949488"
      TITLE_COL = TEXT_COL
      SUBTITLE_COL = AUX_TEXT_COL
      SECTIONH_COL = "3A7CBF"
      AVATAR_BORDER_COL = SECTIONH_COL
      LINK_COL = SECTIONH_COL

      HEADER_BG = "DFDDB2"
      SECTION_BG = "F2F1DB"
      IMG_BG = "FFFFCC"
      
      PERSONAL_SEPARATOR = ' - '


      # Generates the header with titles and QR code
      def header resume, img_dir
        bounding_box([-bounds.absolute_left, cursor + BOX_MARGIN],
                   :width  => bounds.absolute_left + bounds.absolute_right,
                   :height => BOX_MARGIN*2 + RHYTHM*6) do

          fill_color HEADER_BG
          fill_rectangle([bounds.left, bounds.top],
                          bounds.right,
                          bounds.top - bounds.bottom)

          indent BOX_MARGIN, BOX_MARGIN do
            # QR Code and avatar
            qr resume.qr_code_url, img_dir if resume.qr_code_url
            has_avatar = image_provided? img_dir, resume.avatar
            avatar img_dir, resume.avatar if has_avatar

            # Makes room for the avatar, only if provided
            right_indent = has_avatar ? AVATAR_WIDTH + SAFETY_MARGIN : 0
            indent 0, right_indent do
              # Get personal data, preceeded by a line-break if not empty
              # (SUBTITLE_SIZE-2 whitespace is but an empirical hack to get consistent line-spacing)
              personal_data = formatted_personal_data(resume)
              personal_data.unshift({ text: "\n ", size: SUBTITLE_SIZE-2 }) unless personal_data.empty?

              formatted_text [
                  { text: "#{resume.title}\n", size: TITLE_SIZE, color: TITLE_COL, style: :bold },
                  { text: "#{resume.subtitle}", size: SUBTITLE_SIZE, color: SUBTITLE_COL }
                ].concat(personal_data),
                align: :right,
                valign: :center,
                leading: RHYTHM

            end

          end
        end
      end

      # Generates the QR code
      def qr url, output_dir
        original = cursor

        qr = RQRCode::QRCode.new( url, :size => 6, :level => :h )
        # Need creating the QR code in a file because Prawn requires a file for images
        file_name = File.join output_dir, 'qr.png'
        qr.to_img.save file_name
        image file_name,
          width: AVATAR_WIDTH,
          vposition: :center

        move_cursor_to original
      end

      # Places the avatar
      # Returns false if image file is missing
      def avatar img_dir, img_file_name
        original = cursor

        file_name = File.join img_dir, img_file_name
        cell = { image: file_name, width: AVATAR_WIDTH, image_width: AVATAR_WIDTH - PADDING*2 }
        t = make_table [[ cell ]],
          position: :right,
          cell_style: {
            background_color: IMG_BG,
            padding: PADDING
          }
        # Center the table
        move_down((bounds.height - t.height) / 2.0)
        t.draw

        move_cursor_to original
      end

      # true only if file name provided and matches an actual file
      def image_provided? dir, file_name
        file_name && File.exists?(File.join(dir, file_name))
      end

      # Extraxts a resume's personal data in an array to be past as formatted_text argument
      # Returns empty array if no personal data
      def formatted_personal_data resume
        options = { color: AUX_TEXT_COL, size: PERSONAL_SIZE }

        # Prepars data (obfuscation, enhancement)
        loc = resume.location
        age = resume.birth && "#{ age resume.birth } years"
        mail = resume.email && obfuscate_for_formatted(resume.email, HEADER_BG, size: PERSONAL_SIZE, color: LINK_COL)
        phone = resume.phone && obfuscate_for_formatted(resume.phone, HEADER_BG, options)

        # Prepares formatted table
        formatted = [ 
          loc && { text: loc }.merge(options),
          age && { text: age }.merge(options),
          mail,
          phone
        ]

        # Adds the separator if not empty
        formatted.compact!
        return [] if formatted.empty?
        sep = { text: PERSONAL_SEPARATOR }.merge(options)
        formatted.inject([]) { |mem, e| mem << e << sep }[0...-1].flatten
      end

      # Obfuscate sensible data (email) to avoid spam
      # Inserts one small character, same color as the background, between each character
      # Uses Prawn's inline markup to render
      def obfuscate_inline str, background_color = "FFFFFF"
        str.split('').
          product(["<font size='1'><color rgb='#{background_color}'>l</color></font>"]).
          flatten.
          join
      end

      # cf. #obfuscate_inline
      # Result is an array ready to use as an argument for the formatted_text method
      def obfuscate_for_formatted str, background_color = "FFFFFF", options = {}
        str.
          split('').
          map do |l|
            [ { text: l }.merge(options), 
              { text: "l", size: 1, color: background_color } ]
          end.
          flatten
      end

      # Gets an integer age (in years) from a birth date
      def age birth_date
        now = Date.today
        now.year - birth_date.year - ((birth_date >> 12 * now.year) > now ? 1 : 0)
      end

      # Displays a section in the PDF from its Yaml data
      def section section
        move_down(RHYTHM*3)

        group do
          fill_color SECTIONH_COL
          text section.title, size: SECTIONH_SIZE, style: :bold

          # We don't want to leave the title alone on a page bottom
          # hence the grouping with the first point
          point section.points.first
        end

        section.points.drop(1).each do |point_data|
          point point_data
        end
      end

      # Displays a section's point in the PDF from its Yaml data
      def point point
        move_down RHYTHM
        group do
          fill_color TEXT_COL

          if point.date
            text point.date,
              size: AUX_TEXT_SIZE,
              final_gap: false
            move_down LEADING
          end

          text Prawn::TextileToInlinePrawn.new(point.title).to_s,
            size: POINTH_SIZE,
            style: :bold,
            inline_format: true,
            final_gap: false

          if point.data
            move_down LEADING
            prawned = ""
            point.data.each do |label, labelled|
              # Here we need to concatenate inline markup because formatted_text does not support it
              # and several calls to text would add line breaks
              prawned << "<color rgb='#{AUX_TEXT_COL}'><i>#{label}: </i></color>"
              prawned << Prawn::TextileToInlinePrawn.new(labelled).to_s.rstrip
              prawned << " "
            end
            text prawned,
              size: AUX_TEXT_SIZE,
              inline_format: true,
              final_gap: false
          end

          move_down RHYTHM
          prawned = Prawn::TextileToInlinePrawn.new(point.text).to_s
          prawned.each_line('') do |paragraph|
            text paragraph.rstrip,
              size: TEXT_SIZE,
              inline_format: true
              move_down(RHYTHM/2)
          end
        end
      end

    end


    ::Middleman::Extensions.register(:pdf_my_resume, PdfMyResume)
  end
end
