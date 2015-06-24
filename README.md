# Logging

Logging is a re-usable component with a globally accessible Logger, e.g.

```
include Logging::Logger
logger.warn "blah"
```

Also included is a Railtie that overrides the default rails logger to always
print to STDOUT as well as format the messages to JSON for machine readable
goodness. This has been tested with Rails 4.2 but should compatible with
Rails 3 or newer since that's when Railties were introduced.

## Installation

Add this line to your application's Gemfile:

    gem 'logging'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install logging

## Usage

### Non-Rails projects:

```
require 'logging'

include Logging::Logger

Logging.set_logger(STDOUT)

logger.warn "blah"
```

### Rails projects:

Nothing after it's added to your Gemfile, the Railtie takes care of the rest.
