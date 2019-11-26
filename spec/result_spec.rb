require "graphql_converter/result"
require_relative "base_object"

RSpec.describe GraphQLConverter::Result do
  class TestType < Types::BaseObject
  end

  let(:stub_object) do
    obj = double
    allow(obj).to receive(:lazy_value).and_return("return value")
    obj
  end
  let(:attrs) do
    {
      key1: -> { stub_object.lazy_value },
      key2: -> { stub_object.lazy_value },
      key3: -> { stub_object.lazy_value },
    }
  end
  let(:result) do
    GraphQLConverter::Result.new(TestType, attrs)
  end

  it "allows access to type_class" do
    expect(result.type_class).to eq(TestType)
  end

  it "defines methods for all given keys" do
    expect(result).to respond_to(:key1)
    expect(result).to respond_to(:key2)
    expect(result).to respond_to(:key3)
  end

  it "doesn't call lazy values when not requested" do
    expect(stub_object).not_to receive(:lazy_value)
  end

  it "calls lazy values when requested" do
    expect(stub_object).to receive(:lazy_value)
    result.key1
  end

  it "returns expected values from attr methods" do
    expect(result.key1).to eq("return value")
  end
end
