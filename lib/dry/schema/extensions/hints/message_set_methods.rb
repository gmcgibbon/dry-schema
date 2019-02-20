module Dry
  module Schema
    module Extensions
      module Hints
        module MessageSetMethods
          attr_reader :hints, :failures

          # @api private
          def initialize(messages, options = EMPTY_HASH)
            @hints = messages.select(&:hint?)
            super(messages.reject(&:hint?) + @hints, options)
          end

          # @api public
          def to_h
            failures? ? messages_map : messages_map(hints)
          end
          alias_method :to_hash, :to_h
          alias_method :dump, :to_h

          # @api private
          def failures?
            options[:failures].equal?(true)
          end

          private

          # @api private
          def hint_groups
            @hint_groups ||= hints.group_by(&:path)
          end
        end
      end
    end
  end
end