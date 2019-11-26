require_relative "result"

module GraphQLConverter
  module ConverterDsl
    class << self
      def included(base)
        base.extend DslMethods
      end
    end

    module DslMethods
      def type_class(klass)
        @_type_class = klass
      end

      def graphql_field_names
        @_type_class.fields.values.map(&:method_sym)
      end

      def generate_output(attrs)
        GraphQLConverter::Result.new(@_type_class, attrs)
      end
    end
  end
end
