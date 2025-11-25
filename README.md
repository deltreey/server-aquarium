# Server Aquarium

> Down servers are dead fish

I figure I should gamify my tooling.  UptimeKuma is sweet,
but I think I'd rather have an aquarium to display my server statuses.

-----

Host the HTML file on the web.  Dump the `server-status.json` file
where that same website can access it (preferably beside `index.html`).

Run `checker.sh` with cron, referencing `servers.yaml`.  You may want
to adjust the directories at the top of `checker.sh`.

The bash script has some prerequisites: `yq`, `ssh`, `pg_isready`, along
with some basics.

This probably could be dockerized for convenience, but I haven't done that yet.
