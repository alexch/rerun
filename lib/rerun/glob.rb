# based on http://cpan.uwinnipeg.ca/htdocs/Text-Glob/Text/Glob.pm.html#glob_to_regex_string-

# todo: release as separate gem
#
module Rerun
  class Glob
    NO_LEADING_DOT = '(?=[^\.])'   # todo

    def initialize glob_string
      @glob_string = glob_string
    end

    def to_regexp_string
      chars = @glob_string.split('')
      curlies = 0;
      escaping = false;
      chars.map do |char|
        if escaping
          escaping = false
          char
        else
          case char
            when '*'
              ".*"
            when "?"
              "."
            when "."
              "\\."

            when "{"
              curlies += 1
              "("
            when "}"
              if curlies > 0
                curlies -= 1
                ")"
              else
                char
              end
            when ","
              if curlies > 0
                "|"
              else
                char
              end
            when "\\"
              escaping = true
              "\\"

            else
              char

          end
        end
      end.join
    end

    def to_regexp
      Regexp.new(to_regexp_string)
    end
  end
end
