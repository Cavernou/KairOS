# Protocol Specification

## Primary Transport

- Protocol: gRPC over Tailnet
- Shared definition: `proto/kairos_node.proto`

## Packet Envelope

Used for messages, file chunks, and call setup.

- `id`
- `type`
- `sender_kair`
- `receiver_kair`
- `timestamp`
- `encrypted_payload`
- `node_route`

File chunk payloads also include chunk metadata and checksum.

## Required RPCs

- `ActivateDevice`
- `SendMessage`
- `SendFileChunk`
- `FetchQueue`
- `GetContacts`
- `UpdateTrustScore`
- `StoreAIMemory`
- `RetrieveAIMemory`

## Error Handling

Client-visible failures should be typed and stable:

- `INVALID_ARGUMENT`
- `NOT_FOUND`
- `FAILED_PRECONDITION`
- `PERMISSION_DENIED`
- `UNAVAILABLE`
- `INTERNAL`

## Generation Note

`protoc` generation is not checked into the workspace yet because the current machine does not have `protoc` installed. Generated Swift and Go bindings should be produced from this file as soon as the toolchain is available.
