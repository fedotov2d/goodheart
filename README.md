# Good Heart

Clojure interpreter on pure Ruby. Now supports only a small subset.

_**The Wizard of Oz:** As for you, my galvanized friend, you want a heart. You don't know how lucky you are not to have one. Hearts will never be practical until they can be made unbreakable._

_**The Tin Man:** But, I... I still want one._

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'goodheart'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install goodheart

## Usage

```ruby
require "goodheart"

runtime = Clojure::Runtime.new
runtime.load("shared_validation.clj")
runtime.namespace("validation").evaluate(["validate", data])
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/goodheart. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Goodheart project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/goodheart/blob/master/CODE_OF_CONDUCT.md).
