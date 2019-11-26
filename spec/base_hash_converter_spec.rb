require "graphql_converter/base_hash_converter"
require_relative "base_object"

RSpec.describe GraphQLConverter::BaseHashConverter do
  class TestType < Types::BaseObject
    field :name, String, null: false
    field :nickname, String, null: false
    field :special_field, String, null: false
  end

  class TestObjectConverter < GraphQLConverter::BaseConverter
    type_class TestType

    def nickname
      "nickname from resolver"
    end
  end

  class TestHashConverter < GraphQLConverter::BaseHashConverter
    type_class TestType

    def base_converter
      test_object = OpenStruct.new(
        name: "name from object",
        nickname: "nickname from object",
        special_field: "special_field from object"
      )
      TestObjectConverter.new(test_object)
    end
  end

  let(:test_hash) { { name: "name from hash" } }
  let(:instance) { TestHashConverter.new(test_hash) }

  describe "#result" do
    it "generates converter result" do
      expect(instance.result).to be_a(GraphQLConverter::Result)
    end

    it "returns hash values if defined" do
      expect(instance.result.name).to eq("name from hash")
      expect(instance.result.nickname).to eq("nickname from resolver")
      expect(instance.result.special_field).to eq("special_field from object")
    end
  end
end
