require 'socket'
require 'timeout'

module TelosLWCP
  class Error < StandardError; end

  class Engine
    attr_accessor :host, :port

    def initialize host:, port: 20518
      self.host = host
      self.port = port

      @listeners = Hash.new {|h, k| h[k] = {}}
      @subscriptions = []
    end

    def connect
      @server = TCPSocket.new host, port
      start_reader_thread
      if block_given?
        yield self
        disconnect
      end
    end

    def disconnect
      @reader_thread.terminate if @reader_thread
      @server.close
    end

    def login(user, password)
      wait(
        [:ack, :cc] => proc {|r| r.arguments[:logged] }
      ) do
        write :login, :cc, user: user, password: password
      end
    end

    def list_studios
      wait(
        [:indi, :cc] => proc {|r| r.arguments[:studio_list] }
      ) do
        write :get, "cc studio_list"
      end
    end
    

    def select_studio(id)
      wait(
          [:event, :studio] => proc {|r| r },
          [:ack, :studio] => proc {|r| Error.new(r.system_items[:msg]) }
      ) do
        write :select, :studio, id: id
      end
    end

    def seize(line_nr)
      wait(
          [:event, "studio.line##{line_nr}"] => proc { true },
          [:ack, "studio.line##{line_nr}"] => proc {|r| Error.new(r.system_items[:msg]) }
      ) do
        write :seize, "studio.line##{line_nr}"
      end
    end

    def call_number(line_nr, number)
      wait(
          [:event, "studio.line##{line_nr}"] => proc { true }
      ) do
        write :call, "studio.line##{line_nr}", number: number
      end
    end

    def subscribe(command: nil, object: nil, matcher: nil, &block)
      @subscriptions << Subscription.new(command: command, object: object, matcher: matcher, block: block)
    end
    
    # Low level
    def write(command, object, arguments = {})
      cmd = Command.outgoing(command, object, arguments)
      @server.write(cmd.to_s)
    end

    def wait(expectations, read_timeout: 5, &block)
      data = nil
      thread = Thread.current
      expectations.each do |(cmd, object), proc|
        @listeners[cmd.to_s][object.to_s] = proc {|d|
          data = proc.call(d);
          expectations.each {|(cmd, object), _| @listeners[cmd.to_s][object.to_s] = nil }
          thread.run
        }
      end
      block.call
      Timeout.timeout(read_timeout) do
        Thread.stop
      end
      Error === data ? raise(data) : data
    end

    private
    def start_reader_thread
      Thread.abort_on_exception = true
      @reader_thread = Thread.start do
        loop do
          raw = @server.gets.chomp
          value = Command.incoming(raw)
          if listener = @listeners[value.command][value.object]
            listener.call(value)
          end

          @subscriptions.select {|sub| sub.match?(value) }.each {|sub| sub.call(value) }
        end
      end
    end
  end
end