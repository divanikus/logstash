require "test_utils"

describe "conditionals" do
  extend LogStash::RSpec

  describe "simple" do
    config <<-CONFIG
      filter {
        mutate { add_field => { "always" => "awesome" } }
        if [foo] == "bar" {
          mutate { add_field => { "hello" => "world" } }
        } else if [bar] == "baz" {
          mutate { add_field => { "fancy" => "pants" } }
        } else {
          mutate { add_field => { "free" => "hugs" } }
        }
      }
    CONFIG

    sample({"foo" => "bar"}) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] } == "world"
      insist { subject["fancy"] }.nil?
      insist { subject["free"] }.nil?
    end

    sample({"notfoo" => "bar"}) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] }.nil?
      insist { subject["free"] } == "hugs"
    end

    sample({"bar" => "baz"}) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] } == "pants"
      insist { subject["free"] }.nil?
    end
  end

  describe "nested" do
    config <<-CONFIG
      filter {
        if [nest] == 123 {
          mutate { add_field => { "always" => "awesome" } }
          if [foo] == "bar" {
            mutate { add_field => { "hello" => "world" } }
          } else if [bar] == "baz" {
            mutate { add_field => { "fancy" => "pants" } }
          } else {
            mutate { add_field => { "free" => "hugs" } }
          }
        }
      }
    CONFIG

    sample("foo" => "bar", "nest" => 124) do
      insist { subject["always"] }.nil?
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] }.nil?
      insist { subject["free"] }.nil?
    end

    sample("foo" => "bar", "nest" => 123) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] } == "world"
      insist { subject["fancy"] }.nil?
      insist { subject["free"] }.nil?
    end

    sample("notfoo" => "bar", "nest" => 123) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] }.nil?
      insist { subject["free"] } == "hugs"
    end

    sample("bar" => "baz", "nest" => 123) do
      insist { subject["always"] } == "awesome"
      insist { subject["hello"] }.nil?
      insist { subject["fancy"] } == "pants"
      insist { subject["free"] }.nil?
    end
  end

  describe "comparing two fields" do
    config <<-CONFIG
      filter {
        if [foo] == [bar] {
          mutate { add_tag => woot }
        }
      }
    CONFIG

    sample("foo" => 123, "bar" => 123) do
      insist { subject["tags"] }.include?("woot")
    end
  end

  describe "the 'in' operator" do
    config <<-CONFIG
      filter {
        if [foo] in [foobar] {
          mutate { add_tag => "field in field" }
        }
        if [foo] in "foo" {
          mutate { add_tag => "field in string" }
        }
        if "hello" in [greeting] {
          mutate { add_tag => "string in field" }
        }
        if [foo] in ["hello", "world", "foo"] {
          mutate { add_tag => "field in list" }
        }
        if [missing] in [alsomissing] {
          mutate { add_tag => "shouldnotexist" }
        }
      }
    CONFIG

    sample("foo" => "foo", "foobar" => "foobar", "greeting" => "hello world") do
      insist { subject["tags"] }.include?("field in field")
      insist { subject["tags"] }.include?("field in string")
      insist { subject["tags"] }.include?("string in field")
      insist { subject["tags"] }.include?("field in list")
      reject { subject["tags"] }.include?("shouldnotexist")
    end
  end
end
