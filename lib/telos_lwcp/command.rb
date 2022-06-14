module TelosLWCP
  class Command
    class Outgoing
      def initialize(command, object, arguments)
        @command = command
        @object = object
        @arguments = arguments
      end

      def to_s
        "#{@command} #{@object} #{arguments_str}\n"
      end

      def arguments_str
        @arguments.map do |argument, value|
          rv = case value
               when TrueClass
                 'TRUE'
               when FalseClass
                 'FALSE'
               when Integer
                 value
               when String
                 "\"#{value}\""
               end
          "#{argument}=#{rv}"
        end.join(', ')
      end
    end
    
    class Incoming
      attr_accessor :command, :object, :arguments, :system_items

      def initialize(string)
        parts = string.match(/\A(?<command>\S+) (?<object>\S+) (?<arguments>.*)\Z/)
        self.command = parts[:command]
        self.object = parts[:object]
        self.arguments = {}
        self.system_items = {}

        parse_extra_arguments parts[:arguments]
      end

      private
      def parse_extra_arguments(raw_string)
        buffer = ""
        in_string = false
        key = nil
        array = nil
        array_stack = []

        # Translate stuff like
        (raw_string + ' ').each_char do |char|
          case char
          when '='              # Assigning something, so everything before this is the key
            if in_string
              buffer << char
            else
              key = buffer
              buffer = ""
            end
          when '"'              # Toggle in-string status
            in_string = !in_string
            buffer << char
          when /\[/
            arr = []
            array_stack.any? ? array_stack.last << arr : array = arr
            array_stack << arr
          when /\]/
            if !buffer.empty?
              array_stack.last << raw_string_to_type(buffer)
              buffer = ""
            end
            array_stack.pop
            arguments[key.intern] = array if array_stack.empty?
          when /[, ]/
            if in_string
              buffer << char
            else
              if key.nil? || buffer == ""
                next
              elsif array_stack.any?
                array_stack.last << raw_string_to_type(buffer)
                buffer = ""
                next
              elsif key =~ /^\$/
                system_items[key.tr('$', '').intern] = raw_string_to_type(buffer)
              else
                arguments[key.intern] = raw_string_to_type(buffer)
              end
              buffer = ""
              key = nil
            end
          else
            buffer << char
          end
        end
      end

      def raw_string_to_type(raw)
        case raw
        when /^"(.*)"$/
          $1
        when /^\d+$/
          raw.to_i
        when /^TRUE$/
          true
        when /^FALSE$/
          false
        else
          raw.intern
        end
      end
    end

    class << self
      def outgoing(command, object, arguments)
        Outgoing.new(command, object, arguments)
      end

      def incoming(string)
        Incoming.new(string)
      end
    end
  end
end