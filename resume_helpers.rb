# Common helpers between PDF generation and
# the Web version of the resume are defined here.
module ResumeHelpers

  # Gets an integer age (in years) from a birth date
  def age birth_date
    now = Date.today
    now.year - birth_date.year - ((birth_date >> 12 * now.year) > now ? 1 : 0)
  end

end
