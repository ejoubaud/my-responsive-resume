# encoding: utf-8

module Middleman
  module PdfMyResume
    class << self

      def registered(app, options={})
        if data = options[:data]
          resume = data.resume

          # Default file name is the resume's title defined in Yaml file
          options[:file_name] ||= "#{resume.title}.pdf"
          app.after_configuration do
            options[:output_dir] ||= source_dir

            MyResumePdfGenerator.generate(File.join options[:output_dir], options[:file_name]) do
              header resume.title, resume.subtitle, resume.qr_code_url

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
      INNER_MARGIN = 30
      RHYTHM  = 8
      LEADING = 2

      TEXT_COL = "515047"
      AUX_TEXT_COL = "949488"
      TITLE_COL = TEXT_COL
      SUBTITLE_COL = AUX_TEXT_COL
      SECTION_HCOL = "3A7CBF"

      HEADER_BG = "DFDDB2"
      SECTION_BG = "F2F1DB"

      def header title, subtitle, url
        bounding_box([-bounds.absolute_left, cursor + BOX_MARGIN],
                   :width  => bounds.absolute_left + bounds.absolute_right,
                   :height => BOX_MARGIN*2 + RHYTHM*4) do

          fill_color HEADER_BG
          fill_rectangle([bounds.left, bounds.top],
                          bounds.right,
                          bounds.top - bounds.bottom)

          indent BOX_MARGIN, BOX_MARGIN + INNER_MARGIN do
            qr url if url

            formatted_text [
              { text: "#{title}\n", size: 22, color: TITLE_COL, style: :bold },
              { text: subtitle, size: 16, color: SUBTITLE_COL } ],
              align: :right,
              valign: :center,
              leading: RHYTHM
          end
        end
      end

      def qr url
        original = cursor

        qr = RQRCode::QRCode.new( url, :size => 12, :level => :h )
        qr.to_img.save('qr.png')
        image 'qr.png', vposition: :center

        move_cursor_to original
      end

      def section section
        move_down(RHYTHM*3)

        group do
          fill_color SECTION_HCOL
          text section.title, size: 18, style: :bold

          # We don't want to leave the title alone on a page bottom
          # hence the grouping with the first point
          point section.points.first
        end

        section.points.drop(1).each do |point_data|
          point point_data
        end
      end

      def point point
        move_down RHYTHM
        group do
          fill_color TEXT_COL

          if point.date
            text point.date,
              size: 10,
              final_gap: false
            move_down LEADING
          end

          text Prawn::TextileToInlinePrawn.new(point.title).to_s,
            size: 12,
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
              size: 10,
              inline_format: true,
              final_gap: false
          end

          move_down RHYTHM
          prawned = Prawn::TextileToInlinePrawn.new(point.text).to_s
          prawned.each_line('') do |paragraph|
            text paragraph.rstrip,
              size: 10,
              inline_format: true
              move_down(RHYTHM/2)
          end
        end
      end

    end


    ::Middleman::Extensions.register(:pdf_my_resume, PdfMyResume)
  end
end
