Feature: `--pattern` option

  By default, RSpec loads files matching the pattern:

      "spec/**/*_spec.rb"

  Use the `--pattern` option to declare a different pattern.

  Scenario: Default pattern
    Given a file named "spec/example_spec.rb" with:
      """ruby
      RSpec.describe "addition" do
        it "adds things" do
          expect(1 + 2).to eq(3)
        end
      end
      """
    When I run `rspec`
    Then the output should contain "1 example, 0 failures"

  Scenario: Override the default pattern on the command line
    Given a file named "spec/example.spec" with:
      """ruby
      RSpec.describe "addition" do
        it "adds things" do
          expect(1 + 2).to eq(3)
        end
      end
      """
    When I run `rspec --pattern "spec/**/*.spec"`
    Then the output should contain "1 example, 0 failures"

  Scenario: Override the default pattern in configuration
    Given a file named "spec/spec_helper.rb" with:
      """ruby
        RSpec.configure do |config|
          config.pattern << ',**/*.spec'
        end
      """
    And a file named "spec/example.spec" with:
      """ruby
      RSpec.describe "addition" do
        it "adds things" do
          expect(1 + 2).to eq(3)
        end
      end
      """
    When I run `rspec -rspec_helper`
    Then the output should contain "1 example, 0 failures"
