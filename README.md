# lita-group-mention

[![Build Status](https://travis-ci.org/bhouse/lita-group-mention.svg?branch=master)](https://travis-ci.org/bhouse/lita-group-mention)
[![Coverage Status](https://coveralls.io/repos/bhouse/lita-group-mention/badge.svg?branch=master)](https://coveralls.io/r/bhouse/lita-group-mention?branch=master)

## Installation

Add lita-group-mention to your Lita instance's Gemfile:

``` ruby
gem "lita-group-mention"
```

## Configuration (optional)

Preload mention groups and members using configuration:

```ruby
config.handlers.group_mention.groups =
  {
    'ops' => ['ops1','ops2']
    'devs' => ['dev1','dev2']
  }
```

## Usage

This plugin will monitor messages for mentions of groups, and expand the group
to mention a list of each user in that group. Groups are stored in redis, and
configured with commands.

```shell
Larry: Lita group mention add moe to ops
Lita: Added @moe to ops
Larry: Lita group mention add curly to dev
Lita: Added @curly to dev
Larry: Good morning @ops and @dev
Lita: cc @moe, @curly
```

```shell
Larry: Lita group mention show groups
Lita: ops: moe
      dev: curly
Larry: Lita group mention remove group ops
Lita: Removed the ops group
Larry: group mention show user curly
Lita: curly: dev
Larry: group mention show user moe
Lita: moe:
```


## License

[MIT](http://opensource.org/licenses/MIT)
