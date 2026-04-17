# ALICE Lite Specification

## Role

ALICE Lite is the on-device assistant embedded inside the KairOS client. It uses short-term memory locally and stores long-term summaries on the node.

## Initial Delivery Path

Use a fallback lightweight Core ML-compatible instruct model until a compliant `ALICE_2.0/` distillation input package is provided.

## Locked Tool Set

- `send_message`
- `list_files`
- `read_file`
- `search_contacts`
- `start_call`
- `delete_file`

## Guardrails

- Confirmation required:
  - send message
  - start call
  - delete file
- No image or video understanding in v1
- Short-term memory capped to the last 10 exchanges

## Node Sync

- Periodic summary push/pull every 5 minutes
- Explicit manual sync from the UI
- Node remains the long-term memory source of truth
