require "graphql_converter/base_converter"
require_relative "base_object"

RSpec.describe GraphQLConverter::BaseConverter do
  class TestType < Types::BaseObject
    field :name, String, null: false
    field :nickname, String, null: false
  end

  class TestObjectConverter < GraphQLConverter::BaseConverter
    type_class TestType

    def nickname
      "nickname from resolver"
    end
  end

  let(:test_context) { { key: "value" } }
  let(:test_object) do
    OpenStruct.new(
      name: "name from object",
      nickname: "nickname from object"
    )
  end
  let(:instance) { TestObjectConverter.new(test_object, test_context) }

  it "allows access to object and context" do
    expect(instance.object).to eq(test_object)
    expect(instance.context).to eq(test_context)
  end

  describe "#result" do
    it "generates converter result" do
      expect(instance.result).to be_a(GraphQLConverter::Result)
    end

    it "calls resolver methods if defined" do
      expect(instance.result.name).to eq("name from object")
      expect(instance.result.nickname).to eq("nickname from resolver")
    end

    context "lazy values" do
      it "doesn't call value method when not requested" do
        expect(instance).not_to receive(:nickname)
        instance.result
      end

      it "calls value method when requested" do
        expect(instance).to receive(:nickname)
        instance.result.nickname
      end
    end
  end
end
