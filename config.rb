###
# Compass
###

# Susy grids in Compass
# First: gem install susy --pre
# require 'susy'

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy (fake) files
# page "/this-page-has-no-template.html", :proxy => "/template-file.html" do
#   @which_fake_page = "Rendering a fake page with a variable"
# end

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Methods defined in the helpers block are available in templates
helpers do
  # Gets an integer age (in years) from a birth date
  def age birth_date
    now = Date.today
    now.year - birth_date.year - ((birth_date >> 12 * now.year) > now ? 1 : 0)
  end

  # Displays a string with javascript, so it can't be parsed by spam crawlers
  def obfuscate str
    obfed = str.split('').map{|l| "'#{l}' +/* +'trap'+ */ ''" }.join('+')
    %Q{<script type="text/javascript">document.write(#{obfed})</script>}
  end

  # Same as #obfuscate, generating a mailto link instead of just a text
  def obfuscated_mail_to email, title = nil
    obfed_email = email.split('').map{|l| "'#{l}' +/* +'trap'+ */ ''" }.join('+')
    obfed_title = title.nil? ? obfed_email : title.split('').map{|l| "'#{l}' + ''" }.join('+')
    %Q{<script type="text/javascript">document.write('<a href="mailto:' + #{obfed_email} + '">' + #{obfed_title} + '</a>')</script>}
  end

  # Makes a string's whitespaces unbreakable
  def to_nbsp str
    str.gsub(/\s/, '&nbsp;')
  end

  # Generates the personal_data line
  # joining location, age, mail (obfuscated) and phone number, if provided
  def personal_data resume
    [ resume.location,
      resume.birth && "#{ age resume.birth } years",
      resume.email && obfuscated_mail_to(resume.email),
      resume.phone && obfuscate(to_nbsp(resume.phone)),
    ].reject{ |e| e.nil? }.join ' - '
  end

  # true only if file name provided and matches an actual file
  def avatar? file_name
    file_name && File.exists?(File.join(source_dir, images_dir, file_name))
  end
end

set :css_dir, 'css'

set :js_dir, 'js'

set :images_dir, 'img'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript

  # Enable cache buster
  # activate :cache_buster

  # Use relative URLs
  # activate :relative_assets

  # Compress PNGs after build
  # First: gem install middleman-smusher
  # require "middleman-smusher"
  # activate :smusher

  # Or use a different image path
  # set :http_path, "/Content/images/"
end

# Textile parsing
require 'redcloth'

# PDF generation extension
require 'pdf_my_resume'
activate :pdf_my_resume


