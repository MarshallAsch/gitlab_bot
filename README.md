# gitlab_bot
This is a simple bot that will move gitlab issues when different events happen.


This requires node to be installed on the system


This was designed to work with my [Webhook server](https://github.com/MarshallAsch/CI_server) for gitlab events.

The script can move tickets for any of the following actions:
 - when there is a new branch
 - when there is a new pull request
 - when there is a closed pull request
 - when there is a merged pull request


It can add a single label and remove any number of labels from an issue. In order for the script to work the
branch names **MUST** be in the format `<issueNumber>-<some description>`.


This can support multiple different projects with different authentication tokens by adding more entries to the config.yaml file.

An example configuration for the server is the following:

```json
{
    "servers":
    [
		{
		    "repositoryID": "1234",
		    "event": "push",
		    "runScript": "issueBot.sh"
		},
		{
		    "repositoryID": "1234",
		    "event": "merge_request",
		    "runScript": "issueBot.sh"
		}
	]
}
```
