require_relative "converter_dsl"

module GraphQLConverter
  class BaseConverter
    include GraphQLConverter::ConverterDsl

    attr_reader :object, :context

    def initialize(object, context = {})
      @object = object
      @context = context
    end

    def result
      attrs = self.class.graphql_field_names.each_with_object({}) do |key, hash|
        hash[key] = lazy_field_value(key)
      end
      self.class.generate_output(attrs)
    end

    private

    def lazy_field_value(key)
      if respond_to?(key)
        -> { send(key) }
      else
        -> { object.send(key) }
      end
    end
  end
end
