require 'dry/initializer'
require 'dry/equalizer'

module Dry
  module Schema
    class Result
      include Dry::Equalizer(:output, :errors)

      extend Dry::Initializer

      param :output
      alias_method :to_h, :output
      alias_method :to_hash, :output

      param :results, default: -> { EMPTY_ARRAY.dup }

      option :message_compiler

      def self.new(*args)
        result = super
        yield(result)
        result.freeze
      end

      def set(hash)
        @output = hash
        self
      end

      def [](name)
        output[name]
      end

      def fetch(name, &block)
        output.fetch(name, &block)
      end

      def key?(name)
        output.key?(name)
      end

      def error?(name)
        errors.key?(name)
      end

      def concat(other)
        results.concat(other)
        self
      end

      def success?
        results.empty?
      end

      def failure?
        !success?
      end

      def errors(options = EMPTY_HASH)
        message_set(options.merge(hints: false)).dump
      end

      def messages(options = EMPTY_HASH)
        message_set(options.merge(hints: true)).dump
      end

      def hints(options = EMPTY_HASH)
        message_set(options.merge(failures: false)).dump
      end

      def message_set(options = EMPTY_HASH)
        message_compiler.with(options).(result_ast)
      end

      def freeze
        instance_variable_set('@__result_ast__', result_ast)
        super
      end

      private

      def result_ast
        @__result_ast__ || results.map(&:to_ast)
      end
    end
  end
end
