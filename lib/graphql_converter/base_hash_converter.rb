require_relative "base_converter"

module GraphQLConverter
  class BaseHashConverter < GraphQLConverter::BaseConverter
    private

    def base_converter
      raise "base_converter must be provided"
    end

    def base_converter_result
      @_base_converter_result ||= base_converter.result
    end

    def lazy_field_value(key)
      if object.key?(key) && !object[key].nil?
        -> { object[key] }
      else
        -> { base_converter_result.send(key) }
      end
    end
  end
end
