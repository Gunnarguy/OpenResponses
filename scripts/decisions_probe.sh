#!/bin/zsh
# One live POST /v1/decisions call with the app's built-in example (three questions about one support message),
# to check the request shape the app sends against the real API.
# Usage: scripts/decisions_probe.sh [Keychain service]   (default openai-api-key, the item ~/.agents/bin/key-setup openai writes)
# The key is read from the login Keychain and passed to curl on stdin, so it never appears in argv, a log or this output.
# Cost: about 120 input tokens at $0.10 per million (well under $0.0001); Decisions does not charge for output.
set -euo pipefail
service=${1:-openai-api-key}
key=$(security find-generic-password -s "$service" -w)
body='{"model":"gpt-6-luna","input":"I was charged twice for my order and I need the second charge refunded before rent is due on Friday.","questions":[{"type":"choice","name":"department","instructions":"Which department should handle this message?","choices":[{"value":"billing","description":"Payments, invoices, and refunds."},{"value":"technical","description":"Problems using the product."},{"value":"shipping","description":"Delivery and tracking."},{"value":"other","description":"Requests outside these categories."}]},{"type":"predicate","name":"asks_for_refund","instructions":"Does the customer ask for a refund?"},{"type":"score","name":"urgency","instructions":"How urgent is this message?","levels":[{"label":"Low","description":"No deadline or harm mentioned."},{"label":"Medium","description":"A deadline or inconvenience is mentioned."},{"label":"High","description":"Money, safety, or access is at risk soon."}]}]}'
printf 'header = "Authorization: Bearer %s"\n' "$key" | curl -sS -K - https://api.openai.com/v1/decisions \
  -H 'Content-Type: application/json' -d "$body" -w '\nHTTP %{http_code}\n'
unset key
