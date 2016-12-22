module TelosLWCP
  class Subscription
    attr_accessor :command, :object, :matcher, :block

    def initialize(command:, object:, matcher:, block:)
      self.command = Regexp === command ? command : /\A#{command}\Z/ if command
      self.object = Regexp === object ? object : /\A#{object}\Z/ if object
      self.matcher = matcher
      self.block = block
    end
    
    def match?(cmd)
      (command.nil? || command =~ cmd.command) &&
          (object.nil? || object =~ cmd.object) &&
          (matcher.nil? || matcher.call(cmd))
    end

    def call(cmd)
      block.call(cmd)
    end
  end
end