# The hit CLI 👊

`hit` is a productivity-focussed command-line API client that converts individual API endpoints into command-line commands.

## Installation

### macOS

`hit` can be installed using Homebrew:

```bash
brew tap meshde/hit
brew install hit
```

### Linux

Support coming soon!

### Windows

Support coming soon!

## Usage

`hit` works based on the config present in the current working directory. Specifically, the `.hit/config.json` file present in the current working directory. The contents of the config define what commands are available to run.

For example, if the config looks something like:

```json
{
  "commands": {
    "list-users": {
        "url": "https://your.api.com/users",
        "method": "GET",
    }
  }
}
```

then this API call can be made like so:

```bash
hit run list-users
```

**The `.hit/` directory is meant to be added to git and hence can be shared by developers in a team.**

### Route Params

But API endpoint routes are never as simple as the example above. There can be any number of variables in the route. For example, an endpoint to retrieve a single user would include the id of the user to be retrieved in the route. `hit` would not be considered productivity-focussed if we had to go in and update the route in the config file every time we wanted to retrieve a different user.

To handle such cases, the `hit` config has the ability to specify which parts of the route represent variables and the values for such variables can then passed as command-line options. Variables can be denoted by prefixing them with colon `:`. So if the url in the config has `:userId`, then `userId` would be a variable.

For example, the route to retrieve a user can be added to our previous config like so:

```json
{
  "commands": {
    "list-users": {
        "url": "https://your.api.com/users",
        "method": "GET",
    },
    "get-user": {
        "url": "https://your.api.com/users/:userId",
        "method": "GET",
    }
  }
}
```

and this can be invoked as follows to retrieve user with id `47`:

```bash
hit run get-user --user-id 47
```

Something similar can be done if the user id were to be passed in the query params instead of route params:

```json
    "get-user": {
        "url": "https://your.api.com/users?id=:userId",
        "method": "GET",
    }
```

```bash
hit run get-user --user-id 47
```

### Environment Variables

Most software development set ups have multiple environments where their APIs are deployed such as a production/prod environment, a staging or dev or sandbox env or even separate environments for different features being developed. `hit` has the ability to define and use a set of variables that can have different values based on the currently active environment.

Environment variables can be used in the config by enclosing them in double curly braces (`{{` `}}`) and can be defined in the config under the top level field `envs`.


```json
{
  "envs": {
    "prod": {
      "API_URL": "https://prod.api.com"
    },
    "dev": {
      "API_URL": "https://dev.api.com"
    }
  },
  "commands": {
    "list-users": {
        "url": "{{API_URL}}/users",
        "method": "GET",
    },
    "get-user": {
        "url": "{{API_URL}}/users/:userId",
        "method": "GET",
    }
  }
}
```

An environment can be activated by running the command:

```bash
hit env use <env_name>
```

In the above example config, if the `prod` env is activated then all `run` commands using `{{API_URL}}` would use `https://prod.api.com` as the value for the variable.

As mentioned previously, the config file is meant to be committed to git and shared in a development team. The values for the environment variables would then also be automatically shared.


### Ephemeral Environment Variables

Environment variables discussed above are good for nearly-static variables that don't change often and would be good to share in the team but there might be variables in a workflow that are meant to be kept secret. Good examples of such variables are access tokens and api keys. For such variables, `hit` has support for "Ephemeral Environment Variables" or `ephenv`s

`ephenv`s can be set from the `hit` cli directly as opposed to in the config. `hit` stores these values in app settings on the local machine and hence these values don't show up in the config and are not shareable.

Here's an example of setting an API key:

```bash
hit ephenv set API_KEY secret_value_abcd_123
```

Such variables can then be used in the config similar to how environment variables are used by enclosing in double curly braces. For example:

```json
{
  ...
  ...
  "commands": {
    "list-users": {
        "url": "{{API_URL}}/users?api_key={{API_KEY}}",
        "method": "GET",
    },
    ...
    ...
  }
}
```

### Request Headers

`hit` config allows you to provide the request headers that would need to be sent with each API call. The value of each header supports all kinds of variables:
1. variables representing command-line options that start with `:` (see section on Routing Params).
2. Environment variables enclosed in double curly braces.
3. Ephemeral environment variables enclosed in double curly braces.

For example, with the config

```json
{
  ...
  ...
  "commands": {
    "list-users": {
        "url": "{{API_URL}}/users",
        "method": "GET",
        "headers": {
          "X-Authorization-Key": "{{API_KEY}}",
          "Origin": "{{API_URL}}",
          "X-Request-Id": ":customRequestId"
        }
    },
    ...
    ...
  }
}
```

the headers used when invoking command `list-users` would:
1. expect a command-line option `--custom-request-id` for the value of the header `X-Request-Id`.
2. use the value of `{{API_URL}}` from the active environment.
3. use the value of `{{API_KEY}}` from what was set in the app settings using the `hit ephenv set` command.

### Nested Sub-Commands

So far we've covered being able to add commands directly as key-value pairs in the top level `commands` field of the config file. This works great in the beginning when we have just a few commands but as the number of api endpoints increase, our list of commands would also increase and it might get cluttered to maintain the commands. To add some sort of structure to the config file, the `hit` config supports organizing commands into nested sub-commands.

What this means is that instead of having to maintain commands like `get-user`, `list-users`, `delete-user`, `create-user`, we can organize the config to have a high level `users` command with the corresponding sub-commands as `get`, `list`, `delete`, `create`.

The config supports arbitrary level of nesting.

For example, with a config like so:

```json
{
  "envs": {
    "prod": {
      "API_URL": "https://prod.api.com"
    },
    "dev": {
      "API_URL": "https://dev.api.com"
    }
  },
  "commands": {
    "users": {
      "list": {
          "url": "{{API_URL}}/users",
          "method": "GET",
      },
      "get": {
          "url": "{{API_URL}}/users/:userId",
          "method": "GET",
      }
    }
  }
}
```

the available commands would be:

```
hit run users list
hit run users get --user-id 47
```


### Inspecting the response of an API call

Normally, running a command would simply output the body of the response of the API call being made. If you would like to inspect the entire response including the status code and response headers, this can be done by running the command:

```bash
hit last view
```
