module GraphQLConverter
  class Result
    attr_reader :type_class

    def initialize(type_class, attrs = {})
      @type_class = type_class
      initialize_lazy_attrs(attrs)
    end

    private

    def initialize_lazy_attrs(attrs)
      attrs.each do |key, block|
        define_singleton_method key do
          instance_variable_set("@_#{key}", block.call)
        end
        define_singleton_method "#{key}=" do |new_value|
          instance_variable_set("@_#{key}", new_value)
        end
      end
    end
  end
end
