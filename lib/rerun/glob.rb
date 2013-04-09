# based on http://cpan.uwinnipeg.ca/htdocs/Text-Glob/Text/Glob.pm.html#glob_to_regex_string-

# todo: release as separate gem
#
module Rerun
  class Glob
    NO_LEADING_DOT = '(?=[^\.])'   # todo
    START_OF_FILENAME = '(\A|\/)'  # beginning of string or a slash
    END_OF_STRING = '\z'

    def initialize glob_string
      @glob_string = glob_string
    end

    def to_regexp_string
      chars = @glob_string.split('')

      chars = smoosh(chars)

      curlies = 0
      escaping = false
      string = chars.map do |char|
        if escaping
          escaping = false
          char
        else
          case char
            when '**'
              "([^/]+/)*"
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
      START_OF_FILENAME + string + END_OF_STRING
    end

    def to_regexp
      Regexp.new(to_regexp_string)
    end

    def smoosh chars
      out = []
      until chars.empty?
        char = chars.shift
        if char == "*" and chars.first == "*"
          chars.shift
          chars.shift if chars.first == "/"
          out.push("**")
        else
          out.push(char)
        end
      end
      out
    end
  end
end
